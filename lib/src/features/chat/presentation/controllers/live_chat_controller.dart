// lib/src/features/chat/presentation/controllers/live_chat_controller.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/src/features/chat/data/chat_services.dart';
import 'package:krishi_link/src/features/chat/data/live_chat_api_service.dart';
import 'package:krishi_link/src/features/chat/models/live_chat_model.dart';

class LiveChatController extends GetxController {
  LiveChatController({
    required this.productId,
    required this.productName,
    required this.farmerName,
    required this.emailOrPhone,
    this.receiverUserId, // when farmer opens a buyer thread
    this.farmerId, // direct farmer ID from product object
  });

  final String productId;
  final String productName;
  final String farmerName;
  final String emailOrPhone;
  final String? farmerId; // NEW: Direct farmer ID parameter
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
    // Use ApiClient-backed service
    _api = LiveChatApiService();
    _auth =
        Get.isRegistered<AuthController>()
            ? Get.find<AuthController>()
            : Get.put(AuthController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Do not bootstrap chat in guest mode
      if (!(_auth.isLoggedIn)) {
        debugPrint('💤 Guest mode detected — skipping LiveChat bootstrap');
        return;
      }
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    try {
      isLoading.value = true;

      // Safety: avoid any network activity in guest mode
      if (!(_auth.isLoggedIn)) {
        debugPrint('💤 Guest mode — aborting chat bootstrap');
        isOnline.value = false;
        return;
      }

      if (receiverUserId != null && receiverUserId!.isNotEmpty) {
        _selectedBuyerId = receiverUserId;
        debugPrint(
          '📋 Farmer-to-buyer thread initialized for: $receiverUserId',
        );
      } else if (productId.isNotEmpty) {
        debugPrint('📋 Buyer-to-farmer flow for product: $productId');
        try {
          _farmerId = await _api.getFarmerIdByProductId(productId);
          debugPrint(
            '✅ Found farmer ID via API: $_farmerId for product: $productId',
          );
          isOnline.value = await _api.isFarmerLive(productId);
          debugPrint('📊 Farmer live status: ${isOnline.value}');
        } catch (e) {
          debugPrint('❌ Error in API farmer lookup for product $productId: $e');
          if (farmerId != null && farmerId!.isNotEmpty) {
            _farmerId = farmerId;
            debugPrint('✅ Using provided farmer ID as fallback: $_farmerId');
            try {
              isOnline.value = await _api.isFarmerLive(productId);
              debugPrint('📊 Farmer live status: ${isOnline.value}');
            } catch (e2) {
              debugPrint('❌ Error checking live status: $e2');
              isOnline.value = false;
            }
          } else {
            _farmerId = null;
            isOnline.value = false;
            Get.snackbar(
              'Connection Error',
              'Unable to connect to farmer for this product. Please try again.',
              backgroundColor: Colors.orange.withValues(alpha: 0.8),
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
            );
          }
        }
      } else {
        debugPrint('⚠️ No productId or receiverUserId provided');
      }

      // Do not auto-connect to SignalR here. Presence (Go Live) controls connection lifecycle.
      // The send() path will attempt a quick reconnect if needed.

      _sub?.cancel();
      _sub = ChatService.I.messages.listen((raw) {
        try {
          final txt = (raw['message'] as String?) ?? '';
          final when =
              DateTime.tryParse((raw['createdAt'] as String?) ?? '') ??
              DateTime.now();
          if (txt.isEmpty) return;
          final isSystem = raw['system'] == true;
          final senderId =
              (raw['senderId'] as String?) ?? (isSystem ? 'system' : 'other');
          messages.add(
            LiveChatMessage(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              senderId: senderId,
              receiverId: currentUserId ?? '',
              body: isSystem ? '[SYSTEM] $txt' : txt,
              createdAt: when,
            ),
          );
        } catch (e) {
          debugPrint('Error processing message: $e');
        }
      });

      final historyUserId = _selectedBuyerId ?? _farmerId;
      if (historyUserId != null && historyUserId.isNotEmpty) {
        try {
          final history = await _api.getChatHistory(historyUserId);
          history.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          messages.assignAll(history);
        } catch (e) {
          debugPrint('Error loading chat history: $e');
        }
      }
    } catch (e) {
      debugPrint('Error in bootstrap: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> send() async {
    final text = inputCtrl.text.trim();
    if (text.isEmpty) {
      debugPrint('⚠️ Cannot send empty message');
      return;
    }

    final receiverId = _farmerId ?? _selectedBuyerId;
    if (receiverId == null || receiverId.isEmpty) {
      debugPrint(
        '❌ No receiver ID available - farmerId: $_farmerId, selectedBuyerId: $_selectedBuyerId',
      );
      Get.snackbar(
        'Connection Error',
        'Unable to send message. Please try reconnecting.',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      if (productId.isNotEmpty && _farmerId == null) {
        debugPrint(
          '🔄 Attempting to re-fetch farmer ID for product: $productId',
        );
        try {
          _farmerId = await _api.getFarmerIdByProductId(productId);
          debugPrint('✅ Re-fetched farmer ID via API: $_farmerId');
          return send();
        } catch (e) {
          debugPrint('❌ Failed to re-fetch farmer ID via API: $e');
          if (farmerId != null && farmerId!.isNotEmpty) {
            _farmerId = farmerId;
            debugPrint('✅ Re-using provided farmer ID as fallback: $_farmerId');
            return send();
          }
        }
      }
      return;
    }

    debugPrint('📤 Sending message to $receiverId: "$text"');

    isSending.value = true;
    try {
      bool delivered = false;
      try {
        await ChatService.I.sendToUser(receiverId, text);
        delivered = true;
      } catch (_) {}

      if (!delivered) {
        try {
          delivered = await _api.sendMessage(receiverId, text);
        } catch (_) {
          delivered = false;
        }
      }

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

  bool get isValidConnection {
    final receiverId = _farmerId ?? _selectedBuyerId;
    return receiverId != null && receiverId.isNotEmpty;
  }

  String get connectionStatus {
    if (_farmerId != null) return 'Connected to farmer';
    if (_selectedBuyerId != null) return 'Connected to buyer';
    return 'No connection established';
  }

  Future<bool> validateConnection() async {
    if (isValidConnection) return true;
    if (productId.isNotEmpty && _farmerId == null) {
      debugPrint('🔄 Validating connection for product: $productId');
      try {
        _farmerId = await _api.getFarmerIdByProductId(productId);
        isOnline.value = await _api.isFarmerLive(productId);
        debugPrint(
          '✅ Connection validated via API - Farmer: $_farmerId, Online: ${isOnline.value}',
        );
        return true;
      } catch (e) {
        debugPrint('❌ Connection validation via API failed: $e');
        if (farmerId != null && farmerId!.isNotEmpty) {
          _farmerId = farmerId;
          debugPrint(
            '✅ Connection validated using provided farmer ID: $_farmerId',
          );
          try {
            isOnline.value = await _api.isFarmerLive(productId);
            debugPrint('📊 Farmer online status: ${isOnline.value}');
          } catch (e2) {
            debugPrint('❌ Error checking farmer live status: $e2');
            isOnline.value = false;
          }
          return true;
        }
        return false;
      }
    }
    return false;
  }

  final RxMap<String, bool> _farmerLiveStatus = <String, bool>{}.obs;
  Timer? _liveStatusTimer;
  final Map<String, Future<bool>> _inFlightLiveChecks = {};

  void startFarmerLivePolling(String productId) {
    // Do not poll when not authenticated
    if (!(_auth.isLoggedIn)) {
      return;
    }
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
    // Avoid network calls in guest mode
    if (!(_auth.isLoggedIn)) {
      _farmerLiveStatus[productId] = false;
      return;
    }
    if (_inFlightLiveChecks[productId] != null) {
      try {
        final existing = await _inFlightLiveChecks[productId]!;
        _farmerLiveStatus[productId] = existing;
      } finally {}
      return;
    }

    final future = _api.isFarmerLive(productId);
    _inFlightLiveChecks[productId] = future;
    try {
      final status = await future;
      _farmerLiveStatus[productId] = status;
    } finally {
      _inFlightLiveChecks.remove(productId);
    }
  }
}
