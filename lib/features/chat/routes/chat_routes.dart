import 'package:get/get.dart';
import '../bindings/chat_binding.dart';
import '../screens/chat_list_screen.dart';
import '../screens/chat_thread_screen.dart';

class ChatRoutes {
  static const String chatList = '/chat/list';
  static const String chatThread = '/chat/thread';

  static final routes = [
    GetPage(
      name: chatList,
      page: () => const ChatListScreen(),
      binding: ChatBinding(),
    ),
    GetPage(
      name: chatThread,
      page: () => ChatThreadScreen(chatRoom: Get.arguments),
      binding: ChatBinding(),
    ),
  ];
}
