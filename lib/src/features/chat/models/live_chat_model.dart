// lib/features/chat/live_chat/live_chat_model.dart
class LiveChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String body;
  final DateTime createdAt;

  LiveChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.body,
    required this.createdAt,
  });

  factory LiveChatMessage.fromMap(Map<String, dynamic> map) {
    return LiveChatMessage(
      id:
          (map['id'] ?? map['messageId'] ?? map['chatMessageId'] ?? '')
              .toString(),
      senderId:
          (map['senderId'] ?? map['fromUserId'] ?? map['sender'] ?? '')
              .toString(),
      receiverId:
          (map['receiverId'] ?? map['toUserId'] ?? map['receiver'] ?? '')
              .toString(),
      body:
          (map['body'] ?? map['text'] ?? map['message'] ?? map['content'] ?? '')
              .toString(),
      createdAt:
          DateTime.tryParse(
            (map['createdAt'] ??
                    map['timestamp'] ??
                    map['sentAt'] ??
                    map['time'] ??
                    '')
                .toString(),
          ) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'senderId': senderId,
    'receiverId': receiverId,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
  };
}

/// Backwards compatibility: previous code referenced `ChatMessage` with `text`.
/// Keep a lightweight adapter so any legacy imports still work.
class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    final msg = LiveChatMessage.fromMap(map);
    return ChatMessage(
      id: msg.id,
      senderId: msg.senderId,
      receiverId: msg.receiverId,
      text: msg.body,
      createdAt: msg.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'senderId': senderId,
    'receiverId': receiverId,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };
}

class ChatPartner {
  final String id;
  final String displayName;
  final String contact;
  final bool isOnline;

  ChatPartner({
    required this.id,
    required this.displayName,
    required this.contact,
    required this.isOnline,
  });

  factory ChatPartner.fromMap(Map<String, dynamic> map) {
    return ChatPartner(
      id: (map['id'] ?? map['userId'] ?? '').toString(),
      displayName: (map['displayName'] ?? map['name'] ?? '').toString(),
      contact:
          (map['phone'] ?? map['email'] ?? map['contact'] ?? '').toString(),
      isOnline: (map['isOnline'] ?? map['online'] ?? false) == true,
    );
  }
}
