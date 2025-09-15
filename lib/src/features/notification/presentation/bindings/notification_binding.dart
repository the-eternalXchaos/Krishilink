import 'package:get/get.dart';
import 'package:krishi_link/src/features/notification/presentation/controllers/notification_controller.dart';
import 'package:krishi_link/widgets/notification/notification_apiservice.dart';

class NotificationBinding extends Bindings {
  @override
  void dependencies() {
    // Register API service
    Get.lazyPut<NotificationApiservice>(() => NotificationApiservice());

    // Register controller with permanent flag to survive hot restarts
    Get.put<NotificationController>(NotificationController(), permanent: true);
  }
}
