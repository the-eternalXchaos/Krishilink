class SimpleChatRoom {
  final String id;
  final String name;
  final String? avatar;
  final String participantId;
  final String participantName;
  final String participantRole; // buyer, farmer, admin
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? productId; // For product-related chats
  final String? productName; // For product-related chats

  SimpleChatRoom({
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

  factory SimpleChatRoom.fromJson(Map<String, dynamic> json) {
    return SimpleChatRoom(
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

  SimpleChatRoom copyWith({
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
    return SimpleChatRoom(
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