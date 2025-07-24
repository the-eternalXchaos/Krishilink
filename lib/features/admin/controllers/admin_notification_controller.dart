// lib/features/admin/controller/admin_notification_controller.dart
import 'package:get/get.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';

class AdminNotificationController extends GetxController {
  final notifications = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      isLoading(true);
      // Mock; replace with API
      notifications.assignAll([
        {'id': '1', 'message': 'New user registered', 'date': DateTime.now()},
      ]);
    } catch (e) {
      PopupService.error('Failed to load notifications: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> sendNotification(String message) async {
    try {
      isLoading(true);
      // Mock; replace with API
      notifications.add({
        'id': '${notifications.length + 1}',
        'message': message,
        'date': DateTime.now(),
      });
      PopupService.success('Notification sent');
    } catch (e) {
      PopupService.error('Failed to send notification: $e');
    } finally {
      isLoading(false);
    }
  }
}
