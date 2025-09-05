// lib/features/live_chat/live_chat_api_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/services/api_services/api_service.dart';
import 'live_chat_model.dart';

class LiveChatApiService {
  LiveChatApiService(Dio dio) : _dio = dio;
  final Dio _dio;

  // GET /api/Chat/getFarmerIdByProductId/{productId}
  Future<String?> getFarmerIdByProductId(String productId) async {
    try {
      final res = await _dio.get(
        '${ApiConstants.getFarmerIdByProductIdEndpoint}/$productId',
        // Use default interceptors to attach auth; do not force guest access here
        options: Options(headers: {'accept': '*/*'}),
      );
      if (res.statusCode == 200) {
        final data = res.data;
        return (data is Map<String, dynamic>)
            ? (data['data']?.toString())
            : null;
      }
    } catch (e) {
      debugPrint('❌ getFarmerIdByProductId error: $e');
    }
    return null;
  }

  // GET /api/Chat/IsFarmerLive/{productId}
  Future<bool> isFarmerLive(String productId) async {
    try {
      final res = await _dio.get(
        '${ApiConstants.isFarmerLiveEndpoint}/$productId',
        options: Options(
          headers: {'accept': '*/*'},
          extra: {'guestAccess': true},
        ),
      );
      if (res.statusCode == 200) {
        final data = res.data;
        if (data is Map<String, dynamic>) return data['data'] == true;
      }
    } catch (e) {
      debugPrint('❌ isFarmerLive error: $e');
    }
    return false;
  }

  // GET /api/Chat/getChatHistory/{user2Id}
  Future<List<LiveChatMessage>> getChatHistory(String user2Id) async {
    try {
      final res = await _dio.get(
        '${ApiConstants.getChatHistoryEndpoint}/$user2Id',
        options: Options(headers: {'accept': '*/*'}),
      );
      if (res.statusCode == 200) {
        final data = res.data;
        if (data is Map<String, dynamic>) {
          final list = (data['data'] as List?) ?? const [];
          return list
              .map((e) => LiveChatMessage.fromMap(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('❌ getChatHistory error: $e');
    }
    return const [];
  }

  // POST /api/Chat/sendMessage/{user2Id}
  // Backend may expect a different field than "message"—adjust here easily.
  Future<bool> sendMessage(String user2Id, String text) async {
    try {
      final res = await _dio.post(
        '${ApiConstants.sendMessageEndpoint}/$user2Id',
        data: {'message': text},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if (res.statusCode == 200) {
        final data = res.data;
        return (data is Map<String, dynamic>) ? (data['data'] == true) : true;
      }
    } catch (e) {
      debugPrint('❌ sendMessage error: $e');
    }
    return false;
  }

  // GET /api/Chat/getMyCustomersForChat
  Future<List<ChatPartner>> getMyCustomersForChat() async {
    Future<List<ChatPartner>> _parse(Response res) async {
      if (res.statusCode == 200) {
        final data = res.data;
        if (data is Map<String, dynamic>) {
          final list = (data['data'] as List?) ?? const [];
          return list
              .map((e) => ChatPartner.fromMap(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
      return const [];
    }

    try {
      // Primary endpoint from ApiConstants
      final res = await _dio.get(
        ApiConstants.getMyCustomersForChatEndpoint,
        options: Options(headers: {'accept': '*/*'}),
      );
      final parsed = await _parse(res);
      if (parsed.isNotEmpty || res.statusCode == 200) return parsed;
      // If not 200, fall through to attempt alternates
    } on DioException catch (e) {
      // Fallbacks for older routes or casing differences
      if (e.response?.statusCode != 404) {
        debugPrint('❌ getMyCustomersForChat error: $e');
        return const [];
      }
      debugPrint('ℹ️ getMyCustomersForChat 404 on primary, trying alternates');
    } catch (e) {
      debugPrint('❌ getMyCustomersForChat unexpected error: $e');
      return const [];
    }

    // Try common alternate route names (server is usually case-insensitive, but path may differ)
    final alternates = <String>[
      '/api/Chat/GetMyCustomersForChat',
      '/api/Chat/getMyCustomers',
      '/api/Chat/GetMyCustomers',
    ];
    for (final path in alternates) {
      try {
        final res = await _dio.get(
          path,
          options: Options(headers: {'accept': '*/*'}),
        );
        final parsed = await _parse(res);
        if (parsed.isNotEmpty || res.statusCode == 200) {
          debugPrint('✅ getMyCustomersForChat succeeded via alternate: $path');
          return parsed;
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          debugPrint('↪️ Alternate not found: $path');
          continue;
        }
        debugPrint('❌ Alternate request failed for $path: $e');
        return const [];
      } catch (e) {
        debugPrint('❌ Alternate request error for $path: $e');
        return const [];
      }
    }
    return const [];
  }
}
