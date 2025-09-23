import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/features/admin/models/notification_model.dart';
import 'package:krishi_link/src/core/networking/api_service.dart';
import 'package:krishi_link/features/notification/controllers/notification_controller.dart';

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
    } catch (e) {
      debugPrint('❌ Error fetching notifications: $e');
      if (e is DioException) {
        debugPrint('Dio error details: ${e.response?.data}');
        throw Exception(
          'Failed: ${e.response?.data['message'] ?? e.message ?? 'Network error'}',
        );
      }
      rethrow;
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
