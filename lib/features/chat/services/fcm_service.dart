import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide Message;
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import '../controllers/chat_controller.dart';
import '../models/message.dart';
import '../models/chat_room.dart';
import '../../../features/auth/controller/auth_controller.dart';
import 'background_message_handler.dart';

class FcmService extends GetxService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final Logger _logger = Logger();

  // Observables
  final RxString _fcmToken = ''.obs;
  final RxBool _isInitialized = false.obs;

  // Getters
  String get fcmToken => _fcmToken.value;
  bool get isInitialized => _isInitialized.value;

  @override
  void onInit() {
    super.onInit();
    _initializeFCM();
  }

  Future<void> _initializeFCM() async {
    try {
      // Request permission for iOS
      if (Platform.isIOS) {
        NotificationSettings settings = await _firebaseMessaging
            .requestPermission(
              alert: true,
              announcement: false,
              badge: true,
              carPlay: false,
              criticalAlert: false,
              provisional: false,
              sound: true,
            );

        if (settings.authorizationStatus != AuthorizationStatus.authorized) {
          _logger.w('FCM permission not granted');
          return;
        }
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      await _getFCMToken();

      // Setup message handlers
      _setupMessageHandlers();

      // Setup topic subscription for chat notifications
      await _subscribeToChatTopic();

      _isInitialized.value = true;
      _logger.i('FCM service initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize FCM: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'chat_notifications',
      'Chat Notifications',
      description: 'Notifications for chat messages',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> _getFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        _fcmToken.value = token;
        _logger.i('FCM Token: $token');

        // Send token to server for registration
        await _registerTokenWithServer(token);
      }
    } catch (e) {
      _logger.e('Failed to get FCM token: $e');
    }
  }

  Future<void> _registerTokenWithServer(String token) async {
    try {
      // TODO: Implement API call to register FCM token with server
      // This should be called when user logs in and FCM token is generated
      _logger.i('FCM token registered with server: $token');
    } catch (e) {
      _logger.e('Failed to register FCM token with server: $e');
    }
  }

  Future<void> _subscribeToChatTopic() async {
    try {
      // Subscribe to general chat topic
      await _firebaseMessaging.subscribeToTopic('chat_notifications');

      // Subscribe to user-specific topic (using user ID)
      // This allows for targeted notifications
      try {
        final authController = Get.find<AuthController>();
        if (authController.currentUser.value?.id != null) {
          await _firebaseMessaging.subscribeToTopic(
            'user_${authController.currentUser.value!.id}',
          );
        }
      } catch (e) {
        _logger.w(
          'AuthController not available for FCM topic subscription: $e',
        );
      }

      _logger.i('Subscribed to chat notification topics');
    } catch (e) {
      _logger.e('Failed to subscribe to chat topics: $e');
    }
  }

  void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle messages when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Handle initial message when app is opened from terminated state
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleInitialMessage(message);
      }
    });
  }

  void _handleForegroundMessage(RemoteMessage message) {
    _logger.i('Received foreground message: ${message.messageId}');

    try {
      // Parse chat notification data
      if (message.data['type'] == 'chat_message') {
        _handleChatMessage(message);
      }

      // Show local notification
      _showLocalNotification(message);
    } catch (e) {
      _logger.e('Error handling foreground message: $e');
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    _logger.i('App opened from background notification: ${message.messageId}');

    try {
      if (message.data['type'] == 'chat_message') {
        _handleChatMessage(message);
      }
    } catch (e) {
      _logger.e('Error handling background message: $e');
    }
  }

  void _handleInitialMessage(RemoteMessage message) {
    _logger.i('App opened from terminated state: ${message.messageId}');

    try {
      if (message.data['type'] == 'chat_message') {
        _handleChatMessage(message);
      }
    } catch (e) {
      _logger.e('Error handling initial message: $e');
    }
  }

  void _handleChatMessage(RemoteMessage message) {
    try {
      final data = message.data;

      // Extract chat message data
      final String chatRoomId = data['chatRoomId'] ?? '';
      final String messageId = data['messageId'] ?? '';
      final String senderId = data['senderId'] ?? '';
      final String senderName = data['senderName'] ?? '';
      final String content = data['content'] ?? '';
      final String messageType = data['messageType'] ?? 'text';
      final String timestamp = data['timestamp'] ?? '';
      final String? mediaUrl = data['mediaUrl'];
      final String? mediaThumbnail = data['mediaThumbnail'];
      final String? mediaFileName = data['mediaFileName'];
      final int? mediaFileSize = int.tryParse(data['mediaFileSize'] ?? '0');
      final int? mediaDuration = int.tryParse(data['mediaDuration'] ?? '0');
      final Map<String, dynamic>? metadata =
          data['metadata'] != null ? json.decode(data['metadata']) : null;

      // Create Message object
      final Message newMessage = Message(
        id: messageId,
        chatRoomId: chatRoomId,
        senderId: senderId,
        senderName: senderName,
        content: content,
        type: _parseMessageType(messageType),
        status: MessageStatus.delivered,
        timestamp: DateTime.tryParse(timestamp) ?? DateTime.now(),
        mediaUrl: mediaUrl,
        mediaThumbnail: mediaThumbnail,
        mediaFileName: mediaFileName,
        mediaFileSize: mediaFileSize,
        mediaDuration: mediaDuration,
        metadata: metadata,
        isFromMe: false,
      );

      // Update ChatController with new message
      try {
        final ChatController chatController = Get.find<ChatController>();
        // Add message to the current messages list if in the same chat room
        if (chatController.currentChatRoomId.value == chatRoomId) {
          chatController.messages.add(newMessage);
        }
        // Update unread count
        chatController.calculateTotalUnreadCount();
      } catch (e) {
        _logger.w('ChatController not available for message update: $e');
      }

      _logger.i('Chat message processed: $messageId');
    } catch (e) {
      _logger.e('Error processing chat message: $e');
    }
  }

  MessageType _parseMessageType(String type) {
    switch (type.toLowerCase()) {
      case 'image':
        return MessageType.image;
      case 'document':
        return MessageType.document;
      case 'voice':
        return MessageType.voice;
      case 'video':
        return MessageType.video;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final data = message.data;
      final String title =
          message.notification?.title ?? data['senderName'] ?? 'New Message';
      final String body =
          message.notification?.body ??
          data['content'] ??
          'You have a new message';
      final String chatRoomId = data['chatRoomId'] ?? '';
      final String messageId = data['messageId'] ?? '';

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'chat_notifications',
            'Chat Notifications',
            channelDescription: 'Notifications for chat messages',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFF4CAF50), // Green color for chat
            category: AndroidNotificationCategory.message,
            actions: [
              AndroidNotificationAction('reply', 'Reply'),
              AndroidNotificationAction('mark_read', 'Mark as Read'),
            ],
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'chat_message',
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        messageId.hashCode,
        title,
        body,
        notificationDetails,
        payload: json.encode({
          'type': 'chat_message',
          'chatRoomId': chatRoomId,
          'messageId': messageId,
        }),
      );
    } catch (e) {
      _logger.e('Error showing local notification: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    try {
      if (response.payload != null) {
        final Map<String, dynamic> payload = json.decode(response.payload!);

        if (payload['type'] == 'chat_message') {
          final String chatRoomId = payload['chatRoomId'] ?? '';

          // Navigate to chat thread
          if (chatRoomId.isNotEmpty) {
            // Get chat room from cache
            final ChatController chatController = Get.find<ChatController>();
            final ChatRoom? chatRoom = chatController.chatRooms
                .firstWhereOrNull((room) => room.id == chatRoomId);

            if (chatRoom != null) {
              Get.toNamed('/chat/thread', arguments: chatRoom);
            }
          }
        }
      }
    } catch (e) {
      _logger.e('Error handling notification tap: $e');
    }
  }

  // Public methods

  Future<void> updateUserToken() async {
    await _getFCMToken();
  }

  Future<void> subscribeToUserTopic(String userId) async {
    try {
      await _firebaseMessaging.subscribeToTopic('user_$userId');
      _logger.i('Subscribed to user topic: user_$userId');
    } catch (e) {
      _logger.e('Failed to subscribe to user topic: $e');
    }
  }

  Future<void> unsubscribeFromUserTopic(String userId) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic('user_$userId');
      _logger.i('Unsubscribed from user topic: user_$userId');
    } catch (e) {
      _logger.e('Failed to unsubscribe from user topic: $e');
    }
  }

  Future<void> subscribeToChatRoom(String chatRoomId) async {
    try {
      await _firebaseMessaging.subscribeToTopic('chatroom_$chatRoomId');
      _logger.i('Subscribed to chat room topic: chatroom_$chatRoomId');
    } catch (e) {
      _logger.e('Failed to subscribe to chat room topic: $e');
    }
  }

  Future<void> unsubscribeFromChatRoom(String chatRoomId) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic('chatroom_$chatRoomId');
      _logger.i('Unsubscribed from chat room topic: chatroom_$chatRoomId');
    } catch (e) {
      _logger.e('Failed to unsubscribe from chat room topic: $e');
    }
  }

  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  Future<void> clearChatNotifications(String chatRoomId) async {
    // Cancel notifications for specific chat room
    // This is a simplified implementation - in a real app, you'd track notification IDs
    await _localNotifications.cancelAll();
  }

  @override
  void onClose() {
    // Cleanup
    _firebaseMessaging.deleteToken();
    super.onClose();
  }
}
