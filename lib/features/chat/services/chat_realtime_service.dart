class ChatRealtimeService {
  void connect({required String chatRoomId, required String token, required Null Function(dynamic message) onMessageReceived, required Null Function() onDone, required Null Function(dynamic error) onError}) {}

  void onClose() {}
    
}

