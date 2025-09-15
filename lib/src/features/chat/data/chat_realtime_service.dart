import 'live_chat_service.dart';

/// Backward compatible wrapper exposing the same API as legacy ChatRealtimeService.
class ChatRealtimeService {
  final ChatService _inner = ChatService();

  bool get isConnected => _inner.isConnected;
  String? get lastError => _inner.lastError;
  String envSummary() => _inner.envSummary();
  String snapshot() => _inner.snapshot();

  Stream<Map<String, dynamic>> get messages => _inner.messages;
  Stream<Object> get errors => _inner.errors;
  Stream connectionState() => _inner.connectionState;

  Future<bool> connect({bool verbose = false, String? hubUrl}) =>
      _inner.connect(verbose: verbose, hubUrl: hubUrl);
  Future<void> invoke(String methodName, {List<Object>? args}) =>
      _inner.invoke(methodName, args: args);
  Future<void> sendToUser(String receiverUserId, String text) =>
      _inner.sendToUser(receiverUserId, text);
  // Legacy no-op wrappers (methods removed/renamed in new service)
  Future<void> disconnect() async {}

  // Backward compatibility: older code expects explicit join/leave.
  Future<void> joinRoom(String roomId) async {
    // If ChatService implicitly joins on send/receive, we no-op here.
    // Hook for future explicit join implementation.
    return; // no-op
  }

  Future<void> leaveRoom(String roomId) async {
    // No explicit leave semantics yet; provide stub to avoid crashes.
    return; // no-op
  }
}
