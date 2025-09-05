import 'package:signalr_netcore/signalr_client.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import '../models/message.dart';
import '../models/chat_room.dart';
import '../../../features/auth/controller/auth_controller.dart';
import '../../../core/utils/api_constants.dart';

class SignalRService extends GetxService {
  static const String _hubUrl = '/ChatHub';

  late HubConnection _hubConnection;
  final Logger _logger = Logger();
  final AuthController _authController = Get.find<AuthController>();

  // Observables for real-time updates
  final RxList<Message> newMessages = <Message>[].obs;
  final RxString typingUser = ''.obs;
  final RxBool isTyping = false.obs;
  final RxBool isConnected = false.obs;
  final RxString connectionStatus = 'Disconnected'.obs;

  // Callbacks for UI updates
  Function(Message)? onMessageReceived;
  Function(String, bool)? onTypingChanged;
  Function(String)? onUserOnline;
  Function(String)? onUserOffline;
  Function(String)? onMessageRead;

  @override
  void onInit() {
    super.onInit();
    _initializeConnection();
  }

  Future<void> _initializeConnection() async {
    try {
      final token = _authController.currentUser.value?.token;
      if (token == null || token.isEmpty) {
        _logger.e('No authentication token found for SignalR connection');
        return;
      }

      // Use HTTPS base; the client selects transport and handles negotiate.
      final serverUrl = '${ApiConstants.baseUrl}$_hubUrl';

      _hubConnection =
          HubConnectionBuilder()
              .withUrl(
                serverUrl,
                options: HttpConnectionOptions(
                  accessTokenFactory:
                      () async =>
                          _authController.currentUser.value?.token ?? '',
                  // Prefer SSE/LongPolling if proxies block WebSockets
                  transport: HttpTransportType.ServerSentEvents,
                ),
              )
              .withAutomaticReconnect()
              .build();
      // Reasonable timeouts for mobile networks
      _hubConnection.serverTimeoutInMilliseconds = 60000; // 60s
      _hubConnection.keepAliveIntervalInMilliseconds = 15000; // 15s

      _setupEventHandlers();
      await _startConnection();
    } catch (e) {
      _logger.e('Failed to initialize SignalR connection: $e');
    }
  }

  void _setupEventHandlers() {
    // Message received
    _hubConnection.on('ReceiveMessage', (arguments) {
      try {
        if (arguments != null && arguments.isNotEmpty) {
          final messageData = arguments[0] as Map<String, dynamic>;
          final message = Message.fromJson(messageData);

          _logger.d('Received message: ${message.id}');
          newMessages.add(message);

          if (onMessageReceived != null) {
            onMessageReceived!(message);
          }
        }
      } catch (e) {
        _logger.e('Error parsing received message: $e');
      }
    });

    // Typing indicator
    _hubConnection.on('UserTyping', (arguments) {
      try {
        if (arguments != null && arguments.length >= 2) {
          final userId = arguments[0] as String;
          final isTyping = arguments[1] as bool;

          _logger.d('User typing: $userId, isTyping: $isTyping');
          typingUser.value = userId;
          this.isTyping.value = isTyping;

          if (onTypingChanged != null) {
            onTypingChanged!(userId, isTyping);
          }
        }
      } catch (e) {
        _logger.e('Error parsing typing indicator: $e');
      }
    });

    // User online/offline
    _hubConnection.on('UserOnline', (arguments) {
      try {
        if (arguments != null && arguments.isNotEmpty) {
          final userId = arguments[0] as String;
          _logger.d('User online: $userId');

          if (onUserOnline != null) {
            onUserOnline!(userId);
          }
        }
      } catch (e) {
        _logger.e('Error parsing user online event: $e');
      }
    });

    _hubConnection.on('UserOffline', (arguments) {
      try {
        if (arguments != null && arguments.isNotEmpty) {
          final userId = arguments[0] as String;
          _logger.d('User offline: $userId');

          if (onUserOffline != null) {
            onUserOffline!(userId);
          }
        }
      } catch (e) {
        _logger.e('Error parsing user offline event: $e');
      }
    });

    // Message read receipt
    _hubConnection.on('MessageRead', (arguments) {
      try {
        if (arguments != null && arguments.isNotEmpty) {
          final messageId = arguments[0] as String;
          _logger.d('Message read: $messageId');

          if (onMessageRead != null) {
            onMessageRead!(messageId);
          }
        }
      } catch (e) {
        _logger.e('Error parsing message read event: $e');
      }
    });
  }

  Future<void> _startConnection() async {
    try {
      await _hubConnection.start();
      isConnected.value = true;
      connectionStatus.value = 'Connected';
      _logger.i('SignalR connection established');
    } catch (e) {
      _logger.e('Failed to start SignalR connection: $e');
      isConnected.value = false;
      connectionStatus.value = 'Connection Failed';
    }
  }

  Future<void> reconnect() async {
    try {
      if (_hubConnection.state == HubConnectionState.Connected) {
        await _hubConnection.stop();
      }
      await _startConnection();
    } catch (e) {
      _logger.e('Failed to reconnect: $e');
    }
  }

  // Send message
  Future<void> sendMessage({
    required String chatRoomId,
    required String content,
    required MessageType type,
    String? mediaUrl,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (_hubConnection.state != HubConnectionState.Connected) {
        throw Exception('SignalR connection not established');
      }

      await _hubConnection.invoke(
        'SendMessage',
        args: [
          chatRoomId,
          content,
          type.toString().split('.').last,
          mediaUrl ?? '',
          replyToMessageId ?? '',
          metadata ?? {},
        ],
      );

      _logger.d('Message sent successfully');
    } catch (e) {
      _logger.e('Failed to send message: $e');
      rethrow;
    }
  }

  // Send typing indicator
  Future<void> sendTypingIndicator({
    required String chatRoomId,
    required bool isTyping,
  }) async {
    try {
      if (_hubConnection.state != HubConnectionState.Connected) {
        return; // Don't throw error for typing indicators
      }

      await _hubConnection.invoke(
        'SendTypingIndicator',
        args: [chatRoomId, isTyping],
      );
    } catch (e) {
      _logger.w('Failed to send typing indicator: $e');
    }
  }

  // Join chat room
  Future<void> joinChatRoom(String chatRoomId) async {
    try {
      if (_hubConnection.state != HubConnectionState.Connected) {
        throw Exception('SignalR connection not established');
      }

      await _hubConnection.invoke('JoinChatRoom', args: [chatRoomId]);
      _logger.d('Joined chat room: $chatRoomId');
    } catch (e) {
      _logger.e('Failed to join chat room: $e');
      rethrow;
    }
  }

  // Leave chat room
  Future<void> leaveChatRoom(String chatRoomId) async {
    try {
      if (_hubConnection.state != HubConnectionState.Connected) {
        return;
      }

      await _hubConnection.invoke('LeaveChatRoom', args: [chatRoomId]);
      _logger.d('Left chat room: $chatRoomId');
    } catch (e) {
      _logger.w('Failed to leave chat room: $e');
    }
  }

  // Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      if (_hubConnection.state != HubConnectionState.Connected) {
        return;
      }

      await _hubConnection.invoke('MarkMessageAsRead', args: [messageId]);
      _logger.d('Marked message as read: $messageId');
    } catch (e) {
      _logger.w('Failed to mark message as read: $e');
    }
  }

  // Get connection state
  HubConnectionState get connectionState =>
      _hubConnection.state ?? HubConnectionState.Disconnected;

  // Dispose
  @override
  void onClose() {
    _hubConnection.stop();
    super.onClose();
  }
}
