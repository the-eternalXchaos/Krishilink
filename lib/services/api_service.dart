import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:krishi_link/core/components/material_ui/popup.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/core/utils/constants.dart';
import 'package:krishi_link/exceptions/app_exception.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/models/review_model.dart';
import 'package:krishi_link/features/admin/models/user_model.dart';
import 'package:krishi_link/features/admin/models/product_model.dart';
import 'package:krishi_link/services/popup_service.dart';
import 'package:krishi_link/services/token_service.dart';

class ApiService {
  final Dio _dio;

  Future<Options> getJsonOptions() => _jsonOptions();

  // Protected getter for _dio to allow access in subclasses
  @protected
  Dio get dio => _dio;

  bool _isRefreshing = false;
  static const _maxRetries = 3;

  ApiService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
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
            debugPrint('[Interceptor] Request Headers: ${options.headers}');
            return handler.next(options);
          } catch (e) {
            debugPrint('[Interceptor] Error building auth headers: $e');
            PopupService.error(
              'Failed to build auth headers Login Again',
              title: 'Auth Headers Error',
            );
            return handler.next(options);
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
              PopupService.error(
                'Please login to continue',
                title: 'Session Expired',
              );
              // Get.offAllNamed('/login');
              PopupService.error(
                'Failed to build auth headers Login Again',
                title: 'Auth Headers Error',
              );
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
  Future<List<ReviewModel>> getReviews(String productId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.getProductReviewsEndpoint}/$productId',
        options: Options(headers: {'accept': '*/*'}),
      );
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((e) => ReviewModel.fromJson(e))
            .toList();
      } else if (response.data is Map && response.data['data'] is List) {
        return (response.data['data'] as List)
            .map((e) => ReviewModel.fromJson(e))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _parseDioError(e);
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
      }
      throw _parseDioError(e);
    }
  }

  // --- AI CHAT LOGIC ---
  Future<String> chatWithAI(String message) async {
    try {
      final response = await _dio.post(
        ApiConstants.chatWithAiEndpoint,
        data: jsonEncode(message),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      return response.data.toString();
    } on DioException catch (e) {
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
    if (e.response != null && e.response!.data != null) {
      final responseData = e.response!.data;
      if (responseData is String) {
        message = responseData;
      } else if (responseData is Map<String, dynamic>) {
        message = responseData['message'] ?? 'Failed to process request';
      }
    } else {
      message = e.message ?? 'Network error';
    }
    return AppException(message);
  }

  // Method to dispose of resources
  void dispose() {
    _dio.close();
  }
}
