import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import '../models/message.dart';
import '../models/chat_room.dart';
import 'chat_cache_service.dart';

// This function must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized
  // await Firebase.initializeApp();

  final Logger logger = Logger();
  logger.i('Handling background message: ${message.messageId}');

  try {
    // Parse the message data
    final data = message.data;

    if (data['type'] == 'chat_message') {
      // Extract message data
      final String chatRoomId = data['chatRoomId'] ?? '';
      final String messageId = data['messageId'] ?? '';
      final String senderId = data['senderId'] ?? '';
      final String senderName = data['senderName'] ?? '';
      final String content = data['content'] ?? '';
      final String messageType = data['messageType'] ?? 'text';
      final String timestamp = data['timestamp'] ?? '';
      final String? mediaUrl = data['mediaUrl'];
      final String? mediaThumbnail = data['mediaThumbnail'];
      final String? mediaFileName = data['mediaFileName'];
      final int? mediaFileSize = int.tryParse(data['mediaFileSize'] ?? '0');
      final int? mediaDuration = int.tryParse(data['mediaDuration'] ?? '0');
      final Map<String, dynamic>? metadata =
          data['metadata'] != null ? json.decode(data['metadata']) : null;

      // Create Message object
      final Message newMessage = Message(
        id: messageId,
        chatRoomId: chatRoomId,
        senderId: senderId,
        senderName: senderName,
        content: content,
        type: _parseMessageType(messageType),
        status: MessageStatus.delivered,
        timestamp: DateTime.tryParse(timestamp) ?? DateTime.now(),
        mediaUrl: mediaUrl,
        mediaThumbnail: mediaThumbnail,
        mediaFileName: mediaFileName,
        mediaFileSize: mediaFileSize,
        mediaDuration: mediaDuration,
        metadata: metadata,
        isFromMe: false,
      );

      // Save message to local cache
      await _saveMessageToCache(newMessage);

      // Update chat room last message
      await _updateChatRoomLastMessage(chatRoomId, content, DateTime.now());

      logger.i('Background message saved to cache: $messageId');
    }
  } catch (e) {
    logger.e('Error handling background message: $e');
  }
}

MessageType _parseMessageType(String type) {
  switch (type.toLowerCase()) {
    case 'image':
      return MessageType.image;
    case 'document':
      return MessageType.document;
    case 'voice':
      return MessageType.voice;
    case 'video':
      return MessageType.video;
    case 'system':
      return MessageType.system;
    default:
      return MessageType.text;
  }
}

Future<void> _saveMessageToCache(Message message) async {
  try {
    // Initialize Hive if not already done
    // This is a simplified approach - in a real app, you'd ensure Hive is initialized
    final ChatCacheService cacheService = Get.find<ChatCacheService>();
    await cacheService.saveMessage(message);
  } catch (e) {
    // If Get.find fails (app not initialized), we can't save to cache
    // The message will be fetched from server when app opens
    Logger().e('Failed to save background message to cache: $e');
  }
}

Future<void> _updateChatRoomLastMessage(
  String chatRoomId,
  String lastMessage,
  DateTime timestamp,
) async {
  try {
    final ChatCacheService cacheService = Get.find<ChatCacheService>();
    final ChatRoom? existingRoom = cacheService.getChatRoom(chatRoomId);

    if (existingRoom != null) {
      final updatedRoom = existingRoom.copyWith(
        lastMessage: lastMessage,
        lastMessageTime: timestamp,
        unreadCount: existingRoom.unreadCount + 1,
      );
      await cacheService.saveChatRoom(updatedRoom);
    }
  } catch (e) {
    Logger().e('Failed to update chat room last message: $e');
  }
}
