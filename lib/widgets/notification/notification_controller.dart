import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/features/admin/models/notification_model.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/widgets/notification/notification_apiservice.dart';

class NotificationController extends GetxController {
  final RxString errorMessage = ''.obs;
  final RxBool isLoading = false.obs;
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;

  final AuthController _authController = Get.find<AuthController>();
  final NotificationApiservice _apiService =
      Get.isRegistered<NotificationApiservice>()
          ? Get.find<NotificationApiservice>()
          : Get.put(NotificationApiservice());

  int get unreadNotificationCount =>
      notifications.where((n) => !n.isRead).length;

  void _updateLoading(bool value) => isLoading.value = value;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    final userId = _authController.userData?.id;

    if (userId == null) {
      errorMessage.value = 'user_not_logged_in'.tr;
      return;
    }

    try {
      _updateLoading(true);

      // 🔹 Try API first
      final fetchedNotifications = await _apiService.fetchNotifications(
        userId: userId.toString(),
      );
      notifications.assignAll(fetchedNotifications);

      if (fetchedNotifications.isEmpty) {
        // 🔹 If API returns nothing, fallback to mock
        notifications.addAll(_mockNotifications());
      } else {
        notifications.assignAll(fetchedNotifications);
      }
    } catch (e, stack) {
      debugPrint('❌ Notification fetch failed: $e\n$stack');
      errorMessage.value = 'failed_to_fetch_notifications'.tr;

      // 🔹 Always fallback to mock on error
      notifications.assignAll(_mockNotifications());
    } finally {
      _updateLoading(false);
    }
  }

  void markNotificationAsRead(String notificationId) async {
    try {
      _updateLoading(true);
      await _apiService.markNotificationAsRead(notificationId);

      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(isRead: true);
        notifications.refresh();
      }
    } catch (e, stack) {
      debugPrint('❌ Mark-as-read failed: $e\n$stack');
      errorMessage.value = 'failed_to_mark_notification'.tr;
    } finally {
      _updateLoading(false);
    }
  }

  // 🔹 Mock data method
  List<NotificationModel> _mockNotifications() {
    return [
      NotificationModel(
        id: "1",
        message: "Your order #1234 has been shipped!",
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        title: "Order Shipped",
        type: "order",
        relatedId: "1234",
      ),
      NotificationModel(
        id: "2",
        message: "New product added to the catalog",
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        title: "New Product",
        type: "product",
        relatedId: "5678",
      ),
    ];
  }
}
