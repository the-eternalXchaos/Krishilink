import 'package:get/get.dart';

import '../../src/features/ai_chat/presentation/controllers/ai_chat_controller.dart';

class AiChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AiChatController>(() => AiChatController());
    // Get.put(AiChatController()); // Or non-lazy if needed immediately
  }
}
