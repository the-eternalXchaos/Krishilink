class ReviewModel {
  final String? id;
  final String productId;
  final String userId;
  final String username;
  final String review;
  final DateTime timestamp;
  final bool isApproved;
  // final double? rating;
  // final String? imageUrl;

  ReviewModel({
    this.id,
    required this.productId,
    required this.userId,
    required this.username,
    required this.review,
    required this.timestamp,
    this.isApproved = false,
    // this.rating,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      // Some APIs return "reviewId" instead of "id"
      id: (json['id'] ?? json['reviewId'])?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      username: json['userName']?.toString() ?? 'Anonymous',
      review: json['review']?.toString() ?? '',
      // timestamp: DateTime.parse(json['timestamp']),
      timestamp:
          json['timestamp'] != null
              ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
              : DateTime.now(),

      isApproved: json['isApproved'] ?? false,
      // rating: (json['rating'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'userId': userId,
    'username': username,
    'review': review,
    'timestamp': timestamp.toIso8601String(),
    // 'rating': rating,
    'isApproved': isApproved,
  };
}
