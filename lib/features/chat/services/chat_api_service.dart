import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import '../models/chat_room.dart';
import '../models/message.dart';
import '../../../core/utils/api_constants.dart';
import '../../../features/auth/controller/auth_controller.dart';

class ChatApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  final AuthController _authController = Get.find<AuthController>();

  Future<Options> _getAuthOptions() async {
    final token = _authController.currentUser.value?.token;
    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
    );
  }

  // Chat Rooms
  Future<List<ChatRoom>> getChatRooms({int page = 1, int pageSize = 20}) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get(
        '/api/chat/rooms',
        queryParameters: {'page': page, 'pageSize': pageSize},
        options: options,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        if (data is List) {
          return data.map((e) => ChatRoom.fromJson(e)).toList();
        }
        return [];
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch chat rooms: $e');
    }
  }

  Future<ChatRoom> createChatRoom({
    required String participantId,
    String? productId,
    String? initialMessage,
  }) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.post(
        '/api/chat/rooms',
        data: {
          'participantId': participantId,
          if (productId != null) 'productId': productId,
          if (initialMessage != null) 'initialMessage': initialMessage,
        },
        options: options,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ChatRoom.fromJson(response.data['data'] ?? response.data);
      }
      throw Exception('Failed to create chat room');
    } catch (e) {
      throw Exception('Failed to create chat room: $e');
    }
  }

  // Messages
  Future<List<Message>> getMessages({
    required String chatRoomId,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get(
        '/api/chat/rooms/$chatRoomId/messages',
        queryParameters: {'page': page, 'pageSize': pageSize},
        options: options,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        if (data is List) {
          return data.map((e) => Message.fromJson(e)).toList();
        }
        return [];
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch messages: $e');
    }
  }

  Future<Message> sendMessage({
    required String chatRoomId,
    required String content,
    required MessageType type,
    String? mediaUrl,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.post(
        '/api/chat/rooms/$chatRoomId/messages',
        data: {
          'content': content,
          'type': type.toString().split('.').last,
          if (mediaUrl != null) 'mediaUrl': mediaUrl,
          if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
          if (metadata != null) 'metadata': metadata,
        },
        options: options,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Message.fromJson(response.data['data'] ?? response.data);
      }
      throw Exception('Failed to send message');
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<void> markMessagesAsRead(String chatRoomId) async {
    try {
      final options = await _getAuthOptions();
      await _dio.put('/api/chat/rooms/$chatRoomId/read', options: options);
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  // Media Upload
  Future<String> uploadMedia({
    required String filePath,
    required String fileName,
    required MessageType mediaType,
  }) async {
    try {
      final token = _authController.currentUser.value?.token;
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        'type': mediaType.toString().split('.').last,
      });

      final response = await _dio.post(
        '/api/chat/upload-media',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data['url'];
      }
      throw Exception('Failed to upload media');
    } catch (e) {
      throw Exception('Failed to upload media: $e');
    }
  }

  // Typing indicators
  Future<void> sendTypingIndicator({
    required String chatRoomId,
    required bool isTyping,
  }) async {
    try {
      final options = await _getAuthOptions();
      await _dio.post(
        '/api/chat/rooms/$chatRoomId/typing',
        data: {'isTyping': isTyping},
        options: options,
      );
    } catch (e) {
      // Don't throw error for typing indicators as they're not critical
      debugPrint('Failed to send typing indicator: $e');
    }
  }

  // Get user info for chat
  Future<Map<String, dynamic>> getUserInfo(String userId) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get('/api/users/$userId', options: options);

      if (response.statusCode == 200) {
        return response.data['data'] ?? response.data;
      }
      throw Exception('Failed to get user info');
    } catch (e) {
      throw Exception('Failed to get user info: $e');
    }
  }
}
