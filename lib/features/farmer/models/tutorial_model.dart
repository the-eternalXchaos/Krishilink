class TutorialModel {
  final String id;
  final String title;
  final String category;
  final String description;
  final String content; // Detailed steps or instructions
  final String? imageUrl; // Optional media
  final String? videoUrl; // Optional media
  final DateTime? createdAt;

  TutorialModel({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.content,
    this.imageUrl,
    this.videoUrl,
    this.createdAt,
  });

  factory TutorialModel.fromJson(Map<String, dynamic> json) => TutorialModel(
    id: (json['id'] ?? '').toString(),
    title: (json['title'] ?? 'Untitled').toString(),
    category: (json['category'] ?? 'General').toString(),
    description: (json['description'] ?? '').toString(),
    content: (json['content'] ?? '').toString(),
    imageUrl: json['imageUrl']?.toString(),
    videoUrl: json['videoUrl']?.toString(),
    createdAt:
        json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'description': description,
    'content': content,
    'imageUrl': imageUrl,
    'videoUrl': videoUrl,
    'createdAt': createdAt?.toIso8601String(),
  };
}
