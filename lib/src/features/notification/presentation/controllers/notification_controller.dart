import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/notification/model/notification_model.dart';
import 'package:krishi_link/widgets/notification/notification_apiservice.dart';

class NotificationController extends GetxController {
  final RxString errorMessage = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxBool hasError = false.obs;
  final RxInt currentPage = 1.obs;
  final RxBool hasMorePages = true.obs;
  final RxBool isLoadingMore = false.obs;

  final AuthController _authController = Get.find<AuthController>();
  final NotificationApiservice _apiService =
      Get.isRegistered<NotificationApiservice>()
          ? Get.find<NotificationApiservice>()
          : Get.put(NotificationApiservice());

  static const int _pageLimit = 20;

  int get unreadNotificationCount =>
      notifications.where((n) => !n.isRead).length;

  bool get hasNotifications => notifications.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  /// Fetch notifications with pagination support
  Future<void> fetchNotifications({bool isRefresh = false}) async {
    final userId = _authController.userData?.id;

    if (userId == null) {
      _setError('user_not_logged_in'.tr);
      return;
    }

    try {
      if (isRefresh) {
        isRefreshing.value = true;
        currentPage.value = 1;
        hasMorePages.value = true;
      } else if (currentPage.value == 1) {
        isLoading.value = true;
      }

      hasError.value = false;
      errorMessage.value = '';

      final fetchedNotifications = await _apiService.fetchNotifications(
        userId: userId.toString(),
        page: currentPage.value,
        limit: _pageLimit,
      );

      if (isRefresh || currentPage.value == 1) {
        notifications.assignAll(fetchedNotifications);
      } else {
        notifications.addAll(fetchedNotifications);
      }

      // Update pagination state
      hasMorePages.value = fetchedNotifications.length >= _pageLimit;
      if (hasMorePages.value) {
        currentPage.value++;
      }
    } catch (e, stack) {
      debugPrint('❌ Notification fetch failed: $e\n$stack');

      // Extract user-friendly error message
      String errorMsg = 'failed_to_fetch_notifications'.tr;
      if (e.toString().contains('Server is temporarily unavailable')) {
        errorMsg = 'Server is temporarily unavailable. Please try again later.';
      } else if (e.toString().contains('No internet connection')) {
        errorMsg = 'No internet connection. Please check your network.';
      } else if (e.toString().contains('timeout')) {
        errorMsg = 'Connection timeout. Please try again.';
      } else if (e.toString().contains('maintenance')) {
        errorMsg = 'Service is under maintenance. Please try again later.';
      }

      _setError(errorMsg);
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Load more notifications for pagination
  Future<void> loadMoreNotifications() async {
    if (isLoadingMore.value || !hasMorePages.value) return;

    isLoadingMore.value = true;
    await fetchNotifications();
  }

  /// Mark notification as read with optimistic updates
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      // Optimistic update
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !notifications[index].isRead) {
        notifications[index] = notifications[index].copyWith(isRead: true);
        notifications.refresh();
      }

      await _apiService.markNotificationAsRead(notificationId);
    } catch (e, stack) {
      debugPrint('❌ Mark-as-read failed: $e\n$stack');

      // Revert optimistic update on error
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(isRead: false);
        notifications.refresh();
      }

      Get.snackbar(
        'error'.tr,
        'failed_to_mark_notification'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
        icon: Icon(Icons.error_outline, color: Get.theme.colorScheme.error),
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final unreadNotifications = notifications.where((n) => !n.isRead).toList();
    if (unreadNotifications.isEmpty) return;

    try {
      // Optimistic update
      for (int i = 0; i < notifications.length; i++) {
        if (!notifications[i].isRead) {
          notifications[i] = notifications[i].copyWith(isRead: true);
        }
      }
      notifications.refresh();

      // API calls for each unread notification
      await Future.wait(
        unreadNotifications.map(
          (notification) => _apiService.markNotificationAsRead(notification.id),
        ),
      );

      Get.snackbar(
        'success'.tr,
        'all_notifications_marked_read'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.primary,
        icon: Icon(Icons.check_circle, color: Get.theme.colorScheme.primary),
        duration: const Duration(seconds: 2),
      );
    } catch (e, stack) {
      debugPrint('❌ Mark all as read failed: $e\n$stack');

      // Revert optimistic update on error
      for (int i = 0; i < notifications.length; i++) {
        final originalNotification = unreadNotifications.firstWhere(
          (n) => n.id == notifications[i].id,
          orElse: () => notifications[i],
        );
        if (unreadNotifications.any((n) => n.id == notifications[i].id)) {
          notifications[i] = originalNotification;
        }
      }
      notifications.refresh();

      Get.snackbar(
        'error'.tr,
        'failed_to_mark_all_notifications'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
        icon: Icon(Icons.error_outline, color: Get.theme.colorScheme.error),
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      // Optimistic update
      final removedNotification = notifications.firstWhere(
        (n) => n.id == notificationId,
      );
      notifications.removeWhere((n) => n.id == notificationId);

      // TODO: Add API call for delete notification
      // await _apiService.deleteNotification(notificationId);

      Get.snackbar(
        'success'.tr,
        'notification_deleted'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.primary,
        icon: Icon(Icons.delete_outline, color: Get.theme.colorScheme.primary),
        duration: const Duration(seconds: 2),
        mainButton: TextButton(
          onPressed: () {
            notifications.add(removedNotification);
            notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            Get.back();
          },
          child: Text('undo'.tr),
        ),
      );
    } catch (e, stack) {
      debugPrint('❌ Delete notification failed: $e\n$stack');

      Get.snackbar(
        'error'.tr,
        'failed_to_delete_notification'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
        icon: Icon(Icons.error_outline, color: Get.theme.colorScheme.error),
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      final backupNotifications = List<NotificationModel>.from(notifications);
      notifications.clear();

      // TODO: Add API call for clear all notifications
      // await _apiService.clearAllNotifications();

      Get.snackbar(
        'success'.tr,
        'all_notifications_cleared'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.primary,
        icon: Icon(Icons.clear_all, color: Get.theme.colorScheme.primary),
        duration: const Duration(seconds: 3),
        mainButton: TextButton(
          onPressed: () {
            notifications.assignAll(backupNotifications);
            Get.back();
          },
          child: Text('undo'.tr),
        ),
      );
    } catch (e, stack) {
      debugPrint('❌ Clear all notifications failed: $e\n$stack');

      Get.snackbar(
        'error'.tr,
        'failed_to_clear_notifications'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
        icon: Icon(Icons.error_outline, color: Get.theme.colorScheme.error),
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Retry fetching notifications
  Future<void> retry() async {
    currentPage.value = 1;
    hasMorePages.value = true;
    await fetchNotifications();
  }

  void _setError(String message) {
    hasError.value = true;
    errorMessage.value = message;
  }
}
