import 'package:krishi_link/src/core/errors/api_exception.dart';
import 'package:krishi_link/src/core/networking/api_client.dart';

/// Base service class that provides common API functionality
abstract class BaseService {
  final ApiClient apiClient;

  BaseService({ApiClient? apiClient})
    : apiClient = apiClient ?? ApiClient.instance;

  /// Handle common API errors and provide user-friendly messages
  String getErrorMessage(ApiException exception) {
    switch (exception.errorCode) {
      case 'NO_INTERNET':
        return 'No internet connection. Please check your network and try again.';
      case 'CONNECTION_TIMEOUT':
      case 'SEND_TIMEOUT':
      case 'RECEIVE_TIMEOUT':
        return 'Request timed out. Please check your connection and try again.';
      case 'UNAUTHORIZED':
        return 'Your session has expired. Please login again.';
      case 'FORBIDDEN':
        return 'You don\'t have permission to perform this action.';
      case 'NOT_FOUND':
        return 'The requested resource was not found.';
      case 'VALIDATION_ERROR':
        return exception.message; // Use the specific validation message
      case 'TOO_MANY_REQUESTS':
        return 'Too many requests. Please wait a moment and try again.';
      case 'INTERNAL_SERVER_ERROR':
        return 'Server error. Please try again later.';
      case 'SERVICE_UNAVAILABLE':
        return 'Service is temporarily unavailable. Please try again later.';
      default:
        return exception.message.isNotEmpty
            ? exception.message
            : 'An unexpected error occurred. Please try again.';
    }
  }

  /// Execute API call with error handling
  Future<T> executeApiCall<T>(Future<T> Function() apiCall) async {
    try {
      return await apiCall();
    } on ApiException {
      rethrow; // Re-throw API exceptions as-is
    } catch (e) {
      // Convert unexpected errors to ApiException
      throw ApiException(
        message: 'An unexpected error occurred: ${e.toString()}',
        statusCode: 500,
        errorCode: 'UNEXPECTED_ERROR',
      );
    }
  }
}
