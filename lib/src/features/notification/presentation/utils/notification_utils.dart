import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/features/notification/model/notification_model.dart';

class NotificationUtils {
  /// Handle notification tap based on notification type
  static void handleNotificationTap(NotificationModel notification) {
    // Handle navigation based on notification type
    switch (notification.type) {
      case 'order':
        if (notification.relatedId != null) {
          Get.toNamed('/order-details', arguments: notification.relatedId);
        }
        break;
      case 'product':
        if (notification.relatedId != null) {
          Get.toNamed('/product-details', arguments: notification.relatedId);
        }
        break;
      case 'message':
        if (notification.relatedId != null) {
          Get.toNamed('/messages', arguments: notification.relatedId);
        }
        break;
      case 'promotion':
        Get.toNamed('/promotions');
        break;
      default:
        PopupService.showFeedback('Notification opened');
    }
  }

  /// Show delete confirmation dialog
  static void showDeleteDialog(
    NotificationModel notification,
    VoidCallback onConfirm,
  ) {
    Get.dialog(
      AlertDialog(
        title: Text('delete_notification'.tr),
        content: Text('delete_notification_confirm'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () {
              Get.back();
              onConfirm();
            },
            child: Text(
              'delete'.tr,
              style: TextStyle(color: Get.theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  /// Show clear all confirmation dialog
  static void showClearAllDialog(VoidCallback onConfirm) {
    Get.dialog(
      AlertDialog(
        title: Text('clear_all_notifications'.tr),
        content: Text('clear_all_notifications_confirm'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () {
              Get.back();
              onConfirm();
            },
            child: Text(
              'clear_all'.tr,
              style: TextStyle(color: Get.theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
