// import 'package:dio/dio.dart';
// import 'package:flutter/foundation.dart';
// import 'package:get/get_core/get_core.dart';
// import 'package:get/get_navigation/get_navigation.dart';
// import 'package:krishi_link/core/utils/api_constants.dart';
// import 'package:krishi_link/exceptions/app_exception.dart';
// import 'package:krishi_link/models/review_model.dart';
// import 'package:krishi_link/features/admin/models/user_model.dart';
// import 'package:krishi_link/services/token_service.dart';

// class ApiService {
//   final Dio _dio;
//   bool _isRefreshing = false;
//   static const _maxRetries = 3;

//   ApiService()
//     : _dio = Dio(
//         BaseOptions(
//           baseUrl: ApiConstants.baseUrl,
//           connectTimeout: const Duration(seconds: 30),
//           receiveTimeout: const Duration(seconds: 30),
//           headers: {'Content-Type': 'application/json'},
//         ),
//       ) {
//     _configureInterceptors();
//   }

//   void _configureInterceptors() {
//     _dio.interceptors.clear();
//     _dio.interceptors.add(
//       InterceptorsWrapper(
//         onRequest: (options, handler) async {
//           try {
//             // Skip auth headers for auth-related endpoints
//             if (options.path.contains('/auth/') ||
//                 options.path.contains('/otp/') ||
//                 options.path.contains('/verify-otp/') ||
//                 options.path.contains('/otp-verify/') ||
//                 options.path.contains('/verify/')) {
//               return handler.next(options);
//             }

//             final headers = await TokenService.getAuthHeaders();
//             options.headers.addAll(headers);
//             return handler.next(options);
//           } catch (e) {
//             debugPrint('Error in request interceptor: $e');
//             return handler.next(options);
//           }
//         },
//         onError: (error, handler) async {
//           // Only attempt refresh for authenticated endpoints
//           if (error.response?.statusCode == 401 &&
//               !error.requestOptions.path.contains('/auth/')) {
//             try {
//               final retryResponse = await _handleTokenRefresh(error);
//               if (retryResponse != null) {
//                 return handler.resolve(retryResponse);
//               }
//             } catch (e) {
//               debugPrint('Token refresh failed: $e');
//               await TokenService.clearTokens();
//               // Redirect to login on refresh failure
//               Get.offAllNamed('/login');
//             }
//           }
//           return handler.next(error);
//         },
//       ),
//     );
//   }

//   Future<Response<dynamic>?> _handleTokenRefresh(DioException error) async {
//     // If this request doesn't need authentication, don't try to refresh
//     if (!error.requestOptions.headers.containsKey('Authorization')) {
//       return null;
//     }

//     if (_isRefreshing) {
//       // Wait for the other refresh to complete and retry the request
//       await Future.delayed(const Duration(milliseconds: 500));
//       return _retryRequest(error.requestOptions);
//     }

//     try {
//       _isRefreshing = true;
//       final refreshToken = await TokenService.getRefreshToken();
//       if (refreshToken == null) {
//         await TokenService.clearTokens();
//         return null;
//       }

//       final response = await _dio.post(
//         ApiConstants.refreshTokenEndpoint,
//         data: {'refresh_token': refreshToken},
//         options: Options(headers: {'accept': '*/*'}),
//       );

//       if (response.statusCode == 200 && response.data != null) {
//         final data = response.data is Map<String, dynamic> ? response.data : {};
//         final apiData = data['data'] ?? {};
//         await TokenService.saveTokens(
//           accessToken: apiData['token'] ?? '',
//           refreshToken: apiData['refreshToken'] ?? '',
//           expiration: apiData['expiration'] ?? DateTime.now().toIso8601String(),
//         );
//         return _retryRequest(error.requestOptions);
//       }
//     } catch (e) {
//       await TokenService.clearTokens();
//     } finally {
//       _isRefreshing = false;
//     }
//     return null;
//   }

//   Future<Response<dynamic>> _retryRequest(
//     RequestOptions requestOptions, [
//     int retryCount = 0,
//   ]) async {
//     try {
//       final headers = await TokenService.getAuthHeaders();
//       requestOptions.headers.addAll(headers);
//       return await _dio.fetch(requestOptions);
//     } catch (e) {
//       if (retryCount < _maxRetries - 1 && e is DioException) {
//         await Future.delayed(Duration(milliseconds: 500 * (retryCount + 1)));
//         return _retryRequest(requestOptions, retryCount + 1);
//       }
//       rethrow;
//     }
//   }

//   // Rest of your ApiService implementation...
// }
