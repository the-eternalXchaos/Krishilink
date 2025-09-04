// import 'package:dio/dio.dart';
// import 'package:flutter/foundation.dart';
// import 'package:get/get.dart' hide FormData, MultipartFile;
// import '../models/chat_room.dart';
// import '../models/message.dart';
// import '../../../core/utils/api_constants.dart';
// import '../../../features/auth/controller/auth_controller.dart';

// class ChatApiService {
//   final Dio _dio = Dio(
//     BaseOptions(
//       baseUrl: ApiConstants.baseUrl,
//       connectTimeout: const Duration(seconds: 30),
//       receiveTimeout: const Duration(seconds: 30),
//     ),
//   );

//   final AuthController _authController = Get.find<AuthController>();

//   Future<Options> _getAuthOptions() async {
//     final token = _authController.currentUser.value?.token;
//     if (token == null || token.isEmpty) {
//       throw Exception('No authentication token found');
//     }
//     return Options(
//       headers: {
//         'Authorization': 'Bearer $token',
//         'Content-Type': 'application/json',
//         'accept': 'application/json',
//       },
//     );
//   }

//   // Chat Rooms
//   Future<List<ChatRoom>> getChatRooms({int page = 1, int pageSize = 20}) async {
//     try {
//       final options = await _getAuthOptions();
//       final response = await _dio.get(
//         '/api/chat/rooms',
//         queryParameters: {'page': page, 'pageSize': pageSize},
//         options: options,
//       );

//       if (response.statusCode == 200) {
//         final data = response.data['data'] ?? response.data;
//         if (data is List) {
//           return data.map((e) => ChatRoom.fromJson(e)).toList();
//         }
//         return [];
//       }
//       return [];
//     } catch (e) {
//       throw Exception('Failed to fetch chat rooms: $e');
//     }
//   }

//   Future<ChatRoom> createChatRoom({
//     required String participantId,
//     String? productId,
//     String? initialMessage,
//   }) async {
//     try {
//       final options = await _getAuthOptions();
//       final response = await _dio.post(
//         '/api/chat/rooms',
//         data: {
//           'participantId': participantId,
//           if (productId != null) 'productId': productId,
//           if (initialMessage != null) 'initialMessage': initialMessage,
//         },
//         options: options,
//       );

//       if (response.statusCode == 201 || response.statusCode == 200) {
//         return ChatRoom.fromJson(response.data['data'] ?? response.data);
//       }
//       throw Exception('Failed to create chat room');
//     } catch (e) {
//       throw Exception('Failed to create chat room: $e');
//     }
//   }

//   // Messages
//   Future<List<Message>> getMessages({
//     required String chatRoomId,
//     int page = 1,
//     int pageSize = 50,
//   }) async {
//     try {
//       final options = await _getAuthOptions();
//       final response = await _dio.get(
//         '/api/chat/rooms/$chatRoomId/messages',
//         queryParameters: {'page': page, 'pageSize': pageSize},
//         options: options,
//       );

//       if (response.statusCode == 200) {
//         final data = response.data['data'] ?? response.data;
//         if (data is List) {
//           return data.map((e) => Message.fromJson(e)).toList();
//         }
//         return [];
//       }
//       return [];
//     } catch (e) {
//       throw Exception('Failed to fetch messages: $e');
//     }
//   }

//   Future<Message> sendMessage({
//     required String chatRoomId,
//     required String content,
//     required MessageType type,
//     String? mediaUrl,
//     String? replyToMessageId,
//     Map<String, dynamic>? metadata,
//   }) async {
//     try {
//       final options = await _getAuthOptions();
//       final response = await _dio.post(
//         '/api/chat/rooms/$chatRoomId/messages',
//         data: {
//           'content': content,
//           'type': type.toString().split('.').last,
//           if (mediaUrl != null) 'mediaUrl': mediaUrl,
//           if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
//           if (metadata != null) 'metadata': metadata,
//         },
//         options: options,
//       );

//       if (response.statusCode == 201 || response.statusCode == 200) {
//         return Message.fromJson(response.data['data'] ?? response.data);
//       }
//       throw Exception('Failed to send message');
//     } catch (e) {
//       throw Exception('Failed to send message: $e');
//     }
//   }

//   Future<void> markMessagesAsRead(String chatRoomId) async {
//     try {
//       final options = await _getAuthOptions();
//       await _dio.put('/api/chat/rooms/$chatRoomId/read', options: options);
//     } catch (e) {
//       throw Exception('Failed to mark messages as read: $e');
//     }
//   }

//   // Media Upload
//   Future<String> uploadMedia({
//     required String filePath,
//     required String fileName,
//     required MessageType mediaType,
//   }) async {
//     try {
//       final token = _authController.currentUser.value?.token;
//       if (token == null || token.isEmpty) {
//         throw Exception('No authentication token found');
//       }

//       final formData = FormData.fromMap({
//         'file': await MultipartFile.fromFile(filePath, filename: fileName),
//         'type': mediaType.toString().split('.').last,
//       });

//       final response = await _dio.post(
//         '/api/chat/upload-media',
//         data: formData,
//         options: Options(
//           headers: {
//             'Authorization': 'Bearer $token',
//             'Content-Type': 'multipart/form-data',
//           },
//         ),
//       );

