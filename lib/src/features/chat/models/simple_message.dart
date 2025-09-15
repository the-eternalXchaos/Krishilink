import 'package:flutter/foundation.dart';

enum MessageStatus { sending, sent, delivered, read, failed }

enum MessageType { text }

class SimpleMessage {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final bool isFromMe;
  final Map<String, dynamic> metadata;

  SimpleMessage({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    required this.status,
    required this.timestamp,
    required this.isFromMe,
    this.metadata = const {},
  });

  SimpleMessage copyWith({
    String? id,
    String? chatRoomId,
    String? senderId,
    String? senderName,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    bool? isFromMe,
    Map<String, dynamic>? metadata,
  }) {
    return SimpleMessage(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      isFromMe: isFromMe ?? this.isFromMe,
      metadata: metadata ?? this.metadata,
    );
  }
}
