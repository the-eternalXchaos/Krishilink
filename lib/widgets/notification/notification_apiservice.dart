import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:krishi_link/features/notification/model/notification_model.dart';
import 'package:krishi_link/src/core/constants/api_constants.dart';
import 'package:krishi_link/src/core/networking/api_service.dart';

class NotificationApiservice extends ApiService {
  NotificationApiservice() : super();
  Future<List<NotificationModel>> fetchNotifications({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      debugPrint('🔄 [API] Fetching notifications for user: $userId');

      final opts = await getJsonOptions();

      final response = await dio.post(
        ApiConstants.getNotificationsEndpoint,
        queryParameters: {'userId': userId, 'page': page, 'limit': limit},
        options: opts,
        data: {}, // ASP.NET likes non-null body
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response raw: ${response.data}');

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data['data'];
        if (data is List) {
          return data
              .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          debugPrint('⚠️ Unexpected data format: $data');
          return [];
        }
      }

      throw Exception('Failed to fetch notifications: ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint(
        '❌ Dio error fetching notifications: ${e.response?.statusCode} - ${e.message}',
      );

      // Handle specific HTTP error codes
      if (e.response?.statusCode == 502) {
        throw Exception(
          'Server is temporarily unavailable. Please try again later.',
        );
      } else if (e.response?.statusCode == 503) {
        throw Exception(
          'Service is under maintenance. Please try again later.',
        );
      } else if (e.response?.statusCode == 504) {
        throw Exception(
          'Server timeout. Please check your connection and try again.',
        );
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Connection timeout. Please check your internet and try again.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('No internet connection. Please check your network.');
      }

      // Generic error with server message if available
      final errorMsg =
          e.response?.data?['message'] ??
          e.response?.data?['errors']?['MyError']?.first ??
          e.message ??
          'Network error occurred';
      throw Exception('Failed to fetch notifications: $errorMsg');
    } catch (e) {
      debugPrint('❌ Unexpected error fetching notifications: $e');
      throw Exception('Failed to fetch notifications. Please try again.');
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final opts = await getJsonOptions();
      final response = await dio.put(
        '${ApiConstants.markNotificationAsReadEndpoint}/$notificationId',
        options: opts,
      );
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to mark notification as read: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      if (e is DioException) {
        debugPrint('Dio error details: ${e.response?.data}');
        throw Exception(
          'Failed to mark notification as read: ${e.response?.data['message'] ?? e.message ?? 'Network error'}',
        );
      }
      rethrow;
    }
  }
}
