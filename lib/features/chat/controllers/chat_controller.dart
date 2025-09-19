import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_room.dart';
import '../models/message.dart';
import '../services/chat_api_service.dart';
import '../services/chat_cache_service.dart';
import '../services/signalr_service.dart';
import '../services/chat_notification_service.dart';
import '../../../features/auth/controller/auth_controller.dart';

class ChatController extends GetxController {
  final Logger _logger = Logger();
  final AuthController _authController =
      Get.isRegistered()
          ? Get.find<AuthController>()
          : Get.put(AuthController());
  final LiveChatApiService _apiService =
      Get.isRegistered()
          ? Get.find<LiveChatApiService>()
          : Get.put(LiveChatApiService(dio: Get.find<Dio>()));
  final ChatCacheService _cacheService =
      Get.isRegistered()
          ? Get.find<ChatCacheService>()
          : Get.put(ChatCacheService());
  final SignalRService _signalRService =
      Get.isRegistered()
          ? Get.find<SignalRService>()
          : Get.put(SignalRService());
  final ChatNotificationService chatNotificationService =
      Get.isRegistered()
          ? Get.find<ChatNotificationService>()
          : Get.put(ChatNotificationService());

  // Observables
  final RxList<ChatRoom> chatRooms = <ChatRoom>[].obs;
  final RxList<Message> messages = <Message>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMessages = false.obs;
  final RxBool isSendingMessage = false.obs;
  final RxString currentChatRoomId = ''.obs;
  final RxString currentChatRoomName = ''.obs;
  final RxBool isConnected = false.obs;
  final RxString connectionStatus = 'Disconnected'.obs;
  final RxString typingUser = ''.obs;
  final RxBool isTyping = false.obs;
  final RxInt totalUnreadCount = 0.obs;

  // Message input
  final RxString messageText = ''.obs;
  final Rx<Message?> replyToMessage = Rx<Message?>(null);

