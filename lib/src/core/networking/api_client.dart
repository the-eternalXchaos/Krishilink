import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData;
import 'package:krishi_link/src/features/auth/data/token_service.dart';
import 'package:krishi_link/src/core/errors/api_exception.dart';

/// Core API client for all network requests
class ApiClient {
  static ApiClient? _instance;
  static ApiClient get instance => _instance ??= ApiClient._internal();

  ApiClient._internal();

  late final Dio _dio;

  void initialize({
    required String baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Map<String, dynamic>? headers,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout ?? const Duration(seconds: 30),
        receiveTimeout: receiveTimeout ?? const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...?headers,
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    // Holds ongoing refresh operation so concurrent 401s wait for it.
    Completer<bool>? refreshCompleter;

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final currentAuth = options.headers['Authorization']?.toString();
            final host = options.uri.host.toLowerCase();
            final isKhaltiHost = host.contains('khalti.com');
            final hasExplicitKeyHeader =
                currentAuth != null &&
                currentAuth.trim().toLowerCase().startsWith('key ');
            final guestAccess = options.extra['guestAccess'] == true;
            final skipAuth = options.extra['skipAuth'] == true;

            // Only attach bearer token if it's not an external gateway and not explicitly skipped
            if (!isKhaltiHost &&
                !hasExplicitKeyHeader &&
                !guestAccess &&
                !skipAuth) {
              final token = await TokenService.getAccessToken();
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
            }

            handler.next(options);
          } catch (e) {
            // fail open -> continue with request (so unexpected errors don't block)
            handler.next(options);
          }
        },

