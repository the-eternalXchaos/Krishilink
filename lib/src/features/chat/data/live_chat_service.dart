import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:krishi_link/src/features/chat/data/live_chat_api_service.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/src/core/storage/token_storage.dart';

class ChatService {
  static final ChatService I = ChatService._internal();
  factory ChatService() => I;
  ChatService._internal();

  HubConnection? _conn;
  final _msgCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _errorCtrl = StreamController<Object>.broadcast();
  final _stateCtrl = StreamController<HubConnectionState>.broadcast();
  Stream<Map<String, dynamic>> get messages => _msgCtrl.stream;
  Stream<Object> get errors => _errorCtrl.stream;
  Stream<HubConnectionState> get connectionState => _stateCtrl.stream;
  String? _lastUsedUrl;
  String? get lastError => _lastError;
  String? _lastError;
  bool get isConnected => _conn?.state == HubConnectionState.Connected;

  String envSummary() {
    return '{connected: $isConnected, connectionId: ${_conn?.connectionId}, state: ${_conn?.state}, lastUsedUrl: $_lastUsedUrl, attemptCounter: $_attemptCounter, lastError: $_lastError}';
  }

  String snapshot() {
    return '{connected: $isConnected, state: ${_conn?.state}, lastError: $_lastError, lastUsedUrl: $_lastUsedUrl, attemptCounter: $_attemptCounter, timestamp: ${DateTime.now().toIso8601String()}}';
  }

  int _attemptCounter = 0;
  Future<bool> _startWithRetry({int maxAttempts = 3}) async {
    _attemptCounter = 0;
    while (_attemptCounter < maxAttempts) {
      _attemptCounter++;
      try {
        debugPrint('🌐 Connection attempt $_attemptCounter/$maxAttempts');
        // ensure a bounded start time per attempt (mobile networks can hang)
        final c = _conn;
        if (c != null) {
          final startFuture = c.start();
          if (startFuture != null) {
            await startFuture.timeout(const Duration(seconds: 15));
          }
        }
        debugPrint('✅ Connection established: ${_conn?.connectionId}');
        _stateCtrl.add(HubConnectionState.Connected);
        return true;
      } catch (e) {
        debugPrint('❌ Connection attempt $_attemptCounter failed: $e');
        _lastError = e.toString();
        if (_attemptCounter < maxAttempts) {
          // exponential backoff with jitter
          final backoff = 2000 * _attemptCounter;
          final jitter = (500 * (_attemptCounter)).clamp(0, 1500);
          await Future.delayed(Duration(milliseconds: backoff + jitter));
        }
      }
    }
    return false;
  }

