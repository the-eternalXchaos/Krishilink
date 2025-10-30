// Legacy compatibility shim for architecture compliance.
//
// Primary export: canonical chat service under lib/src/.
export 'package:krishi_link/src/features/chat/data/chat_services.dart';

// Minimal shim to preserve old type used by legacy controllers/bindings.
// The legacy SignalRService exposed room-centric APIs that are no longer
// supported. This stub keeps the app compiling while that code path is phased
// out. All methods are no-ops and callbacks are never fired.
//
// If you still rely on these, migrate to ChatService (user-to-user) located at
// src/features/chat/data/live_chat_service.dart.

import 'package:get/get.dart';
import '../models/message.dart';

class SignalRService extends GetxService {
	// connection state used by legacy ChatController
	final RxBool isConnected = false.obs;

	// legacy callbacks (never invoked in this shim)
	void Function(Message message)? onMessageReceived;
	void Function(String userId, bool isTyping)? onTypingChanged;
	void Function(String userId)? onUserOnline;
	void Function(String userId)? onUserOffline;
	void Function(String messageId)? onMessageRead;

	Future<void> joinChatRoom(String chatRoomId) async {}
	Future<void> leaveChatRoom(String chatRoomId) async {}
	Future<void> markMessageAsRead(String messageId) async {}

	Future<void> sendTypingIndicator({
		required String chatRoomId,
		required bool isTyping,
	}) async {}

	Future<void> sendMessage({
		required String chatRoomId,
		required String content,
		required MessageType type,
		String? mediaUrl,
		String? replyToMessageId,
		Map<String, dynamic>? metadata,
	}) async {}
}