        onError: (err, handler) async {
          final options = err.requestOptions;
          final status = err.response?.statusCode;
          final host = options.uri.host.toLowerCase();
          final isKhaltiHost = host.contains('khalti.com');
          final guestAccess = options.extra['guestAccess'] == true;
          final skipAuth = options.extra['skipAuth'] == true;

          // If it's a pure network error (no response) => surface network error
          if (err.type == DioExceptionType.connectionTimeout ||
              err.type == DioExceptionType.receiveTimeout ||
              err.type == DioExceptionType.sendTimeout ||
              err.type == DioExceptionType.badCertificate ||
              err.type ==
                  DioExceptionType
                      .unknown // could be SocketException
                      ) {
            // Mark that last refresh was a network error if relevant
            TokenService.lastRefreshWasNetworkError = true;
            return handler.next(err);
          }

          // Only attempt refresh for auth failures on protected endpoints
          if (status == 401 || status == 403 || status == 498) {
            // Do not touch external gateway requests or explicitly-guest requests
            if (isKhaltiHost || guestAccess || skipAuth) {
              return handler.next(err);
            }

            try {
              // If no stored tokens -> nothing to refresh
              final hasTokens = await TokenService.hasTokens();
              if (!hasTokens) return handler.next(err);

              // Single refresh orchestrator:
              if (refreshCompleter == null) {
                refreshCompleter = Completer<bool>();
                try {
                  final refreshed = await TokenService.refreshAccessToken();
                  TokenService.lastRefreshWasNetworkError = false;
                  refreshCompleter!.complete(refreshed);
                } catch (e) {
                  // check if it was network issue inside TokenService
                  // TokenService should set lastRefreshWasNetworkError appropriately
                  refreshCompleter!.complete(false);
                } finally {
                  // keep the reference for waiting callers to read result
                }
              }

              // Wait for the refresh to finish
              final refreshed = await refreshCompleter!.future;

              // Clear completer reference so future 401 uses a new refresh attempt
              if (refreshCompleter != null && refreshCompleter!.isCompleted) {
                refreshCompleter = null;
              }

              if (refreshed) {
                final newToken = await TokenService.getAccessToken();
                if (newToken != null && newToken.isNotEmpty) {
                  options.headers['Authorization'] = 'Bearer $newToken';
                } else {
                  // Unexpected: treat as no refresh available
                  return handler.next(err);
                }

                // Retry original request with updated token
                try {
                  final response = await _dio.fetch(options);
                  return handler.resolve(response);
                } on DioException catch (e) {
                  return handler.next(e);
                }
              } else {
                // Refresh failed. If it was network error, surface network error to user (do not logout)
                if (TokenService.lastRefreshWasNetworkError) {
                  return handler.next(err);
                } else {
                  // Permanent refresh failure -> clear tokens and redirect to login
                  await TokenService.clearTokens();
                  try {
                    Get.offAllNamed('/login');
                  } catch (_) {}
                  return handler.next(err);
                }
              }
            } catch (e) {
              // anything unexpected - pass original error
              return handler.next(err);
            }
          }

          // For all other errors just continue
          return handler.next(err);
        },
      ),
    );

    // Logging interceptor (only in debug mode)
    if (const bool.fromEnvironment('dart.vm.product') == false) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
        ),
      );
    }
  }

  // void _setupInterceptors() {
  //   // Request interceptor - add auth token
  //   _dio.interceptors.add(
  //     InterceptorsWrapper(
  //       onRequest: (options, handler) async {
  //         // Skip adding Bearer token for external gateways like Khalti,
  //         // when an Authorization header is already explicitly set,
  //         // or when guestAccess is explicitly allowed.
  //         final currentAuth = options.headers['Authorization']?.toString();
  //         final host = options.uri.host.toLowerCase();
  //         final isKhaltiHost = host.contains('khalti.com');
  //         final hasExplicitKeyHeader =
  //             currentAuth != null &&
  //             currentAuth.trim().toLowerCase().startsWith('key ');
  //         final guestAccess = options.extra['guestAccess'] == true;

  //         if (!isKhaltiHost && !hasExplicitKeyHeader && !guestAccess) {
  //           final token = await TokenService.getAccessToken();
  //           if (token != null && token.isNotEmpty) {
  //             options.headers['Authorization'] = 'Bearer $token';
  //           }
  //         }
  //         handler.next(options);
  //       },
  //       onError: (error, handler) async {
  //         final status = error.response?.statusCode;
  //         final options = error.requestOptions;
  //         final host = options.uri.host.toLowerCase();
  //         final isKhaltiHost = host.contains('khalti.com');
  //         final guestAccess = options.extra['guestAccess'] == true;

  //         if (status == 401 && !isKhaltiHost && !guestAccess) {
  //           try {
  //             // If there are no tokens (guest mode), do not attempt refresh or force logout
  //             final hasTokens = await TokenService.hasTokens();
  //             if (!hasTokens) {
  //               return handler.next(error);
  //             }

  //             final refreshed = await TokenService.refreshAccessToken();
  //             if (refreshed) {
  //               final newToken = await TokenService.getAccessToken();
  //               if (newToken != null && newToken.isNotEmpty) {
  //                 options.headers['Authorization'] = 'Bearer $newToken';
  //               }
  //               final response = await _dio.fetch(options);
  //               return handler.resolve(response);
  //             } else {
  //               // If refresh failed due to network issue, do not force logout.
  //               if (!TokenService.lastRefreshWasNetworkError) {
  //                 await TokenService.clearTokens();
  //                 try {
  //                   Get.offAllNamed('/login');
  //                 } catch (_) {}
  //               }
  //             }
  //           } catch (_) {}
  //         }
  //         handler.next(error);
  //       },
  //     ),
  //   );

  //   // Logging interceptor (only in debug mode)
  //   if (const bool.fromEnvironment('dart.vm.product') == false) {
  //     _dio.interceptors.add(
  //       LogInterceptor(
  //         requestBody: true,
  //         responseBody: true,
  //         requestHeader: true,
  //         responseHeader: false,
  //       ),
  //     );
  //   }
  // }

  // GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // Upload file
  Future<Response<T>> upload<T>(
    String path,
    FormData formData, {
    ProgressCallback? onSendProgress,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
