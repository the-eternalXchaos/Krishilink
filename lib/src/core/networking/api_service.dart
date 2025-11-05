import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/features/admin/models/user_model.dart';
// Package-level imports within this app
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/src/core/components/material_ui/pop_up.dart';
import 'package:krishi_link/src/core/constants/api_constants.dart';
import 'package:krishi_link/src/core/constants/constants.dart';
import 'package:krishi_link/src/core/errors/app_exception.dart';
import 'package:krishi_link/src/features/auth/data/token_service.dart';
import 'package:krishi_link/src/features/product/data/models/review_model.dart';

class ApiService {
  final Dio _dio;

  Future<Options> getJsonOptions() => _jsonOptions();

  // getter for the dio
  Dio get dio => _dio;

  bool _isRefreshing = false;
  static const _maxRetries = 3;

  ApiService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
          headers: {'Content-Type': 'application/json'},
        ),
      ) {
    _configureInterceptors();
  }
  //            token
  Future<String?> _token() async {
    final authController = Get.find<AuthController>();
    return authController.currentUser.value?.token;
  }

  void _configureInterceptors() {
    _dio.interceptors.clear();
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final path = options.uri.path;
          final isGuestAccess = options.extra['guestAccess'] == true;

          try {
            if (isGuestAccess ||
                guestAllowedEndpoints.any(
                  (endpoint) => path.contains(endpoint),
                )) {
              debugPrint('[Interceptor] Guest access allowed for: $path');
              return handler.next(options);
            }

            final headers = await TokenService.getAuthHeaders();
            options.headers.addAll(headers);
            // Ensure multipart requests are not forced to JSON content type
            if (options.data is FormData) {
              options.headers.remove('Content-Type');
              options.contentType = 'multipart/form-data';
              debugPrint('[Interceptor] Adjusted Content-Type for multipart');
            }
            debugPrint('[Interceptor] Request Headers: ${options.headers}');
            return handler.next(options);
          } catch (e) {
            debugPrint('[Interceptor] Error building auth headers: $e');
            // Do NOT proceed without Authorization; reject to let caller handle
            if (e is AppException && e.message == 'OFFLINE') {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.connectionError,
                  error: e,
                ),
              );
            }
            // If token cannot be built, force login flow
            if (Get.currentRoute != '/login') {
              PopupService.error(
                'Please login to continue',
                title: 'Session Required',
              );
              Get.offAllNamed('/login');
            }
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                error: e,
              ),
            );
          }
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            if (guestAllowedEndpoints.any(
              (endpoint) => error.requestOptions.path.contains(endpoint),
            )) {
              debugPrint(
                '[Interceptor] 401 on guest endpoint, proceeding: ${error.requestOptions.path}',
              );
              return handler.next(error);
            }

            final retryResponse = await _handleTokenRefresh(error);
            if (retryResponse != null) {
              return handler.resolve(retryResponse);
            }

            debugPrint('[Interceptor] Unauthorized: showing login prompt');
            if (Get.currentRoute != '/login') {
              // Parse server-provided title/message if available
              final ex = _parseDioError(error);
              final popupTitle = ex.title ?? 'Authentication Failed';
              final popupMessage =
                  ex.message.isNotEmpty
                      ? ex.message
                      : 'Please login to continue';
              PopupService.error(popupMessage, title: popupTitle);
              Get.offAllNamed('/login');
            }
            return handler.next(error);
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<Response<dynamic>?> _handleTokenRefresh(DioException error) async {
    if (_isRefreshing) {
      await Future.delayed(const Duration(milliseconds: 500));
      return _retryRequest(error.requestOptions);
    }

    try {
      _isRefreshing = true;
      final refreshToken = await TokenService.getRefreshToken();
      if (refreshToken == null) {
        debugPrint('[Interceptor] No refresh token available');
        return null;
      }

      final formData = FormData.fromMap({
        'refreshToken': refreshToken, // must match backend field name
      });
      final response = await _dio.post(
        ApiConstants.refreshTokenEndpoint,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200) {
        final data = response.data is Map<String, dynamic> ? response.data : {};
        final apiData = data['data'] ?? {};
        await TokenService.saveTokens(
          accessToken: apiData['token'] ?? '',
          refreshToken: apiData['refreshToken'] ?? '',
          expiration: apiData['expiration'] ?? DateTime.now().toIso8601String(),
        );
        return _retryRequest(error.requestOptions);
      }
    } catch (e) {
      await TokenService.clearTokens();
    } finally {
      _isRefreshing = false;
    }
    return null;
  }

  Future<Response<dynamic>> _retryRequest(
    RequestOptions requestOptions, [
    int retryCount = 0,
  ]) async {
    try {
      final headers = await TokenService.getAuthHeaders();
      requestOptions.headers.addAll(headers);
      return await _dio.fetch(requestOptions);
    } catch (e) {
      if (retryCount < _maxRetries - 1 && e is DioException) {
        await Future.delayed(Duration(milliseconds: 500 * (retryCount + 1)));
        return _retryRequest(requestOptions, retryCount + 1);
      }
      rethrow;
    }
  }

  // --- OTP LOGIC ---
  Future<Map<String, dynamic>> sendOtp(
    String identifier,
    String deviceId,
  ) async {
    try {
      final data = FormData.fromMap({
        'EmailorPhone': identifier,
        'DeviceId': deviceId,
      });
      final response = await _dio.post(
        ApiConstants.sendOtpEndpoint,
        data: data,
        options: Options(
          headers: {'accept': '*/*'},
          extra: {'guestAccess': true},
        ),
      );
      return {'message': response.data, 'statusCode': response.statusCode};
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  // --- SOCIAL LOGIN LOGIC ---
  Future<UserModel> loginWithGoogle(String accessToken) async {
    throw UnimplementedError('Google login is not implemented on backend');
  }

  Future<UserModel> loginWithFacebook(String accessToken) async {
    throw UnimplementedError('Facebook login is not implemented on backend');
  }

  Future<UserModel> loginWithApple({
    required String identityToken,
    required String authorizationCode,
  }) async {
    throw UnimplementedError('Apple login is not implemented on backend');
  }

  // --- REVIEW LOGIC ---

  //   // --- REVIEW LOGIC ---
  //   Future<List<ReviewModel>> getReviews(String productId) async {
  //     try {
  //       final response = await _dio.get(
  //         '${ApiConstants.getProductReviewsEndpoint}/$productId',
  //         options: Options(headers: {'accept': '*/*'}),
  //       );
  //       if (response.statusCode == 200 && response.data is List) {
  //         return (response.data as List)
  //             .map((e) => ReviewModel.fromJson(e))
  //             .toList();
  //       } else if (response.data is Map && response.data['data'] is List) {
  //         return (response.data['data'] as List)
  //             .map((e) => ReviewModel.fromJson(e))
  //             .toList();
  //       }
  //       return [];
  //     } on DioException catch (e) {
  //       throw _parseDioError(e);
  //     }
  //   }

  //   Future<void> submitReview(ReviewModel review) async {
  //     try {
  //       final formData = FormData.fromMap({
  //         'productId': review.productId,
  //         'review': review.review,
  //       });
  //       final response = await _dio.post(
  //         ApiConstants.addReviewEndpoint,
  //         data: formData,
  //         options: Options(headers: {'accept': '*/*'}),
  //       );
  //       if (response.statusCode != 200) {
  //         throw AppException('Failed to submit review');
  //       }
  //     } on DioException catch (e) {
  //       throw _parseDioError(e);
  //     }
  //   }
  Future<List<ReviewModel>> getReviews(String productId) async {
    try {
      debugPrint('🔍 [Review API] Fetching reviews for product: $productId');
      debugPrint(
        '🔍 [Review API] Endpoint: ${ApiConstants.getProductReviewsEndpoint}/$productId',
      );

      final response = await _dio.get(
        '${ApiConstants.getProductReviewsEndpoint}/$productId',
        options: Options(headers: {'accept': '*/*'}),
      );

      debugPrint('🔍 [Review API] Response status: ${response.statusCode}');
      debugPrint(
        '🔍 [Review API] Response data type: ${response.data.runtimeType}',
      );
      debugPrint('🔍 [Review API] Response data: ${response.data}');

      if (response.statusCode == 200 && response.data is List) {
        final reviews =
            (response.data as List)
                .map((e) => ReviewModel.fromJson(e))
                .toList();
        debugPrint(
          '🔍 [Review API] Parsed ${reviews.length} reviews from List',
        );
        return reviews;
      } else if (response.data is Map && response.data['data'] is List) {
        final reviews =
            (response.data['data'] as List)
                .map((e) => ReviewModel.fromJson(e))
                .toList();
        debugPrint(
          '🔍 [Review API] Parsed ${reviews.length} reviews from Map.data',
        );
        return reviews;
      } else if (response.data is Map && response.data['success'] == true) {
        // Handle case where API returns success but no data
        debugPrint('🔍 [Review API] API returned success but no review data');
        return [];
      }

      debugPrint('🔍 [Review API] No reviews found, returning empty list');
      return [];
    } on DioException catch (e) {
      debugPrint('❌ [Review API] DioException: ${e.message}');
      debugPrint('❌ [Review API] Status code: ${e.response?.statusCode}');
      debugPrint('❌ [Review API] Response data: ${e.response?.data}');
      throw _parseDioError(e);
    } catch (e) {
      debugPrint('❌ [Review API] General error: $e');
      throw AppException('Failed to load reviews: $e');
    }
  }

  Future<void> submitReview(ReviewModel review) async {
    try {
      final formData = FormData.fromMap({
        'productId': review.productId,
        'review': review.review,
      });
      final response = await _dio.post(
        ApiConstants.addReviewEndpoint,
        data: formData,
        options: Options(headers: {'accept': '*/*'}),
      );
      if (response.statusCode != 200) {
        throw AppException('Failed to submit review');
      }
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<void> deleteReview(String reviewId) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.deleteReviewEndpoint}/$reviewId',
        options: Options(headers: {'accept': '*/*'}),
      );

      // Check both status code and success flag from response
      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map && responseData['success'] == true) {
          debugPrint(
            '✅ [ApiService] Review deleted: ${responseData['message']}',
          );
          return;
        }
      }

      throw AppException('Failed to delete review');
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<void> updateReview(String reviewId, String newReviewText) async {
    try {
      final formData = FormData.fromMap({'newReviewText': newReviewText});

      debugPrint('🔍 [ApiService] Updating review: $reviewId');
      debugPrint('🔍 [ApiService] New text: $newReviewText');

      final response = await _dio.put(
        '${ApiConstants.editReviewEndpoint}/$reviewId',
        data: formData,
        options: Options(headers: {'accept': '*/*'}),
      );

      debugPrint(
        '🔍 [ApiService] Update response status: ${response.statusCode}',
      );
      debugPrint('🔍 [ApiService] Update response data: ${response.data}');

      // Check both status code and success flag from response
      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map && responseData['success'] == true) {
          debugPrint(
            '✅ [ApiService] Review updated: ${responseData['message']}',
          );
          return;
        } else {
          debugPrint('⚠️ [ApiService] Unexpected response: $responseData');
        }
      }

      throw AppException('Failed to update review');
    } on DioException catch (e) {
      debugPrint('❌ [ApiService] Update error: ${e.message}');
      debugPrint('❌ [ApiService] Error response: ${e.response?.data}');
      throw _parseDioError(e);
    }
  }

  // --- REGISTER LOGIC ---
  Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String password,
    required String confirmPassword,
    required String role,
    required String deviceId,
    String? email,
    String? phoneNumber,
    double? latitude,
    double? longitude,
    File? image,
  }) async {
    try {
      final formData = FormData.fromMap({
        'FullName': fullName,
        'Password': password,
        'ConfirmPassword': confirmPassword,
        'Role': role,
        'DeviceId': deviceId,
        'Email': email ?? '',
        'PhoneNumber': phoneNumber ?? '',
        'Latitude': latitude != null ? latitude.toString() : '',
        'Longitude': longitude != null ? longitude.toString() : '',
        'Image': image != null ? await MultipartFile.fromFile(image.path) : '',
      });
      debugPrint('[registerUser] FormData fields:');
      for (var f in formData.fields) {
        debugPrint('  ${f.key}: ${f.value}');
      }
      debugPrint('[registerUser] Files:');
      for (var f in formData.files) {
        debugPrint('  ${f.key}: ${f.value.filename ?? "<empty>"}');
      }
      final response = await _dio.post(
        ApiConstants.registerEndpoint,
        data: formData,
        options: Options(
          headers: {'accept': 'text/plain'},
          extra: {'guestAccess': true},
        ),
      );
      debugPrint(
        '[registerUser] Response: ${response.statusCode} ${response.data}',
      );
      return response.data;
    } on DioException catch (e) {
      debugPrint('[registerUser] DioException: ${e.toString()}');
      if (e.response != null) {
        debugPrint(
          '[registerUser] DioException response data: ${e.response?.data}',
        );
        final data = e.response?.data;

        String title = 'Registration Failed';
        String message = 'Something went wrong';

        if (data is Map<String, dynamic>) {
          if (data['title'] != null) {
            title = data['title'].toString();
          }

          // extract first error message
          if (data['errors'] != null && data['errors'] is Map) {
            final errors = data['errors'] as Map;
            final firstKey = errors.keys.first;
            final firstError = errors[firstKey];
            if (firstError is List && firstError.isNotEmpty) {
              message = firstError.first.toString();
            }
          }
        }

        PopupService.showSnackbar(
          type: PopupType.error,
          title: title,
          message: message,
        );
      }
      throw _parseDioError(e);
    }
  }

  // --- HEALTH CHECK LOGIC ---
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get(ApiConstants.healthEndpoint);
      return response.statusCode == 200;
    } on DioException {
      PopupService.error(
        'Failed to check health',
        title: 'Health Check Failed',
      );
      return false;
    }
  }

  // --- CART LOGIC ---
  // display the cart

  //  remove    item from cart

  // clear the cart

  Future<bool> addToCart(List<Map<String, dynamic>> items) async {
    try {
      final response = await _dio.post(
        ApiConstants.addToCartEndpoint,
        data: jsonEncode({'items': items}),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      PopupService.error('Failed to add to cart', title: 'Cart Error');
      throw _parseDioError(e);
    }
  }

  Future<UserModel> verifyOtp({
    required String otp,
    required String identifier,
    required String deviceId,
  }) async {
    try {
      final data = FormData.fromMap({
        'EmailorPhone': identifier,
        'otp': otp,
        'DeviceId': deviceId,
      });
      final response = await _dio.post(
        ApiConstants.verifyOtpEndpoint,
        data: data,
        options: Options(
          headers: {'accept': '*/*'},
          extra: {'guestAccess': true},
        ),
      );
      final dataMap = response.data['data'];
      return UserModel(
        id: dataMap['id'] ?? '',
        fullName: dataMap['fullName'] ?? '',
        email: dataMap['email'] ?? '',
        phoneNumber: dataMap['phoneNumber'] ?? '',
        role: dataMap['role'] ?? '',
        address: dataMap['address'] ?? '',
        profileImageUrl: dataMap['profileImageUrl'] ?? '',
        token: dataMap['token'] ?? '',
        refreshToken: dataMap['refreshToken'] ?? '',
        expiration: dataMap['expiration'] ?? '',
        deviceId: dataMap['deviceId'] ?? '',
      );
    } on DioException catch (e) {
      PopupService.error(
        'Failed to verify OTP',
        title: 'OTP Verification Failed',
      );
      throw _parseDioError(e);
    }
  }
  // token fetchng

  // json options
  Future<Options> _jsonOptions() async {
    final token = await _token();
    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
  }

  // --- ERROR HANDLING ---
  AppException _parseDioError(DioException e) {
    String message = 'An error occurred';
    String? title;
    int? statusCode = e.response?.statusCode;

    String? findStringIgnoreCase(Map data, String key) {
      try {
        final entry = data.entries.firstWhere(
          (kv) => kv.key.toString().toLowerCase() == key.toLowerCase(),
          orElse: () => const MapEntry('', null),
        );
        final val = entry.value;
        return val?.toString();
      } catch (_) {
        return null;
      }
    }

    // Small helper to extract meaningful message/title from a Map payload
    void extractFromMap(Map responseMap) {
      // Normalize possible keys: Title/Errors/Message (case-insensitive)
      title = findStringIgnoreCase(responseMap, 'title');
      final msgField = findStringIgnoreCase(responseMap, 'message');

      // Extract first error from Errors/errors if present; prefer MyError
      String? firstErrorMsg;
      dynamic errorsVal =
          responseMap.entries
              .firstWhere(
                (kv) => kv.key.toString().toLowerCase() == 'errors',
                orElse: () => const MapEntry('', null),
              )
              .value;

      if (errorsVal is Map && errorsVal.isNotEmpty) {
        final myErrorEntry = errorsVal.entries.firstWhere(
          (e) => e.key.toString().toLowerCase() == 'myerror',
          orElse: () => const MapEntry('', null),
        );
        final chosen =
            (myErrorEntry.value != null)
                ? myErrorEntry.value
                : errorsVal.values.first;
        if (chosen is List && chosen.isNotEmpty) {
          firstErrorMsg = chosen.first.toString();
        } else {
          firstErrorMsg = chosen?.toString();
        }
      } else if (errorsVal is List && errorsVal.isNotEmpty) {
        firstErrorMsg = errorsVal.first.toString();
      }

      message =
          firstErrorMsg ?? msgField ?? title ?? 'Server error: $statusCode';
    }

    if (e.response != null && e.response!.data != null) {
      final responseData = e.response!.data;
      debugPrint('🔍 [Error Parser] Response data: $responseData');

      if (responseData is String) {
        final raw = responseData.trim();
        // Try to decode JSON-like string to extract proper error fields
        if (raw.startsWith('{') && raw.endsWith('}')) {
          try {
            final decoded = jsonDecode(raw);
            if (decoded is Map) {
              extractFromMap(decoded);
            } else {
              message = responseData; // fallback to raw string
            }
          } catch (_) {
            // As a guard, try regex to grab title/MyError to avoid showing full JSON raw
            try {
              final titleMatch = RegExp(
                r'"title"\s*:\s*"([^"]+)"',
                caseSensitive: false,
              ).firstMatch(raw);
              if (titleMatch != null) title = titleMatch.group(1);
              final myErrorMatch = RegExp(
                r'"MyError"\s*:\s*\[\s*"([^"]+)"',
                caseSensitive: false,
              ).firstMatch(raw);
              if (myErrorMatch != null) {
                message = myErrorMatch.group(1)!;
              } else {
                message = title ?? 'Server error: $statusCode';
              }
            } catch (_) {
              message = 'Server error: $statusCode';
            }
          }
        } else {
          // Plain string message from server; use as-is
          message = responseData;
        }
      } else if (responseData is Map) {
        extractFromMap(responseData);
      }
    } else {
      // Handle network-level errors
      if (e.type == DioExceptionType.connectionTimeout) {
        message = 'Connection timeout - please check your internet connection';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        message = 'Request timeout - server is taking too long to respond';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'Connection error - please check your internet connection';
      } else {
        message = e.message ?? 'Network error occurred';
      }
    }

    debugPrint('🔍 [Error Parser] Final error title: ${title ?? '-'}');
    debugPrint('🔍 [Error Parser] Final error message: $message');
    return AppException(message, statusCode: statusCode, title: title);
  }

  // Method to dispose of resources
  void dispose() {
    _dio.close();
  }
}

//   Future<bool> isFarmerLive(String productId) async {
//     try {
//       final response = await _dio.get(
//         '${ApiConstants.isFarmerLiveEndpoint}/$productId',
//         options: Options(
//           headers: {'accept': '*/*'},
//           extra: {'guestAccess': true},
//         ),
//       );

//       if (response.statusCode == 200) {
//         final data = response.data;
//         if (data is Map<String, dynamic>) {
//           return data['data'] == true; // 🔑 actual field is "data"
//         }
//       }
//       return false;
//     } catch (e) {
//       debugPrint('❌ Error checking farmer live status: $e');
//       return false;
//     }
//   }
// }
