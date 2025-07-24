import 'package:get/get.dart';

import '../../features/ai_chat/ai_chat_controller.dart';

class AiChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AiChatController>(() => AiChatController());
    // Get.put(AiChatController()); // Or non-lazy if needed immediately
  }
}
