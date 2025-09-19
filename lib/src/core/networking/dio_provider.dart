import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:krishi_link/services/token_service.dart';
import 'package:krishi_link/core/utils/api_constants.dart';

/// Centralized Dio provider registered with Get.lazyPut(fenix: true)
/// Ensures:
///  - Single logical instance (recreated if disposed)
///  - Dynamic token attachment through an interceptor
///  - Rebuild capability when base URL / global config changes
class DioProvider {
  DioProvider() {
    _dio = _createDio();
  }

  late Dio _dio;
  Dio get client => _dio;

  // Prevent multiple simultaneous refreshes / rebuilds
  Future<bool>? _refreshFuture;
  bool _rebuildInProgress = false;

  Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(_SelfHealingInterceptor(this));
    dio.interceptors.add(_AuthInterceptor(this));
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: false,
        requestHeader: false,
        responseHeader: false,
      ),
    );
    return dio;
  }

  void rebuild({bool forceClose = true}) {
    if (_rebuildInProgress) return;
    _rebuildInProgress = true;
    try {
      try {
        if (forceClose) {
          _dio.httpClientAdapter.close(force: true);
        }
      } catch (_) {}
      _dio = _createDio();
    } finally {
      _rebuildInProgress = false;
    }
  }

  Future<bool> performSerializedRefresh(Future<bool> Function() action) {
    final existing = _refreshFuture;
    if (existing != null) return existing;
    final completer = Completer<bool>();
    _refreshFuture = completer.future;
    () async {
      bool ok = false;
      try {
        ok = await action();
        completer.complete(ok);
      } catch (_) {
        completer.complete(false);
      } finally {
        _refreshFuture = null;
      }
    }();
    return _refreshFuture!;
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this.provider);
  final DioProvider provider;

  bool _shouldSkip(RequestOptions o) =>
      o.extra['skipAuth'] == true || o.extra['guestAccess'] == true;

  @override
  Future onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_shouldSkip(options)) return handler.next(options);
    final token = await TokenService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final opts = err.requestOptions;
    if (status == 401 && !_shouldSkip(opts)) {
      final hasTokens = await TokenService.hasTokens();
      if (!hasTokens) return handler.next(err);
      final refreshed = await provider.performSerializedRefresh(
        () async => await TokenService.refreshAccessToken(),
      );
      if (refreshed) {
        final newToken = await TokenService.getAccessToken();
        if (newToken != null && newToken.isNotEmpty) {
          opts.headers['Authorization'] = 'Bearer $newToken';
        }
        try {
          final response = await provider.client.fetch(opts);
          return handler.resolve(response);
        } catch (_) {}
      } else {
        if (!TokenService.lastRefreshWasNetworkError) {
          await TokenService.clearTokens();
          try {
            Get.offAllNamed('/login');
          } catch (_) {}
        }
      }
    }
    return handler.next(err);
  }
}

class _SelfHealingInterceptor extends Interceptor {
  _SelfHealingInterceptor(this.provider);
  final DioProvider provider;

  bool _looksClosed(DioException e) {
    final msg = (e.message ?? '').toLowerCase();
    return msg.contains(
          "can't establish a new connection after it was closed",
        ) ||
        msg.contains('connection was disposed') ||
        msg.contains('client is closed');
  }

  @override
  Future onError(DioException err, ErrorInterceptorHandler handler) async {
    final alreadyRetried = err.requestOptions.extra['__healed'] == true;
    if (!alreadyRetried && _looksClosed(err)) {
      provider.rebuild(forceClose: true);
      try {
        final opts = err.requestOptions;
        opts.extra['__healed'] = true;
        final response = await provider.client.fetch(opts);
        return handler.resolve(response);
      } catch (_) {}
    }
    return handler.next(err);
  }
}

void registerDioProvider() {
  if (!Get.isRegistered<DioProvider>()) {
    Get.lazyPut<DioProvider>(() => DioProvider(), fenix: true);
  }
}

/// Convenience helper to access shared Dio succinctly.
extension DioGetX on GetInterface {
  Dio dio() => find<DioProvider>().client;
}