//       if (response.statusCode == 200) {
//         return response.data['url'];
//       }
//       throw Exception('Failed to upload media');
//     } catch (e) {
//       throw Exception('Failed to upload media: $e');
//     }
//   }

//   // Typing indicators
//   Future<void> sendTypingIndicator({
//     required String chatRoomId,
//     required bool isTyping,
//   }) async {
//     try {
//       final options = await _getAuthOptions();
//       await _dio.post(
//         '/api/chat/rooms/$chatRoomId/typing',
//         data: {'isTyping': isTyping},
//         options: options,
//       );
//     } catch (e) {
//       // Don't throw error for typing indicators as they're not critical
//       debugPrint('Failed to send typing indicator: $e');
//     }
//   }

//   // Get user info for chat
//   Future<Map<String, dynamic>> getUserInfo(String userId) async {
//     try {
//       final options = await _getAuthOptions();
//       final response = await _dio.get('/api/users/$userId', options: options);

//       if (response.statusCode == 200) {
//         return response.data['data'] ?? response.data;
//       }
//       throw Exception('Failed to get user info');
//     } catch (e) {
//       throw Exception('Failed to get user info: $e');
//     }
//   }
// }
// lib/features/chat/live_chat/live_chat_api_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/features/chat/live_chat/live_chat_model.dart';
import '../models/chat_room.dart';
import '../models/message.dart';

class LiveChatApiService {
  final Dio dio;
  LiveChatApiService({required this.dio});

  Future<String?> getFarmerIdByProductId(String productId) async {
    try {
      final res = await dio.get(
        '${ApiConstants.getFarmerIdByProductIdEndpoint}/$productId',
        options: Options(
          headers: {'accept': '*/*'},
          extra: {'guestAccess': true},
        ),
      );
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data['data']?.toString();
      }
    } catch (e) {
      debugPrint('❌ getFarmerIdByProductId error: $e');
    }
    return null;
  }

  Future<bool> isFarmerLive(String productId) async {
    try {
      final res = await dio.get(
        '${ApiConstants.isFarmerLiveEndpoint}/$productId',
        options: Options(
          headers: {'accept': '*/*'},
          extra: {'guestAccess': true},
        ),
      );
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data['data'] == true;
      }
    } catch (e) {
      debugPrint('❌ isFarmerLive error: $e');
    }
    return false;
  }

  Future<List<LiveChatMessage>> getChatHistory(String user2Id) async {
    try {
      final res = await dio.get(
        '${ApiConstants.getChatHistoryEndpoint}/$user2Id',
        options: Options(headers: {'accept': '*/*'}),
      );
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final list = (res.data['data'] as List?) ?? const [];
        return list
            .map((e) => LiveChatMessage.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (e) {
      debugPrint('❌ getChatHistory error: $e');
    }
    return const [];
  }

  Future<List<ChatPartner>> getMyCustomersForChat() async {
    try {
      final res = await dio.get(
        ApiConstants.getMyCustomersForChatEndpoint,
        options: Options(headers: {'accept': '*/*'}),
      );
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final list = (res.data['data'] as List?) ?? const [];
        return list
            .map((e) => ChatPartner.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (e) {
      debugPrint('❌ getMyCustomersForChat error: $e');
    }
    return const [];
  }

  // ---- Stubs for legacy room-based controller (no backend support yet) ----
  Future<List<ChatRoom>> getChatRooms({int page = 1, int pageSize = 20}) async {
    // Backend does not expose rooms; return empty list to satisfy callers
    return const <ChatRoom>[];
  }

  Future<List<Message>> getMessages({
    required String chatRoomId,
    int page = 1,
    int pageSize = 50,
  }) async {
    // No room messages endpoint; return empty list
    return const <Message>[];
  }

  Future<Message> sendMessage({
    required String chatRoomId,
    required String content,
    MessageType type = MessageType.text,
    String? mediaUrl,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) async {
    // Not supported on backend; return a synthetic sent message
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatRoomId: chatRoomId,
      senderId: 'me',
      senderName: 'Me',
      content: content,
      type: type,
      status: MessageStatus.sent,
      timestamp: DateTime.now(),
      mediaUrl: mediaUrl,
      metadata: metadata,
      isFromMe: true,
      replyToMessageId: replyToMessageId,
    );
  }

  Future<void> markMessagesAsRead(String chatRoomId) async {
    // No-op stub
  }

  Future<String> uploadMedia({
    required String filePath,
    required String fileName,
    required MessageType mediaType,
  }) async {
    // Not supported; return pseudo-URL so UI can proceed
    return 'media://$fileName';
  }

  Future<ChatRoom> createChatRoom({
    required String participantId,
    String? productId,
    String? initialMessage,
  }) async {
    // Not supported; return a synthetic room object
    final now = DateTime.now();
    return ChatRoom(
      id: 'synthetic-${now.millisecondsSinceEpoch}',
      name: 'Chat',
      participantId: participantId,
      participantName: 'User',
      participantRole: 'user',
      lastMessage: initialMessage,
      lastMessageTime: now,
      unreadCount: 0,
      isOnline: false,
      createdAt: now,
      updatedAt: now,
      productId: productId,
      productName: null,
    );
  }
}
