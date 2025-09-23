import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/src/features/chat/data/chat_services.dart';
import 'package:krishi_link/src/features/chat/data/live_chat_api_service.dart';
import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/src/features/auth/data/token_service.dart';

class ProductChatController extends GetxController {
  final String productId;
  final String productName;
  ProductChatController({required this.productId, required this.productName});

  final messages = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;
  final isSendingMessage = false.obs;
  final isFarmerLive = false.obs;
  final messageText = ''.obs;
  final inputCtrl = TextEditingController();
  String? farmerId;
  StreamSubscription? _sub;

  @override
  void onInit() {
    super.onInit();
    _connectToRealtimeChat();
  }

  Future<void> _connectToRealtimeChat() async {
    try {
      isLoading.value = true;
      final chatApi = LiveChatApiService();
      // If unauthenticated, avoid any network that requires a token; only allow guest-safe reads handled by service
      if (!(await TokenService.hasTokens())) {
        // Try only guest-safe calls
        try {
          farmerId = await chatApi.getFarmerIdByProductId(productId);
          isFarmerLive.value = await chatApi.isFarmerLive(productId);
        } catch (_) {}
        // Do not proceed to realtime or history in guest mode
        isLoading.value = false;
        return;
      }

      farmerId = await chatApi.getFarmerIdByProductId(productId);
      debugPrint('🌐 Farmer ID: $farmerId');
      if (farmerId == null || farmerId!.isEmpty) {
        throw Exception('No farmer ID found for product $productId');
      }

      isFarmerLive.value = await chatApi.isFarmerLive(productId);
      debugPrint('🌐 Farmer online: ${isFarmerLive.value}');

      final token = await TokenService.getAccessToken();
      if (token == null || token.isEmpty) {
        debugPrint('❌ No valid token');
        Get.snackbar(
          'Error',
          'Authentication failed',
          backgroundColor: Colors.red.withValues(alpha: 0.1),
        );
        return;
      }

      final ok = await ChatService.I.connect(
        hubUrl: '${ApiConstants.baseUrl}/ChatHub',
        verbose: true,
      );

      if (!ok) {
        debugPrint('❌ SignalR connection failed');
        Get.snackbar(
          'Error',
          'Failed to connect to chat',
          backgroundColor: Colors.red.withValues(alpha: 0.1),
        );
        return;
      }

      debugPrint('💡 Successfully connected to real-time chat service');

      _sub?.cancel();
      _sub = ChatService.I.messages.listen((msg) {
        debugPrint('📨 Received: $msg');
        messages.add(msg);
      });

      final history = await chatApi.getChatHistory(farmerId!);
      messages.assignAll(
        history
            .map(
              (m) => {
                'senderId': m.senderId,
                'senderName': m.senderId == farmerId ? 'Farmer' : 'You',
                'message': m.body,
                'createdAt': m.createdAt.toIso8601String(),
                'status': 'sent',
              },
            )
            .toList(),
      );
      debugPrint('📜 Loaded ${history.length} history messages');
    } catch (e) {
      debugPrint('❌ Connection error: $e');
      Get.snackbar(
        'Error',
        'Failed to initialize chat',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || farmerId == null || farmerId!.isEmpty) {
      debugPrint('❌ Invalid input or no farmer ID');
      return;
    }

    isSendingMessage.value = true;
    final tempMessage = {
      'senderId': 'me',
      'senderName': 'You',
      'message': text,
      'createdAt': DateTime.now().toIso8601String(),
      'status': 'sending',
    };
    messages.add(tempMessage);

    try {
      if (!ChatService.I.isConnected) {
        debugPrint('🔌 Connection not stable, reconnecting');
        final token = await TokenService.getAccessToken();
        if (token == null || token.isEmpty) {
          throw Exception('No valid token');
        }
        final ok = await ChatService.I.connect(
          hubUrl: '${ApiConstants.baseUrl}/ChatHub',
          verbose: true,
        );
        if (!ok) {
          throw Exception('Failed to reconnect');
        }
      }

      await ChatService.I.sendToUser(farmerId!, text);
      final index = messages.indexWhere(
        (m) => m['createdAt'] == tempMessage['createdAt'],
      );
      if (index != -1) {
        messages[index] = {...tempMessage, 'status': 'sent'};
        messages.refresh();
      }
      inputCtrl.clear();
      messageText.value = '';
      debugPrint('✅ Message sent to $farmerId');
    } catch (e) {
      debugPrint('⛔ Failed to send message: $e');
      final index = messages.indexWhere(
        (m) => m['createdAt'] == tempMessage['createdAt'],
      );
      if (index != -1) {
        messages[index] = {...tempMessage, 'status': 'failed'};
        messages.refresh();
      }
      try {
        final delivered = await LiveChatApiService().sendMessage(
          farmerId!,
          text,
        );
        if (delivered) {
          if (index != -1) {
            messages[index] = {...tempMessage, 'status': 'sent'};
            messages.refresh();
          }
          inputCtrl.clear();
          messageText.value = '';
          debugPrint('✅ Sent via REST fallback');
        } else {
          throw Exception('REST send failed');
        }
      } catch (restE) {
        debugPrint('❌ REST fallback failed: $restE');
        Get.snackbar(
          'Error',
          'Failed to send message',
          backgroundColor: Colors.red.withValues(alpha: 0.1),
        );
      }
    } finally {
      isSendingMessage.value = false;
    }
  }

  Future<void> retryMessage(Map<String, dynamic> failedMessage) async {
    if (failedMessage['status'] != 'failed') return;

    final index = messages.indexWhere(
      (m) => m['createdAt'] == failedMessage['createdAt'],
    );
    if (index != -1) {
      messages[index] = {...failedMessage, 'status': 'sending'};
      messages.refresh();
    }

    try {
      await sendMessage(failedMessage['message']);
    } catch (e) {
      if (index != -1) {
        messages[index] = {...failedMessage, 'status': 'failed'};
        messages.refresh();
      }
      debugPrint('❌ Retry failed: $e');
    }
  }

  Future<void> checkFarmerLiveStatus() async {
    try {
      final isLive = await LiveChatApiService().isFarmerLive(productId);
      isFarmerLive.value = isLive;
      debugPrint('🌐 Farmer live status: $isLive');
    } catch (e) {
      debugPrint('❌ Failed to check farmer live status: $e');
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    inputCtrl.dispose();
    super.onClose();
  }
}
