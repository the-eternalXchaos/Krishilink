import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../services/chat_api_service.dart';
import '../services/chat_cache_service.dart';
import '../services/signalr_service.dart';
import '../services/chat_notification_service.dart';

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    // Register services as singletons
    Get.lazyPut<ChatApiService>(() => ChatApiService(), fenix: true);
    Get.lazyPut<ChatCacheService>(() => ChatCacheService(), fenix: true);
    Get.lazyPut<SignalRService>(() => SignalRService(), fenix: true);
    Get.lazyPut<ChatNotificationService>(() => ChatNotificationService(), fenix: true);

    // Register controller
    Get.lazyPut<ChatController>(() => ChatController(), fenix: true);
  }
}
