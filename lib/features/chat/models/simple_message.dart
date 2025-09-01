enum MessageType { text, image, document, voice, video, system }

enum MessageStatus { sending, sent, delivered, read, failed }

class SimpleMessage {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final String? mediaUrl;
  final String? mediaThumbnail;
  final int? mediaDuration;
  final String? mediaFileName;
  final int? mediaFileSize;
  final Map<String, dynamic>? metadata;
  final bool isFromMe;
  final String? replyToMessageId;
  final String? replyToMessageContent;

  SimpleMessage({
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

  factory SimpleMessage.fromJson(Map<String, dynamic> json) {
    return SimpleMessage(
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

  SimpleMessage copyWith({
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
    return SimpleMessage(
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
      replyToMessageContent: replyToMessageContent ?? this.replyToMessageContent,
    );
  }
}