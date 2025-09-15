import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import '../models/simple_chat_room.dart';
import '../models/simple_message.dart';
import '../services/product_chat_api_service.dart';
import 'package:krishi_link/src/features/chat/data/chat_realtime_service.dart';
import '../../../features/auth/controller/auth_controller.dart';

class ProductChatController extends GetxController {
  final Logger _logger = Logger();
  final AuthController _authController = Get.find<AuthController>();
  final ProductChatApiService _apiService = ProductChatApiService();
  final ChatRealtimeService _realtimeService = ChatRealtimeService();

  // Observables
  final RxList<SimpleMessage> messages = <SimpleMessage>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSendingMessage = false.obs;
  final RxBool isFarmerLive = false.obs;
  final RxString currentChatRoomId = ''.obs;
  final RxString currentFarmerId = ''.obs;
  final RxString currentFarmerName = ''.obs;
  final RxString currentProductId = ''.obs;
  final RxString currentProductName = ''.obs;

  StreamSubscription<Map<String, dynamic>>? _messageSubscription;

  // Message input
  final RxString messageText = ''.obs;

  /// Initialize chat for a product
  Future<bool> initializeChatForProduct({
    required String productId,
    required String productName,
    required String farmerName,
    required String emailOrPhone,
  }) async {
    try {
      isLoading.value = true;
      currentProductId.value = productId;
      currentProductName.value = productName;
      currentFarmerName.value = farmerName;

      // Get farmer ID by product ID
      final farmerId = await _apiService.getFarmerIdByProductId(productId);
      currentFarmerId.value = farmerId;

      // Check if farmer is live
      final isLive = await _apiService.isFarmerLive(productId);
      isFarmerLive.value = isLive;

      // Create or get chat room
      final chatRoom = await _apiService.getOrCreateProductChatRoom(
        productId: productId,
        farmerId: farmerId,
        farmerName: farmerName,
        productName: productName,
      );
      currentChatRoomId.value = chatRoom.id;

      // Load existing chat history
      await loadChatHistory();

      // Connect to real-time service for live updates
      _connectToRealtimeChat();

      return true;
    } catch (e) {
      _logger.e('Failed to initialize chat for product: $e');
      Get.snackbar(
        'Error',
        'Failed to initialize chat: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  SimpleMessage _mapDataToMessage(Map<String, dynamic> data) {
    final currentUser = _authController.currentUser.value;
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
      isFromMe: senderId == currentUser?.id,
      metadata: {
        if (data['productId'] != null) 'productId': data['productId'],
        if (data['productName'] != null) 'productName': data['productName'],
      },
    );
  }

  void _connectToRealtimeChat() {
    final chatRoomId = currentChatRoomId.value;
    if (chatRoomId.isEmpty) {
      _logger.w('Cannot connect to real-time chat. Missing chatRoomId.');
      return;
    }

    _realtimeService
        .connect()
        .then((connected) {
          if (!connected) {
            _logger.e('Failed to connect to realtime chat service');
            return;
          }
          _messageSubscription?.cancel();
          _messageSubscription = _realtimeService.messages.listen((data) {
            final message = _mapDataToMessage(data);
            if (!messages.any((m) => m.id == message.id)) messages.add(message);
          });
        })
        .catchError((error) {
          _logger.e('Failed to connect to real-time chat service: $error');
          Get.snackbar(
            'Connection Error',
            'Could not connect to chat service.',
          );
        });
  }

  /// Load chat history with the farmer
  Future<void> loadChatHistory() async {
    if (currentFarmerId.value.isEmpty) return;

    try {
      final chatHistory = await _apiService.getChatHistory(
        currentFarmerId.value,
      );
      messages.value = chatHistory;
    } catch (e) {
      _logger.w('Failed to load chat history: $e');
      // Don't show error for chat history as it might be empty
    }
  }

  /// Send message to farmer
  Future<void> sendMessage() async {
    final content = messageText.value.trim();
    if (content.isEmpty || currentFarmerId.value.isEmpty) return;

    final currentUser = _authController.currentUser.value;
    if (currentUser == null) {
      Get.snackbar(
        'Error',
        'Please login to send messages',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Create temporary message for immediate UI update
    final tempMessage = SimpleMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatRoomId: currentChatRoomId.value,
      senderId: currentUser.id,
      senderName: currentUser.fullName,
      content: content,
      type: MessageType.text,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
      isFromMe: true,
      metadata: {
        'productId': currentProductId.value,
        'productName': currentProductName.value,
      },
    );

    // Add to UI immediately
    messages.add(tempMessage);
    messageText.value = '';

    isSendingMessage.value = true;
    try {
      // Send message via API
      // The backend should then broadcast this message via WebSocket to all participants,
      // including the sender. Your `onMessageReceived` callback will handle it.
      final sentMessage = await _apiService.sendMessage(
        chatRoomId: currentChatRoomId.value,
        content: content,
        productId: currentProductId.value,
        productName: currentProductName.value,
      );

      // Once the API confirms the message is sent, we can update the local
      // temporary message to a 'sent' status. The WebSocket will later update it
      // with the final version from the server if needed.
      final index = messages.indexWhere((m) => m.id == tempMessage.id);
      if (index != -1) {
        messages[index] = sentMessage.copyWith(
          status: MessageStatus.sent,
          isFromMe: true,
        );
        messages.refresh();
      }
    } on DioException catch (e) {
      _logger.e('Failed to send message: $e');

      // Update message status to failed
      final index = messages.indexWhere((m) => m.id == tempMessage.id);
      if (index != -1) {
        messages[index] = tempMessage.copyWith(status: MessageStatus.failed);
      }
      Get.snackbar(
        'Error',
        'Failed to send message. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      _logger.e('An unexpected error occurred while sending message: $e');
    } finally {
      isSendingMessage.value = false;
    }
  }

  /// Retry sending failed message
  Future<void> retryMessage(SimpleMessage failedMessage) async {
    if (failedMessage.status != MessageStatus.failed) return;

    try {
      // Update message status to sending
      final index = messages.indexWhere((m) => m.id == failedMessage.id);
      if (index != -1) {
        messages[index] = failedMessage.copyWith(status: MessageStatus.sending);
      }

      // Retry sending
      final sentMessage = await _apiService.sendMessage(
        chatRoomId: currentChatRoomId.value,
        content: failedMessage.content,
        productId: failedMessage.metadata?['productId'] as String?,
        productName: failedMessage.metadata?['productName'] as String?,
      );

      // Update with sent message
      if (index != -1) {
        messages[index] = sentMessage.copyWith(
          status: MessageStatus.sent,
          isFromMe: true,
        );
      }
    } catch (e) {
      _logger.e('Failed to retry message: $e');

      // Revert to failed status
      final index = messages.indexWhere((m) => m.id == failedMessage.id);
      if (index != -1) {
        messages[index] = failedMessage.copyWith(status: MessageStatus.failed);
      }
    }
  }

  /// Check farmer live status
  Future<void> checkFarmerLiveStatus() async {
    if (currentProductId.value.isEmpty) return;

    try {
      final isLive = await _apiService.isFarmerLive(currentProductId.value);
      isFarmerLive.value = isLive;
    } catch (e) {
      _logger.e('Failed to check farmer live status: $e');
    }
  }

  /// Clear current chat
  void clearChat() {
    messages.clear();
    messageText.value = '';
    currentChatRoomId.value = '';
    currentFarmerId.value = '';
    currentFarmerName.value = '';
    currentProductId.value = '';
    currentProductName.value = '';
    isFarmerLive.value = false;
  }

  /// Get chat room info
  SimpleChatRoom? getCurrentChatRoom() {
    if (currentChatRoomId.value.isEmpty) return null;

    return SimpleChatRoom(
      id: currentChatRoomId.value,
      name: currentFarmerName.value,
      participantId: currentFarmerId.value,
      participantName: currentFarmerName.value,
      participantRole: 'farmer',
      productId: currentProductId.value,
      productName: currentProductName.value,
      isOnline: isFarmerLive.value,
      lastMessage: messages.isNotEmpty ? messages.last.content : null,
      lastMessageTime: messages.isNotEmpty ? messages.last.timestamp : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  void onClose() {
    _messageSubscription?.cancel();
    clearChat();
    super.onClose();
  }
}