  Future<bool> connect({bool verbose = false, String? hubUrl}) async {
    hubUrl = hubUrl ?? '${ApiConstants.baseUrl}/ChatHub';
    _lastUsedUrl = hubUrl;
    _lastError = null;
    try {
      if (_conn?.state == HubConnectionState.Connected) {
        debugPrint('✅ Already connected: ${_conn?.connectionId}');
        return true;
      }

      _conn?.stop();
      final token = await TokenStorage.getToken();
      if (token == null) {
        debugPrint('❌ No token found');
        return false;
      }
      debugPrint('🔐 Using token (length: ${token.length})');

      // Try WebSockets first with auto-reconnect
      _conn =
          HubConnectionBuilder()
              .withUrl(
                hubUrl,
                options: HttpConnectionOptions(
                  accessTokenFactory: () async => token,
                  logMessageContent: verbose,
                  skipNegotiation: false,
                  transport: HttpTransportType.WebSockets,
                ),
              )
              .withAutomaticReconnect()
              .build();

      // Apply reasonable mobile network timeouts
      try {
        _conn!.serverTimeoutInMilliseconds = 60000; // 60s
        _conn!.keepAliveIntervalInMilliseconds = 15000; // 15s
      } catch (_) {
        // ignore if not supported by the platform
      }

      _setupCoreHandlers();
      _stateCtrl.add(HubConnectionState.Connecting);

      bool success = await _startWithRetry(maxAttempts: 3);
      if (!success && hubUrl.endsWith('/ChatHub')) {
        debugPrint(
          '🌐 Retrying with lowercase: ${hubUrl.replaceFirst('/ChatHub', '/chatHub')}',
        );
        _lastUsedUrl = hubUrl.replaceFirst('/ChatHub', '/chatHub');
        // Retry with lowercase path (WebSockets)
        _conn =
            HubConnectionBuilder()
                .withUrl(
                  _lastUsedUrl!,
                  options: HttpConnectionOptions(
                    accessTokenFactory:
                        () async => await TokenStorage.getToken() ?? '',
                    logMessageContent: verbose,
                    skipNegotiation: false,
                    transport: HttpTransportType.WebSockets,
                  ),
                )
                .withAutomaticReconnect()
                .build();

        try {
          _conn!.serverTimeoutInMilliseconds = 60000;
          _conn!.keepAliveIntervalInMilliseconds = 15000;
        } catch (_) {}

        _setupCoreHandlers();
        _stateCtrl.add(HubConnectionState.Connecting);
        success = await _startWithRetry(maxAttempts: 3);
      }

      // If still not connected, try ServerSentEvents (some proxies block WS)
      if (!success) {
        debugPrint('🌐 Retrying with ServerSentEvents transport');
        _conn =
            HubConnectionBuilder()
                .withUrl(
                  _lastUsedUrl ?? hubUrl,
                  options: HttpConnectionOptions(
                    accessTokenFactory:
                        () async => await TokenStorage.getToken() ?? '',
                    logMessageContent: verbose,
                    skipNegotiation: false,
                    transport: HttpTransportType.ServerSentEvents,
                  ),
                )
                .withAutomaticReconnect()
                .build();

        try {
          _conn!.serverTimeoutInMilliseconds = 60000;
          _conn!.keepAliveIntervalInMilliseconds = 15000;
        } catch (_) {}

        _setupCoreHandlers();
        _stateCtrl.add(HubConnectionState.Connecting);
        success = await _startWithRetry(maxAttempts: 3);
      }

      if (!success) {
        debugPrint('❌ All connection attempts failed');
        _stateCtrl.add(HubConnectionState.Disconnected);
        return false;
      }

      debugPrint('✅ Connected to $hubUrl');
      return true;
    } catch (e) {
      debugPrint('❌ Connection error: $e');
      _lastError = e.toString();
      _stateCtrl.add(HubConnectionState.Disconnected);
      return false;
    }
  }

  Future<void> invoke(String methodName, {List<Object>? args}) async {
    if (_conn == null || !isConnected) {
      debugPrint('❌ Cannot invoke $methodName: not connected');
      throw Exception('Hub not connected');
    }
    try {
      await _conn!.invoke(methodName, args: args ?? []);
      debugPrint('✅ Invoked $methodName with args: $args');
    } catch (e) {
      debugPrint('❌ Invoke $methodName failed: $e');
      rethrow;
    }
  }

  Future<void> sendToUser(String receiverUserId, String text) async {
    if (text.trim().isEmpty) return;

    debugPrint(
      '🔍 sendToUser: receiver=$receiverUserId, msg="$text", state=${_conn?.state}, connId=${_conn?.connectionId}',
    );

    if (!isConnected || _conn == null) {
      debugPrint('🔌 Not connected, attempting quick reconnect');
      try {
        final ok = await connect(
          verbose: true,
          hubUrl: _lastUsedUrl ?? '${ApiConstants.baseUrl}/ChatHub',
        );
        if (!ok) {
          debugPrint('❌ Quick reconnect failed');
          throw Exception('Hub not connected');
        }
      } catch (e) {
        _errorCtrl.add(e);
        debugPrint('❌ Reconnect failed: $e');
        throw Exception('Reconnect before send failed: $e');
      }
    }

    try {
      debugPrint('📤 Invoking SendMessage to $receiverUserId');
      await _conn!.invoke('SendMessage', args: [receiverUserId, text]);
      debugPrint('✅ Sent via Hub');
    } catch (e) {
      _errorCtrl.add(e);
      debugPrint('❌ SendMessage error: $e');
      try {
        final delivered = await Get.find<LiveChatApiService>().sendMessage(
          receiverUserId,
          text,
        );
        if (delivered) {
          debugPrint('✅ Sent via REST fallback');
        } else {
          debugPrint('❌ REST fallback failed');
          throw Exception('REST send failed');
        }
      } catch (restE) {
        debugPrint('❌ REST fallback error: $restE');
        throw Exception('Send failed: $e; REST failed: $restE');
      }
    }
  }

