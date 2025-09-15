import 'package:dio/dio.dart';

/// Custom exception class for API-related errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final dynamic data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.data,
  });

  /// Create ApiException from DioException
  factory ApiException.fromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
        return const ApiException(
          message: 'Connection timeout. Please check your internet connection.',
          statusCode: 408,
          errorCode: 'CONNECTION_TIMEOUT',
        );

      case DioExceptionType.sendTimeout:
        return const ApiException(
          message: 'Request timeout. Please try again.',
          statusCode: 408,
          errorCode: 'SEND_TIMEOUT',
        );

      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message: 'Response timeout. Please try again.',
          statusCode: 408,
          errorCode: 'RECEIVE_TIMEOUT',
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(dioException);

      case DioExceptionType.cancel:
        return const ApiException(
          message: 'Request was cancelled.',
          statusCode: 499,
          errorCode: 'REQUEST_CANCELLED',
        );

      case DioExceptionType.connectionError:
        return const ApiException(
          message: 'No internet connection. Please check your network.',
          statusCode: 0,
          errorCode: 'NO_INTERNET',
        );

      case DioExceptionType.badCertificate:
        return const ApiException(
          message: 'Certificate verification failed.',
          statusCode: 495,
          errorCode: 'BAD_CERTIFICATE',
        );

      case DioExceptionType.unknown:
        return ApiException(
          message: dioException.message ?? 'An unexpected error occurred.',
          statusCode: 500,
          errorCode: 'UNKNOWN_ERROR',
        );
    }
  }

  static ApiException _handleBadResponse(DioException dioException) {
    final response = dioException.response;
    final statusCode = response?.statusCode ?? 0;
    final data = response?.data;

    String message;
    String errorCode;

    switch (statusCode) {
      case 400:
        message =
            _extractErrorMessage(data) ??
            'Bad request. Please check your input.';
        errorCode = 'BAD_REQUEST';
        break;
      case 401:
        message = 'Unauthorized. Please login again.';
        errorCode = 'UNAUTHORIZED';
        break;
      case 403:
        message = 'Access forbidden. You don\'t have permission.';
        errorCode = 'FORBIDDEN';
        break;
      case 404:
        message = 'Resource not found.';
        errorCode = 'NOT_FOUND';
        break;
      case 422:
        message = _extractErrorMessage(data) ?? 'Validation failed.';
        errorCode = 'VALIDATION_ERROR';
        break;
      case 429:
        message = 'Too many requests. Please try again later.';
        errorCode = 'TOO_MANY_REQUESTS';
        break;
      case 500:
        message = 'Internal server error. Please try again.';
        errorCode = 'INTERNAL_SERVER_ERROR';
        break;
      case 502:
        message = 'Bad gateway. Server is temporarily unavailable.';
        errorCode = 'BAD_GATEWAY';
        break;
      case 503:
        message = 'Service unavailable. Please try again later.';
        errorCode = 'SERVICE_UNAVAILABLE';
        break;
      default:
        message =
            _extractErrorMessage(data) ??
            'An error occurred. Please try again.';
        errorCode = 'HTTP_ERROR_$statusCode';
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      errorCode: errorCode,
      data: data,
    );
  }

  static String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      // Try common error message fields
      if (data['message'] is String) return data['message'];
      if (data['error'] is String) return data['error'];
      if (data['detail'] is String) return data['detail'];
      if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
        final firstError = (data['errors'] as List).first;
        if (firstError is String) return firstError;
        if (firstError is Map && firstError['message'] is String) {
          return firstError['message'];
        }
      }
    }
    return null;
  }

  @override
  String toString() {
    return 'ApiException: $message (Code: $statusCode, Error: $errorCode)';
  }
}

/// Specific exception for authentication errors
class AuthException extends ApiException {
  const AuthException({
    required super.message,
    super.statusCode = 401,
    super.errorCode = 'AUTH_ERROR',
    super.data,
  });
}

/// Specific exception for validation errors
class ValidationException extends ApiException {
  final Map<String, List<String>>? fieldErrors;

  const ValidationException({
    required super.message,
    super.statusCode = 422,
    super.errorCode = 'VALIDATION_ERROR',
    super.data,
    this.fieldErrors,
  });
}

/// Specific exception for network connectivity issues
class NetworkException extends ApiException {
  const NetworkException({
    super.message = 'No internet connection. Please check your network.',
    super.statusCode = 0,
    super.errorCode = 'NO_INTERNET',
    super.data,
  });
}
