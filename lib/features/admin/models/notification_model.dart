class NotificationModel {
  final String id;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String title;
  final String type;
  final String? relatedId;

  NotificationModel({
    required this.id,
    required this.message,
    required this.isRead,
    required this.createdAt,
    String? title,
    String? type,
    this.relatedId,
  }) : title = title ?? 'Notification',
       type = type ?? 'info';

  // Time ago Helper
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
  }

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
      'title': title,
      'type': type,
      if (relatedId != null) 'relatedId': relatedId,
    };
  }

  // Copy with updated fields
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
