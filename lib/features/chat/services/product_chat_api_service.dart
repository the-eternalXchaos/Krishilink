import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:krishi_link/src/core/constants/api_constants.dart';
import '../../../features/auth/controller/auth_controller.dart';
import '../models/simple_chat_room.dart';
import '../models/simple_message.dart';

class ProductChatApiService {
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

  /// Get farmer ID by product ID
  /// GET /api/Chat/getFarmerIdByProductId/{productId}
  Future<String> getFarmerIdByProductId(String productId) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get(
        '/api/Chat/getFarmerIdByProductId/$productId',
        options: options,
      );

      if (response.statusCode == 200) {
        // Assuming the response contains the farmer ID
        return response.data['farmerId'] ?? response.data.toString();
      }
      throw Exception('Failed to get farmer ID');
    } catch (e) {
      throw Exception('Failed to get farmer ID: $e');
    }
  }

  /// Get chat history with a user
  /// GET /api/Chat/getChatHistory/{user2Id}
  Future<List<SimpleMessage>> getChatHistory(String user2Id) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get(
        '/api/Chat/getChatHistory/$user2Id',
        options: options,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.map((e) => _mapToMessage(e)).toList();
        } else if (data is Map && data['messages'] != null) {
          final messages = data['messages'] as List;
          return messages.map((e) => _mapToMessage(e)).toList();
        }
        return [];
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get chat history: $e');
    }
  }

  /// Check if farmer is live
  /// GET /api/Chat/IsFarmerLive/{productId}
  Future<bool> isFarmerLive(String productId) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get(
        '/api/Chat/IsFarmerLive/$productId',
        options: options,
      );

      if (response.statusCode == 200) {
        return response.data['isLive'] ?? response.data == true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to check farmer status: $e');
    }
  }

  /// Get my customers for chat
  /// GET /api/Chat/getMyCustomersForChat
  Future<List<SimpleChatRoom>> getMyCustomersForChat() async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get(
        '/api/Chat/getMyCustomersForChat',
        options: options,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.map((e) => _mapToChatRoom(e)).toList();
        } else if (data is Map && data['customers'] != null) {
          final customers = data['customers'] as List;
          return customers.map((e) => _mapToChatRoom(e)).toList();
        }
        return [];
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get customers: $e');
    }
  }

  /// Send message to a user
  /// POST /api/chat/rooms/{roomId}/messages
  Future<SimpleMessage> sendMessage({
    required String chatRoomId,
    required String content,
    String? productId,
    String? productName,
  }) async {
    try {
      final options = await _getAuthOptions();
      final payload = {
        'content': content,
        if (productId != null) 'productId': productId,
        if (productName != null) 'productName': productName,
      };
      final response = await _dio.post(
        '/api/chat/rooms/$chatRoomId/messages', // This is a more RESTful endpoint
        data: payload,
        options: options,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _mapToMessage(response.data);
      }
      throw Exception('Failed to send message');
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Create or get existing chat room for product
  Future<SimpleChatRoom> getOrCreateProductChatRoom({
    required String productId,
    required String farmerId,
    required String farmerName,
    required String productName,
  }) async {
    try {
      final currentUser = _authController.currentUser.value;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Create a chat room ID based on product and users
      final chatRoomId = '${productId}_${currentUser.id}_$farmerId';
      
      return SimpleChatRoom(
        id: chatRoomId,
        name: farmerName,
        participantId: farmerId,
        participantName: farmerName,
        participantRole: 'farmer',
        productId: productId,
        productName: productName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to create chat room: $e');
    }
  }

  /// Map API response to Message model
  SimpleMessage _mapToMessage(Map<String, dynamic> data) {
    final currentUser = _authController.currentUser.value;
    final senderId = data['senderId']?.toString() ?? data['userId']?.toString() ?? '';
    
    return SimpleMessage(
      id: data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      chatRoomId: data['chatRoomId']?.toString() ?? '',
      senderId: senderId,
      senderName: data['senderName']?.toString() ?? data['userName']?.toString() ?? 'Unknown',
      content: data['content']?.toString() ?? data['message']?.toString() ?? '',
      type: MessageType.text,
      status: MessageStatus.sent,
      timestamp: data['timestamp'] != null 
          ? DateTime.parse(data['timestamp'].toString())
          : DateTime.now(),
      isFromMe: senderId == currentUser?.id,
      metadata: {
        if (data['productId'] != null) 'productId': data['productId'],
        if (data['productName'] != null) 'productName': data['productName'],
      },
    );
  }

  /// Map API response to ChatRoom model
  SimpleChatRoom _mapToChatRoom(Map<String, dynamic> data) {
    return SimpleChatRoom(
      id: data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: data['name']?.toString() ?? data['customerName']?.toString() ?? 'Unknown',
      participantId: data['participantId']?.toString() ?? data['customerId']?.toString() ?? '',
      participantName: data['participantName']?.toString() ?? data['customerName']?.toString() ?? 'Unknown',
      participantRole: data['participantRole']?.toString() ?? 'buyer',
      lastMessage: data['lastMessage']?.toString(),
      lastMessageTime: data['lastMessageTime'] != null 
          ? DateTime.parse(data['lastMessageTime'].toString())
          : null,
      unreadCount: data['unreadCount'] ?? 0,
      isOnline: data['isOnline'] ?? false,
      createdAt: data['createdAt'] != null 
          ? DateTime.parse(data['createdAt'].toString())
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? DateTime.parse(data['updatedAt'].toString())
          : DateTime.now(),
      productId: data['productId']?.toString(),
      productName: data['productName']?.toString(),
    );
  }
}