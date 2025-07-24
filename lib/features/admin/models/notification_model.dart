class NotificationModel {
  final String id;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? title; // Optional: for notification title
  final String? type; // Optional: for notification type (e.g., "order", "product")
  final String? relatedId; // Optional: ID of related entity (e.g., product or order)

  NotificationModel({
    required this.id,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.title,
    this.type,
    this.relatedId,
  });

  // Getter for timestamp to support NotificationsScreen
  DateTime get timestamp => createdAt;

  // Create NotificationModel from JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      message: json['message'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      title: json['title'],
      type: json['type'],
      relatedId: json['relatedId'],
    );
  }

  // Convert NotificationModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      if (title != null) 'title': title,
      if (type != null) 'type': type,
      if (relatedId != null) 'relatedId': relatedId,
    };
  }

  // Create a copy with updated fields
  NotificationModel copyWith({
    String? id,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    String? title,
    String? type,
    String? relatedId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
    );
  }
}