  void _setupCoreHandlers() {
    final conn = _conn;
    if (conn == null) {
      debugPrint('⚠️ Cannot setup handlers: connection is null');
      return;
    }

    void registerReceiveHandler(String eventName) {
      conn.on(eventName, (List<Object?>? args) {
        try {
          if (args == null || args.isEmpty) {
            debugPrint('⚠️ $eventName: null or empty args');
            return;
          }

          String? senderId;
          String senderName = 'Unknown';
          String message = '';
          String? createdAtIso;

          debugPrint('📨 $eventName args: ${args.length} - $args');

          // Preferred new payload: [senderUserId, senderFullName, message, createdAt?]
          final first = args.isNotEmpty ? args[0] : null;
          final second = args.length > 1 ? args[1] : null;
          final third = args.length > 2 ? args[2] : null;

          final looksLikeNewShape =
              args.length >= 3 &&
              third is String &&
              (second is String || second == null);

          if (looksLikeNewShape) {
            senderId = first?.toString();
            senderName = (second as String?)?.trim() ?? 'Unknown';
            message = (third as String?)?.trim() ?? '';
            if (args.length >= 4) {
              createdAtIso = args[3]?.toString();
            }
            debugPrint(
              '📨 Parsed (new): id=$senderId, name=$senderName, msg=$message',
            );
          } else if (args.length >= 2) {
            // Legacy payload: [senderName, message, createdAt?]
            senderName = (args[0] as String?)?.trim() ?? 'Unknown';
            message = (args[1] as String?)?.trim() ?? '';
            if (args.length >= 3) {
              createdAtIso = args[2]?.toString();
            }
            debugPrint('📨 Parsed (legacy 2+): name=$senderName, msg=$message');
          } else {
            // Old minimal payload: [message]
            message = (args[0] as String?)?.trim() ?? '';
            debugPrint('📨 Parsed (legacy 1): msg=$message');
          }

          if (message.isEmpty) {
            debugPrint('⚠️ Empty message ignored');
            return;
          }

          createdAtIso ??= DateTime.now().toIso8601String();

          _msgCtrl.add({
            'senderId': senderId,
            'senderName': senderName,
            'message': message,
            'createdAt': createdAtIso,
          });
          debugPrint(
            '✅ Added to stream: ${senderName.isEmpty ? senderId ?? 'Unknown' : senderName}: $message',
          );
        } catch (e) {
          _errorCtrl.add(e);
          debugPrint('❌ $eventName parse error: $e');
        }
      });
    }

    // Register handlers for both the expected event and the backend's current typo variant
    registerReceiveHandler('ReceiveMessage');
    registerReceiveHandler('Reveivemesage'); // temporary: backend typo support

    conn.on('ReceiveSystemMessage', (List<Object?>? args) {
      try {
        if (args == null || args.isEmpty) return;
        final msg = (args.first as String?) ?? '';
        if (msg.isEmpty) return;
        _msgCtrl.add({
          'system': true,
          'message': msg,
          'createdAt': DateTime.now().toIso8601String(),
        });
        debugPrint('📢 System message: $msg');
      } catch (e) {
        _errorCtrl.add(e);
        debugPrint('❌ ReceiveSystemMessage parse error: $e');
      }
    });

    conn.on('Error', (List<Object?>? args) {
      try {
        if (args == null || args.isEmpty) return;
        final errorMsg = (args.first as String?) ?? 'Unknown error';
        _errorCtrl.add(Exception(errorMsg));
        debugPrint('❌ Hub error: $errorMsg');
      } catch (e) {
        _errorCtrl.add(e);
        debugPrint('❌ Error handler parse error: $e');
      }
    });

    conn.onclose(({error}) async {
      debugPrint('🔌 SignalR closed: $error');
      _stateCtrl.add(HubConnectionState.Disconnected);
      if (error != null) {
        _lastError = error.toString();
        _errorCtrl.add(error);
      }
    });

    conn.onreconnecting(({error}) {
      debugPrint('🔄 SignalR reconnecting: $error');
      _stateCtrl.add(HubConnectionState.Reconnecting);
    });

    conn.onreconnected(({connectionId}) {
      debugPrint('🔄 SignalR reconnected: connectionId=$connectionId');
      _stateCtrl.add(HubConnectionState.Connected);
    });
  }
}
