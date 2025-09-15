import 'package:dio/dio.dart' show Options;
import 'package:krishi_link/src/core/networking/base_service.dart';
import 'package:krishi_link/src/features/chat/models/live_chat_model.dart';
import 'package:krishi_link/services/token_service.dart';

class LiveChatApiService extends BaseService {
  Future<List<Map<String, dynamic>>> getMyCustomersForChat() async {
    return executeApiCall(() async {
      final response = await apiClient.get('/api/Chat/getMyCustomersForChat');
      final data = response.data;
      if (data is! Map<String, dynamic> || !data['success']) {
        throw Exception(data['message'] ?? 'Failed to fetch customers');
      }
      final customers =
          (data['data'] as List<dynamic>? ?? []).map((item) {
            final map = item as Map<String, dynamic>;
            return {
              'id': map['id']?.toString() ?? '',
              'name': map['displayName']?.toString() ?? 'Unknown',
              'contact': map['contact']?.toString() ?? '',
            };
          }).toList();
      return customers;
    });
  }

  Future<bool> sendMessage(String receiverId, String message) async {
    return executeApiCall(() async {
      // Require auth for sending messages
      final hasAuth = await TokenService.hasTokens();
      if (!hasAuth) return false;
      final response = await apiClient.post(
        '/api/Chat/SendMessage',
        data: {'receiverId': receiverId, 'message': message},
      );
      return response.statusCode == 200 && response.data['success'] == true;
    });
  }

  Future<bool> isFarmerLive(String productId) async {
    return executeApiCall(() async {
      if (productId.isEmpty) {
        return false;
      }
      // Allow this check for guests without forcing auth/refresh
      final response = await apiClient.get(
        '/api/Chat/IsFarmerLive/$productId',
        options: Options(extra: {'guestAccess': true}),
      );
      if (response.statusCode != 200 || response.data == null) {
        return false;
      }
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('success') && data['success'] == false) {
          return false;
        }
        return data['data'] == true;
      } else if (response.data is bool) {
        return response.data as bool;
      }
      return false;
    });
  }

  Future<String> getFarmerIdByProductId(String productId) async {
    return executeApiCall(() async {
      if (productId.isEmpty) {
        throw Exception('Product ID cannot be empty');
      }
      // Allow lookup for guests without triggering token refresh/logout
      final response = await apiClient.get(
        '/api/Chat/getFarmerIdByProductId/$productId',
        options: Options(extra: {'guestAccess': true}),
      );
      if (response.statusCode != 200 || response.data == null) {
        throw Exception('No response data received');
      }
      String farmerId = '';
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('success') && data['success'] == false) {
          throw Exception(data['message'] ?? 'Failed to get farmer ID');
        }
        farmerId = data['data']?.toString() ?? '';
      } else if (response.data is String) {
        farmerId = response.data as String;
      } else {
        farmerId = response.data?.toString() ?? '';
      }
      if (farmerId.isEmpty) {
        throw Exception('No farmer found for this product');
      }
      return farmerId;
    });
  }

  Future<List<LiveChatMessage>> getChatHistory(String userId) async {
    return executeApiCall(() async {
      // Only fetch history when authenticated
      final hasAuth = await TokenService.hasTokens();
      if (!hasAuth) return <LiveChatMessage>[];
      final response = await apiClient.get('/api/Chat/getChatHistory/$userId');
      final data = response.data['data'] as List<dynamic>? ?? [];
      return data.map((item) {
        final map = item as Map<String, dynamic>;
        return LiveChatMessage(
          id: map['id']?.toString() ?? '',
          senderId: map['senderId']?.toString() ?? '',
          receiverId: map['receiverId']?.toString() ?? '',
          body: map['message']?.toString() ?? '',
          createdAt:
              DateTime.tryParse(map['timeStamp']?.toString() ?? '') ??
              DateTime.now(),
        );
      }).toList();
    });
  }
}
