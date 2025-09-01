import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' hide Message;
import 'package:get/get.dart';
import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../controllers/chat_controller.dart';
import '../models/message.dart';
import '../models/chat_room.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';

class ChatNotificationService extends GetxService {
  final Logger _logger = Logger();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  WebSocketChannel? _channel;
  String? _deviceId;

  // Observables
  final RxBool _isInitialized = false.obs;
  bool get isInitialized => _isInitialized.value;

  @override
  void onInit() {
    super.onInit();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      await _initializeLocalNotifications();
      await _registerDevice();
      _connectWebSocket();
      _isInitialized.value = true;
      _logger.i("ChatNotificationService initialized");
    } catch (e) {
      _logger.e("Failed to initialize notification service: $e");
    }
  }

  // -------------------- Local Notifications --------------------
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (Theme.of(Get.context!).platform == TargetPlatform.android) {
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
  }

  // -------------------- Device Registration --------------------
  Future<void> _registerDevice() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Theme.of(Get.context!).platform == TargetPlatform.android) {
      final androidInfo = await deviceInfo.androidInfo;
      _deviceId = androidInfo.device;
    } else {
      final iosInfo = await deviceInfo.iosInfo;
      _deviceId = iosInfo.identifierForVendor;
    }

    final authController = Get.find<AuthController>();
    final userId = authController.currentUser.value?.id ?? '';

    if (_deviceId != null && userId.isNotEmpty) {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/Notification/registerDevice'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId, 'deviceId': _deviceId}),
      );

      if (response.statusCode == 200) {
        _logger.i("Device registered successfully with API");
      } else {
        _logger.w(
          "Device registration failed: ${response.statusCode} ${response.body}",
        );
      }
    }
  }

  // -------------------- WebSocket --------------------
  void _connectWebSocket() {
    final authController = Get.find<AuthController>();
    final userId = authController.currentUser.value?.id ?? '';
    if (userId.isEmpty) return;

    _channel = WebSocketChannel.connect(
      Uri.parse(
        '${ApiConstants.baseUrl.replaceAll("https", "wss")}/ws/chat/$userId',
      ),
    );

    _channel!.stream.listen(
      (message) {
        _logger.i("Received WebSocket message: $message");
        _handleIncomingMessage(json.decode(message));
      },
      onError: (error) => _logger.e("WebSocket error: $error"),
      onDone: () => _logger.w("WebSocket connection closed"),
    );
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    final chatController = Get.find<ChatController>();

    final newMessage = Message(
      id: data['messageId'] ?? '',
      chatRoomId: data['chatRoomId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      content: data['content'] ?? '',
      type: _parseMessageType(data['messageType'] ?? 'text'),
      status: MessageStatus.delivered,
      timestamp: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
      isFromMe: false,
    );

    // Update ChatController
    if (chatController.currentChatRoomId.value == newMessage.chatRoomId) {
      chatController.messages.add(newMessage);
    }
    chatController.calculateTotalUnreadCount();

    // Show local notification
    _showLocalNotification(newMessage);
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

  Future<void> _showLocalNotification(Message message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'chat_notifications',
          'Chat Notifications',
          channelDescription: 'Notifications for chat messages',
          importance: Importance.high,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.id.hashCode,
      message.senderName,
      message.content,
      notificationDetails,
      payload: json.encode({
        'chatRoomId': message.chatRoomId,
        'messageId': message.id,
      }),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final payload = json.decode(response.payload!);
      final chatRoomId = payload['chatRoomId'] ?? '';
      if (chatRoomId.isNotEmpty) {
        final chatController = Get.find<ChatController>();
        final chatRoom = chatController.chatRooms.firstWhereOrNull(
          (r) => r.id == chatRoomId,
        );
        if (chatRoom != null) {
          Get.toNamed('/chat/thread', arguments: chatRoom);
        }
      }
    }
  }

  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  @override
  void onClose() {
    _channel?.sink.close();
    super.onClose();
  }

  Future<void> clearChatNotifications(String chatRoomId) async {}

  Future<void> unsubscribeFromChatRoom(String chatRoomId) async {}

  Future<void> subscribeToUserTopic(String id) async {}

  Future<void> subscribeToChatRoom(String chatRoomId) async {}

  Future<void> updateUserToken() async {}
}
