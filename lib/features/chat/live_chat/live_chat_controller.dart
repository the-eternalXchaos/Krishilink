// lib/features/chat/live_chat/live_chat_controller.dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'live_chat_api_service.dart';
import 'live_chat_model.dart';
import 'chat_services.dart';

class LiveChatController extends GetxController {
  LiveChatController({
    required this.productId,
    required this.productName,
    required this.farmerName,
    required this.emailOrPhone,
    this.receiverUserId, // when farmer opens a buyer thread
  });

  final String productId;
  final String productName;
  final String farmerName;
  final String emailOrPhone;
  final String? receiverUserId;

  final messages = <LiveChatMessage>[].obs;
  final isLoading = false.obs;
  final isSending = false.obs;
  final isOnline = false.obs;

  final inputCtrl = TextEditingController();

  String? _farmerId; // receiver for buyer flow
  String? _selectedBuyerId; // receiver for farmer flow
  String? get currentUserId => _auth.userData?.id;
  String? get authToken => _auth.userData?.token;

  late final LiveChatApiService _api;
  late final AuthController _auth;
  StreamSubscription? _sub;

  @override
  void onInit() {
    super.onInit();
    _api = LiveChatApiService(Get.isRegistered() ? Get.find<Dio>() : Dio());
    _auth =
        Get.isRegistered<AuthController>()
            ? Get.find<AuthController>()
            : Get.put(AuthController());
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    isLoading.value = true;
    try {
      // If farmer opened a buyer thread, set receiver; else buyer flow by product
      if (receiverUserId != null && receiverUserId!.isNotEmpty) {
        // Farmer opened a specific buyer thread
        _selectedBuyerId = receiverUserId;
      } else if (productId.isNotEmpty) {
        _farmerId = await _api.getFarmerIdByProductId(productId);
        isOnline.value = await _api.isFarmerLive(productId);
      }

      // realtime connect flips presence on backend
      await ChatRealtimeService.I.connect(
        tokenProvider: () async => authToken ?? '',
      );

      _sub = ChatRealtimeService.I.messages.listen((raw) {
        // raw = { senderName, message, createdAt } from ReceiveMessage
        final txt = (raw['message'] as String?) ?? '';
        final when =
            DateTime.tryParse((raw['createdAt'] as String?) ?? '') ??
            DateTime.now();
        if (txt.isEmpty) return;
        final isSystem = raw['system'] == true;
        final senderId = (raw['senderId'] as String?) ?? (isSystem ? 'system' : 'other');
        messages.add(
          LiveChatMessage(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            senderId: senderId,
            receiverId: currentUserId ?? '',
            body: isSystem ? '[SYSTEM] $txt' : txt,
            createdAt: when,
          ),
        );
      });

      // history (needs user2Id)
      final historyUserId = _selectedBuyerId ?? _farmerId;
      if (historyUserId != null && historyUserId.isNotEmpty) {
        final history = await _api.getChatHistory(historyUserId);
        history.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        messages.assignAll(history);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> send() async {
    final text = inputCtrl.text.trim();
    if (text.isEmpty) return;

    // pick receiver id depending on role/screen (buyer vs farmer)
    final receiverId = _farmerId ?? _selectedBuyerId;
    if (receiverId == null || receiverId.isEmpty) {
      debugPrint('No receiverUserId available');
      return;
    }

    isSending.value = true;
    try {
  await ChatRealtimeService.I.sendToUser(receiverId, text);

      // Optimistic echo (server may not echo to sender)
      messages.add(
        LiveChatMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          senderId: currentUserId ?? 'me',
            receiverId: receiverId,
          body: text,
          createdAt: DateTime.now(),
        ),
      );
      inputCtrl.clear();
    } finally {
      isSending.value = false;
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    inputCtrl.dispose();
    super.onClose();
  }

  // // Farmer Live Status
  final RxMap<String, bool> _farmerLiveStatus = <String, bool>{}.obs;
  // in authController
  Timer? _liveStatusTimer;

  void startFarmerLivePolling(String productId) {
    _liveStatusTimer?.cancel();
    _liveStatusTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      fetchFarmerLiveStatus(productId);
    });
  }

  void stopPolling() {
    _liveStatusTimer?.cancel();
  }

  bool isFarmerLive(String productId) => _farmerLiveStatus[productId] ?? false;
  Future<void> fetchFarmerLiveStatus(String productId) async {
    final status = await _api.isFarmerLive(productId);
    _farmerLiveStatus[productId] = status;
  }
}
