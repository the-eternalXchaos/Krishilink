import 'package:hive/hive.dart';
import 'message.dart';

// // part 'chat_room.g.dart';

@HiveType(typeId: 1)
class ChatRoom extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? avatar;

  @HiveField(3)
  final String participantId;

  @HiveField(4)
  final String participantName;

  @HiveField(5)
  final String participantRole; // buyer, farmer, admin

  @HiveField(6)
  final String? lastMessage;

  @HiveField(7)
  final DateTime? lastMessageTime;

  @HiveField(8)
  final int unreadCount;

  @HiveField(9)
  final bool isOnline;

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  final DateTime updatedAt;

  @HiveField(12)
  final String? productId; // For product-related chats

  @HiveField(13)
  final String? productName; // For product-related chats

  ChatRoom({
    required this.id,
    required this.name,
    this.avatar,
    required this.participantId,
    required this.participantName,
    required this.participantRole,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    required this.createdAt,
    required this.updatedAt,
    this.productId,
    this.productName,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'],
      name: json['name'],
      avatar: json['avatar'],
      participantId: json['participantId'],
      participantName: json['participantName'],
      participantRole: json['participantRole'],
      lastMessage: json['lastMessage'],
      lastMessageTime:
          json['lastMessageTime'] != null
              ? DateTime.parse(json['lastMessageTime'])
              : null,
      unreadCount: json['unreadCount'] ?? 0,
      isOnline: json['isOnline'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      productId: json['productId'],
      productName: json['productName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'participantId': participantId,
      'participantName': participantName,
      'participantRole': participantRole,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'unreadCount': unreadCount,
      'isOnline': isOnline,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'productId': productId,
      'productName': productName,
    };
  }

  ChatRoom copyWith({
    String? id,
    String? name,
    String? avatar,
    String? participantId,
    String? participantName,
    String? participantRole,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isOnline,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? productId,
    String? productName,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      participantId: participantId ?? this.participantId,
      participantName: participantName ?? this.participantName,
      participantRole: participantRole ?? this.participantRole,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
    );
  }
}