  // Media handling
  final RxBool isUploadingMedia = false.obs;
  final RxDouble uploadProgress = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _setupSignalRCallbacks();
    _setupConnectivityListener();
    _loadChatRoomsFromCache();
    calculateTotalUnreadCount();
  }

  void _setupSignalRCallbacks() {
    _signalRService.onMessageReceived = _handleNewMessage;
    _signalRService.onTypingChanged = _handleTypingChange;
    _signalRService.onUserOnline = _handleUserOnline;
    _signalRService.onUserOffline = _handleUserOffline;
    _signalRService.onMessageRead = _handleMessageRead;

    // Listen to connection status
    ever(_signalRService.isConnected, (connected) {
      isConnected.value = connected;
      connectionStatus.value = connected ? 'Connected' : 'Disconnected';
    });
  }

  void _setupConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        _syncPendingMessages();
        _refreshChatRooms();
      }
    });
  }

  // Chat Rooms Management
  Future<void> loadChatRooms({bool refresh = false}) async {
    try {
      isLoading.value = true;

      if (refresh) {
        // Load from API
        final apiRooms = await _apiService.getChatRooms();
        await _cacheService.saveChatRooms(apiRooms);
        chatRooms.value = apiRooms;
      } else {
        // Load from cache first, then API
        final cachedRooms = _cacheService.getAllChatRooms();
        chatRooms.value = cachedRooms;

        // Refresh from API in background
        _refreshChatRooms();
      }
    } catch (e) {
      _logger.e('Failed to load chat rooms: $e');
      // Load from cache if API fails
      final cachedRooms = _cacheService.getAllChatRooms();
      chatRooms.value = cachedRooms;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _refreshChatRooms() async {
    try {
      final apiRooms = await _apiService.getChatRooms();
      await _cacheService.saveChatRooms(apiRooms);
      chatRooms.value = apiRooms;
      calculateTotalUnreadCount();
    } catch (e) {
      _logger.e('Failed to refresh chat rooms: $e');
    }
  }

  Future<void> _loadChatRoomsFromCache() async {
    final cachedRooms = _cacheService.getAllChatRooms();
    chatRooms.value = cachedRooms;
    calculateTotalUnreadCount();
  }

  // Messages Management
  Future<void> loadMessages(String chatRoomId, {bool refresh = false}) async {
    try {
      isLoadingMessages.value = true;
      currentChatRoomId.value = chatRoomId;

      // Get chat room info
      final chatRoom = _cacheService.getChatRoom(chatRoomId);
      if (chatRoom != null) {
        currentChatRoomName.value = chatRoom.name;
      }

      if (refresh) {
        // Load from API
        final apiMessages = await _apiService.getMessages(
          chatRoomId: chatRoomId,
        );
        await _cacheService.saveMessages(apiMessages);
        messages.value = apiMessages;
      } else {
        // Load from cache first
        final cachedMessages = _cacheService.getMessages(chatRoomId);
        messages.value = cachedMessages;

        // Refresh from API in background
        _refreshMessages(chatRoomId);
      }

      // Join SignalR room
      await _signalRService.joinChatRoom(chatRoomId);

      // Mark messages as read
      await _markMessagesAsRead(chatRoomId);
    } catch (e) {
      _logger.e('Failed to load messages: $e');
      // Load from cache if API fails
      final cachedMessages = _cacheService.getMessages(chatRoomId);
      messages.value = cachedMessages;
    } finally {
      isLoadingMessages.value = false;
    }
  }

  Future<void> _refreshMessages(String chatRoomId) async {
    try {
      final apiMessages = await _apiService.getMessages(chatRoomId: chatRoomId);
      await _cacheService.saveMessages(apiMessages);
      messages.value = apiMessages;
    } catch (e) {
      _logger.e('Failed to refresh messages: $e');
    }
  }

  // Send Message
  Future<void> sendMessage({
    required String content,
    MessageType type = MessageType.text,
    String? mediaUrl,
    Map<String, dynamic>? metadata,
  }) async {
    if (content.trim().isEmpty && type == MessageType.text) return;
    if (currentChatRoomId.value.isEmpty) return;

    final tempId = const Uuid().v4();
    final currentUser = _authController.currentUser.value;
    if (currentUser == null) return;

    // Create temporary message
    final tempMessage = Message(
      id: tempId,
      chatRoomId: currentChatRoomId.value,
      senderId: currentUser.id,
      senderName: currentUser.fullName,
      content: content,
      type: type,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
      mediaUrl: mediaUrl,
      metadata: metadata,
      isFromMe: true,
      replyToMessageId: replyToMessage.value?.id,
      replyToMessageContent: replyToMessage.value?.content,
    );

    // Add to UI immediately
    messages.add(tempMessage);
    messageText.value = '';
    replyToMessage.value = null;

    try {
      isSendingMessage.value = true;

      // Try to send via SignalR first
      if (_signalRService.isConnected.value) {
        await _signalRService.sendMessage(
          chatRoomId: currentChatRoomId.value,
          content: content,
          type: type,
          mediaUrl: mediaUrl,
          replyToMessageId: replyToMessage.value?.id,
          metadata: metadata,
        );

        // Update message status
        final updatedMessage = tempMessage.copyWith(status: MessageStatus.sent);
        await _cacheService.updateMessage(updatedMessage);
        _updateMessageInList(updatedMessage);
      } else {
        // Fallback to API
        final sentMessage = await _apiService.sendMessage(
          chatRoomId: currentChatRoomId.value,
          content: content,
          type: type,
          mediaUrl: mediaUrl,
          replyToMessageId: replyToMessage.value?.id,
          metadata: metadata,
        );

        // Replace temp message with real message
        await _cacheService.saveMessage(sentMessage);
        _replaceMessageInList(tempMessage, sentMessage);
      }

      // Update chat room last message
      _updateChatRoomLastMessage(currentChatRoomId.value, content);
    } catch (e) {
      _logger.e('Failed to send message: $e');

      // Update message status to failed
      final failedMessage = tempMessage.copyWith(status: MessageStatus.failed);
      await _cacheService.updateMessage(failedMessage);
      _updateMessageInList(failedMessage);

      // Save to pending messages for retry
      await _cacheService.savePendingMessage(tempMessage);
    } finally {
      isSendingMessage.value = false;
    }
  }

  // Media Upload
  Future<String?> uploadMedia({
    required String filePath,
    required String fileName,
    required MessageType mediaType,
  }) async {
    try {
      isUploadingMedia.value = true;
      uploadProgress.value = 0.0;

      final mediaUrl = await _apiService.uploadMedia(
        filePath: filePath,
        fileName: fileName,
        mediaType: mediaType,
      );

      uploadProgress.value = 1.0;
      return mediaUrl;
    } catch (e) {
      _logger.e('Failed to upload media: $e');
      return null;
    } finally {
      isUploadingMedia.value = false;
      uploadProgress.value = 0.0;
    }
  }

  // SignalR Event Handlers
  void _handleNewMessage(Message message) {
    // Add to messages if it's for current chat room
    if (message.chatRoomId == currentChatRoomId.value) {
      messages.add(message);
      _markMessagesAsRead(message.chatRoomId);
    }

    // Save to cache
    _cacheService.saveMessage(message);

    // Update chat room last message
    _updateChatRoomLastMessage(message.chatRoomId, message.content);

    // Update unread count
    calculateTotalUnreadCount();
  }

  void _handleTypingChange(String userId, bool isTyping) {
    if (currentChatRoomId.value.isNotEmpty) {
      typingUser.value = userId;
      this.isTyping.value = isTyping;
    }
  }

  void _handleUserOnline(String userId) {
    // Update user online status in chat rooms
    final updatedRooms =
        chatRooms.map((room) {
          if (room.participantId == userId) {
            return room.copyWith(isOnline: true);
          }
          return room;
        }).toList();
    chatRooms.value = updatedRooms;
  }

  void _handleUserOffline(String userId) {
    // Update user offline status in chat rooms
    final updatedRooms =
        chatRooms.map((room) {
          if (room.participantId == userId) {
            return room.copyWith(isOnline: false);
          }
          return room;
        }).toList();
    chatRooms.value = updatedRooms;
  }

  void _handleMessageRead(String messageId) {
    // Update message status in current chat
    final updatedMessages =
        messages.map((message) {
          if (message.id == messageId) {
            return message.copyWith(status: MessageStatus.read);
          }
          return message;
        }).toList();
    messages.value = updatedMessages;
  }

  // Utility Methods
  void _updateMessageInList(Message updatedMessage) {
    final index = messages.indexWhere((m) => m.id == updatedMessage.id);
    if (index != -1) {
      messages[index] = updatedMessage;
    }
  }

  void _replaceMessageInList(Message oldMessage, Message newMessage) {
    final index = messages.indexWhere((m) => m.id == oldMessage.id);
    if (index != -1) {
      messages[index] = newMessage;
    }
  }

  void _updateChatRoomLastMessage(String chatRoomId, String lastMessage) {
    final updatedRooms =
        chatRooms.map((room) {
          if (room.id == chatRoomId) {
            return room.copyWith(
              lastMessage: lastMessage,
              lastMessageTime: DateTime.now(),
            );
          }
          return room;
        }).toList();
    chatRooms.value = updatedRooms;
  }

  Future<void> _markMessagesAsRead(String chatRoomId) async {
    try {
      await _apiService.markMessagesAsRead(chatRoomId);
      await _signalRService.markMessageAsRead(chatRoomId);
    } catch (e) {
      _logger.e('Failed to mark messages as read: $e');
    }
  }

  void calculateTotalUnreadCount() {
    int total = 0;
    for (final room in chatRooms) {
      total += room.unreadCount;
    }
    totalUnreadCount.value = total;
  }

  // Sync pending messages
  Future<void> _syncPendingMessages() async {
    try {
      final pendingMessages = _cacheService.getPendingMessages();
      for (final message in pendingMessages) {
        try {
          await sendMessage(
            content: message.content,
            type: message.type,
            mediaUrl: message.mediaUrl,
            metadata: message.metadata,
          );
          await _cacheService.removePendingMessage(
            message.chatRoomId,
            message.id,
          );
        } catch (e) {
          _logger.e('Failed to sync pending message: $e');
        }
      }
    } catch (e) {
      _logger.e('Failed to sync pending messages: $e');
    }
  }

  // Typing indicator
  void sendTypingIndicator(bool isTyping) {
    if (currentChatRoomId.value.isNotEmpty) {
      _signalRService.sendTypingIndicator(
        chatRoomId: currentChatRoomId.value,
        isTyping: isTyping,
      );
    }
  }

  // Create new chat room
  Future<ChatRoom?> createChatRoom({
    required String participantId,
    String? productId,
    String? initialMessage,
  }) async {
    try {
      final chatRoom = await _apiService.createChatRoom(
        participantId: participantId,
        productId: productId,
        initialMessage: initialMessage,
      );

      await _cacheService.saveChatRoom(chatRoom);
      chatRooms.insert(0, chatRoom);

      // Send initial message if provided
      if (initialMessage != null) {
        await sendMessage(content: initialMessage);
      }

      return chatRoom;
    } catch (e) {
      _logger.e('Failed to create chat room: $e');
      return null;
    }
  }

  // Clear current chat
  void clearCurrentChat() {
    currentChatRoomId.value = '';
    currentChatRoomName.value = '';
    messages.clear();
    messageText.value = '';
    replyToMessage.value = null;
    typingUser.value = '';
    isTyping.value = false;
  }

  // Set reply message
  void setReplyMessage(Message? message) {
    replyToMessage.value = message;
  }

  // Clear reply message
  void clearReplyMessage() {
    replyToMessage.value = null;
  }

  // FCM Integration Methods

  /// Initialize FCM for the current user
  Future<void> initializeFCM() async {
    try {
      if (_authController.currentUser.value?.id != null) {
        await chatNotificationService.subscribeToUserTopic(
          _authController.currentUser.value!.id,
        );
        _logger.i(
          'FCM initialized for user: ${_authController.currentUser.value!.id}',
        );
      }
    } catch (e) {
      _logger.e('Failed to initialize FCM: $e');
    }
  }

  /// Subscribe to chat room notifications
  Future<void> subscribeToChatRoomNotifications(String chatRoomId) async {
    try {
      await chatNotificationService.subscribeToChatRoom(chatRoomId);
      _logger.i('Subscribed to chat room notifications: $chatRoomId');
    } catch (e) {
      _logger.e('Failed to subscribe to chat room notifications: $e');
    }
  }

  /// Unsubscribe from chat room notifications
  Future<void> unsubscribeFromChatRoomNotifications(String chatRoomId) async {
    try {
      await chatNotificationService.unsubscribeFromChatRoom(chatRoomId);
      _logger.i('Unsubscribed from chat room notifications: $chatRoomId');
    } catch (e) {
      _logger.e('Failed to unsubscribe from chat room notifications: $e');
    }
  }

  /// Clear notifications for a specific chat room
  Future<void> clearChatNotifications(String chatRoomId) async {
    try {
      await chatNotificationService.clearChatNotifications(chatRoomId);
      _logger.i('Cleared notifications for chat room: $chatRoomId');
    } catch (e) {
      _logger.e('Failed to clear chat notifications: $e');
    }
  }

  /// Update FCM token when user logs in
  Future<void> updateFCMToken() async {
    try {
      await chatNotificationService.updateUserToken();
      _logger.i('FCM token updated');
    } catch (e) {
      _logger.e('Failed to update FCM token: $e');
    }
  }

  /// Handle FCM notification tap
  void handleNotificationTap(String chatRoomId) {
    try {
      final chatRoom = chatRooms.firstWhereOrNull(
        (room) => room.id == chatRoomId,
      );
      if (chatRoom != null) {
        // Navigate to chat thread
        Get.toNamed('/chat/thread', arguments: chatRoom);
      }
    } catch (e) {
      _logger.e('Failed to handle notification tap: $e');
    }
  }

  @override
  void onClose() {
    if (currentChatRoomId.value.isNotEmpty) {
      _signalRService.leaveChatRoom(currentChatRoomId.value);
    }
    super.onClose();
  }
}
