import 'package:hive/hive.dart';

// part 'message.g.dart';

enum MessageType { text, image, document, voice, video, system }

enum MessageStatus { sending, sent, delivered, read, failed }

@HiveType(typeId: 2)
class Message {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String chatRoomId;

  @HiveField(2)
  final String senderId;

  @HiveField(3)
  final String senderName;

  @HiveField(4)
  final String content;

  @HiveField(5)
  final MessageType type;

  @HiveField(6)
  final MessageStatus status;

  @HiveField(7)
  final DateTime timestamp;

  @HiveField(8)
  final String? mediaUrl;

  @HiveField(9)
  final String? mediaThumbnail;

  @HiveField(10)
  final int? mediaDuration; // For voice/video messages

  @HiveField(11)
  final String? mediaFileName; // For documents

  @HiveField(12)
  final int? mediaFileSize; // File size in bytes

  @HiveField(13)
  final Map<String, dynamic>? metadata; // For additional data like product info

  @HiveField(14)
  final bool isFromMe;

  @HiveField(15)
  final String? replyToMessageId; // For reply functionality

  @HiveField(16)
  final String? replyToMessageContent; // Preview of replied message

  Message({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    required this.status,
    required this.timestamp,
    this.mediaUrl,
    this.mediaThumbnail,
    this.mediaDuration,
    this.mediaFileName,
    this.mediaFileSize,
    this.metadata,
    required this.isFromMe,
    this.replyToMessageId,
    this.replyToMessageContent,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      chatRoomId: json['chatRoomId'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      content: json['content'],
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      mediaUrl: json['mediaUrl'],
      mediaThumbnail: json['mediaThumbnail'],
      mediaDuration: json['mediaDuration'],
      mediaFileName: json['mediaFileName'],
      mediaFileSize: json['mediaFileSize'],
      metadata: json['metadata'],
      isFromMe: json['isFromMe'] ?? false,
      replyToMessageId: json['replyToMessageId'],
      replyToMessageContent: json['replyToMessageContent'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'mediaUrl': mediaUrl,
      'mediaThumbnail': mediaThumbnail,
      'mediaDuration': mediaDuration,
      'mediaFileName': mediaFileName,
      'mediaFileSize': mediaFileSize,
      'metadata': metadata,
      'isFromMe': isFromMe,
      'replyToMessageId': replyToMessageId,
      'replyToMessageContent': replyToMessageContent,
    };
  }

  Message copyWith({
    String? id,
    String? chatRoomId,
    String? senderId,
    String? senderName,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    String? mediaUrl,
    String? mediaThumbnail,
    int? mediaDuration,
    String? mediaFileName,
    int? mediaFileSize,
    Map<String, dynamic>? metadata,
    bool? isFromMe,
    String? replyToMessageId,
    String? replyToMessageContent,
  }) {
    return Message(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaThumbnail: mediaThumbnail ?? this.mediaThumbnail,
      mediaDuration: mediaDuration ?? this.mediaDuration,
      mediaFileName: mediaFileName ?? this.mediaFileName,
      mediaFileSize: mediaFileSize ?? this.mediaFileSize,
      metadata: metadata ?? this.metadata,
      isFromMe: isFromMe ?? this.isFromMe,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToMessageContent:
          replyToMessageContent ?? this.replyToMessageContent,
    );
  }
}
