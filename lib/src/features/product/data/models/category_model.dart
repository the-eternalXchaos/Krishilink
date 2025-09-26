class CategoryModel {
  final String id;
  final String name;
  final DateTime? createdAt;

  CategoryModel({required this.id, required this.name, this.createdAt});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString())
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt?.toIso8601String(),
  };
}
