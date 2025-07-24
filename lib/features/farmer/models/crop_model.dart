class CropModel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? status;
  final String? suggestions;
  final DateTime? plantedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? note;
  final String? disease;
  final String? careInstructions;

  CropModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.status,
    this.suggestions,
    this.plantedAt,
    this.createdAt,
    this.updatedAt,
    this.note,
    this.disease,
    this.careInstructions,
  });

  factory CropModel.fromJson(Map<String, dynamic> json) => CropModel(
    id: (json['id'] ?? '').toString(),
    name: (json['name'] ?? 'Unknown Crop').toString(),
    description: json['description']?.toString(),
    imageUrl: json['imageUrl']?.toString(),
    plantedAt:
        json['plantedAt'] != null
            ? DateTime.tryParse(json['plantedAt'].toString())
            : null,
    status: json['status']?.toString() ?? 'UNCHECKED',
    suggestions: json['suggestion']?.toString() ?? '',
    createdAt:
        json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
    updatedAt:
        json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'].toString())
            : null,

    note: json['note'] ?? '',
    disease: json['disease'] ?? '',
    careInstructions: json['careInstructions'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'imageUrl': imageUrl,
    'plantedAt': plantedAt?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'status': status ?? 'UNCHECKED',
    'suggestion': suggestions,
    'disease': disease,
    'careInstructions': careInstructions,
    'note': note,
  };

  CropModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    DateTime? plantedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? note,
    String? status,
    String? disease,
    String? careInstructions,
    String? suggestions,
  }) => CropModel(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    imageUrl: imageUrl ?? this.imageUrl,
    plantedAt: plantedAt ?? this.plantedAt,
    createdAt: createdAt ?? this.createdAt,
    note: note ?? this.note,
    status: note ?? this.status,
    suggestions: note ?? this.suggestions,
    disease: note ?? this.disease,
    careInstructions: note ?? this.careInstructions,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
