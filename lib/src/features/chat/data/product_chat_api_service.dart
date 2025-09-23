import 'package:dio/dio.dart' show Options;
import 'package:krishi_link/src/core/networking/base_service.dart';
import 'package:krishi_link/src/features/chat/models/simple_chat_room.dart';
import 'package:krishi_link/src/features/chat/models/simple_message.dart';
import 'package:krishi_link/src/core/storage/token_storage.dart';
import 'package:krishi_link/src/features/auth/data/token_service.dart';

class ProductChatApiService extends BaseService {
  Future<String?> getFarmerIdByProductId(String productId) async {
    return executeApiCall(() async {
      final response = await apiClient.get(
        '/api/Chat/getFarmerIdByProductId/$productId',
        options: Options(extra: {'guestAccess': true}),
      );
      final data = response.data;
      if (data is Map && data['data'] != null) {
        return data['data'].toString();
      }
      return data?.toString();
    });
  }

  Future<List<SimpleMessage>> getChatHistory(String user2Id) async {
    final currentUserId = await TokenStorage.getUserId();
    // Only fetch history when authenticated
    if (!(await TokenService.hasTokens())) {
      return <SimpleMessage>[];
    }
    return executeApiCall(() async {
      final response = await apiClient.get('/api/Chat/getChatHistory/$user2Id');
      final data = response.data;
      if (data is List) {
        return data.map((e) => _mapToMessage(e, currentUserId)).toList();
      } else if (data is Map && data['messages'] != null) {
        final messages = data['messages'] as List;
        return messages.map((e) => _mapToMessage(e, currentUserId)).toList();
      }
      return [];
    });
  }

  Future<bool> isFarmerLive(String productId) async {
    return executeApiCall(() async {
      final response = await apiClient.get(
        '/api/Chat/IsFarmerLive/$productId',
        options: Options(extra: {'guestAccess': true}),
      );
      if (response.data is Map) {
        final map = response.data as Map;
        return map['data'] == true || map['isLive'] == true;
      }
      return response.data == true;
    });
  }

  Future<List<SimpleChatRoom>> getMyCustomersForChat() async {
    return executeApiCall(() async {
      final response = await apiClient.get('/api/Chat/getMyCustomersForChat');
      final data = response.data;
      if (data is List) {
        return data.map((e) => _mapToChatRoom(e)).toList();
      } else if (data is Map && data['customers'] != null) {
        final customers = data['customers'] as List;
        return customers.map((e) => _mapToChatRoom(e)).toList();
      }
      return [];
    });
  }

  Future<SimpleMessage> sendMessage({
    required String chatRoomId,
    required String content,
    String? productId,
    String? productName,
  }) async {
    final currentUserId = await TokenStorage.getUserId();
    return executeApiCall(() async {
      final payload = {
        'content': content,
        if (productId != null) 'productId': productId,
        if (productName != null) 'productName': productName,
      };
      final response = await apiClient.post(
        '/api/chat/rooms/$chatRoomId/messages',
        data: payload,
      );
      return _mapToMessage(response.data, currentUserId);
    });
  }

  Future<SimpleChatRoom> getOrCreateProductChatRoom({
    required String productId,
    required String farmerId,
    required String farmerName,
    required String productName,
  }) async {
    final currentUserId = await TokenStorage.getUserId();
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Create a chat room ID based on product and users
    final chatRoomId = '${productId}_${currentUserId}_$farmerId';

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
  }

  SimpleMessage _mapToMessage(
    Map<String, dynamic> data,
    String? currentUserId,
  ) {
    final senderId =
        data['senderId']?.toString() ?? data['userId']?.toString() ?? '';

    return SimpleMessage(
      id:
          data['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      chatRoomId: data['chatRoomId']?.toString() ?? '',
      senderId: senderId,
      senderName:
          data['senderName']?.toString() ??
          data['userName']?.toString() ??
          'Unknown',
      content: data['content']?.toString() ?? data['message']?.toString() ?? '',
      type: MessageType.text,
      status: MessageStatus.sent,
      timestamp:
          data['timestamp'] != null
              ? DateTime.parse(data['timestamp'].toString())
              : DateTime.now(),
      isFromMe: senderId == currentUserId,
      metadata: {
        if (data['productId'] != null) 'productId': data['productId'],
        if (data['productName'] != null) 'productName': data['productName'],
      },
    );
  }

  SimpleChatRoom _mapToChatRoom(Map<String, dynamic> data) {
    return SimpleChatRoom(
      id:
          data['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name:
          data['name']?.toString() ??
          data['customerName']?.toString() ??
          'Unknown',
      participantId:
          data['participantId']?.toString() ??
          data['customerId']?.toString() ??
          '',
      participantName:
          data['participantName']?.toString() ??
          data['customerName']?.toString() ??
          'Unknown',
      participantRole: data['participantRole']?.toString() ?? 'buyer',
      lastMessage: data['lastMessage']?.toString(),
      lastMessageTime:
          data['lastMessageTime'] != null
              ? DateTime.parse(data['lastMessageTime'].toString())
              : null,
      unreadCount: data['unreadCount'] ?? 0,
      isOnline: data['isOnline'] ?? false,
      createdAt:
          data['createdAt'] != null
              ? DateTime.parse(data['createdAt'].toString())
              : DateTime.now(),
      updatedAt:
          data['updatedAt'] != null
              ? DateTime.parse(data['updatedAt'].toString())
              : DateTime.now(),
      productId: data['productId']?.toString(),
      productName: data['productName']?.toString(),
    );
  }
}
