import 'package:flutter/material.dart';
import 'package:krishi_link/core/utils/api_constants.dart';

class Product {
  final String id;
  final String productName;
  final String description;
  final double rate;
  final String unit;
  final double latitude;
  final double longitude;
  final String? location;
  final String? address;
  final String image;
  final double? soldedQuantity;
  final double availableQuantity;
  final String category;
  final String? farmerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? farmerPhone;
  final String? farmerName;
  final bool isActive;
  final double? distance;

  Product({
    required this.id,
    required this.productName,
    required this.description,
    required this.rate,
    required this.unit,
    required this.latitude,
    required this.longitude,
    this.location,
    this.address,
    required this.image,
    required this.soldedQuantity,
    required this.availableQuantity,
    required this.category,
    required this.farmerId,
    this.createdAt,
    this.updatedAt,
    required this.farmerPhone,
    required this.farmerName,
    required this.isActive,
    this.distance,
  });

  factory Product.fromJson(dynamic json) {
    try {
      if (json is! Map) {
        throw const FormatException('Product.fromJson: input is not a Map');
      }

      return Product(
        id: json['productId']?.toString() ?? '',
        productName: json['productName']?.toString() ?? '',
        description: json['description']?.toString() ?? 'No description',
        rate: _toDouble(json['rate']),
        unit: json['unit']?.toString() ?? 'kg',
        latitude: _toDouble(json['latitude']),
        longitude: _toDouble(json['longitude']),
        location: json['city']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        image:
            json['imagePath']?.toString() ??
            (json['imageCode'] != null
                ? '${ApiConstants.getProductImageEndpoint}/${json['imageCode']}?t=${DateTime.now().millisecondsSinceEpoch}'
                : ''),
        soldedQuantity: _toDouble(json['soldedQuantity']),
        availableQuantity: _toDouble(json['availableQuantity']),
        category: json['category']?.toString() ?? '',
        farmerId: json['farmerId']?.toString() ?? '',
        farmerName: json['farmerName']?.toString() ?? '',
        farmerPhone: json['farmerEmailorPhone']?.toString() ?? '',
        createdAt:
            json['dateTime'] != null
                ? DateTime.tryParse(json['dateTime'].toString())
                : null,
        updatedAt:
            json['updated_at'] != null
                ? DateTime.tryParse(json['updated_at'].toString())
                : null,
        isActive: json['isActive'] == true || json['isActive'] == 'true',
        distance: json['distance'] != null ? _toDouble(json['distance']) : null,
      );
    } catch (e, stack) {
      debugPrint('Product.fromJson error: $e\n$stack');
      return Product(
        id: '',
        productName: '',
        description: 'No description',
        rate: 0.0,
        unit: 'kg',
        latitude: 0.0,
        longitude: 0.0,
        location: '',
        address: '',
        image: '',
        soldedQuantity: 0.0,
        availableQuantity: 0.0,
        category: '',
        farmerId: '',
        farmerName: '',
        farmerPhone: '',
        createdAt: null,
        updatedAt: null,
        isActive: false,
        distance: null,
      );
    }
  }

  Map<String, dynamic> toJson() => {
    'productId': id,
    'productName': productName,
    'description': description,
    'rate': rate,
    'unit': unit,
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'location': location,
    'imagePath': image,
    'soldedQuantity': soldedQuantity,
    'availableQuantity': availableQuantity,
    'category': category,
    'farmerId': farmerId,
    'farmerName': farmerName,
    'farmerEmailorPhone': farmerPhone,
    'dateTime': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'isActive': isActive,
    'distance': distance,
  };

  Product copyWith({
    String? id,
    String? productName,
    String? description,
    double? rate,
    String? unit,
    double? latitude,
    double? longitude,
    String? location,
    String? address,
    String? image,
    double? soldedQuantity,
    double? availableQuantity,
    String? category,
    String? farmerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? farmerPhone,
    String? farmerName,
    bool? isActive,
    double? distance,
  }) => Product(
    id: id ?? this.id,
    productName: productName ?? this.productName,
    description: description ?? this.description,
    rate: rate ?? this.rate,
    unit: unit ?? this.unit,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    location: location ?? this.location,
    address: address ?? this.address,
    image: image ?? this.image,
    soldedQuantity: soldedQuantity ?? this.soldedQuantity,
    availableQuantity: availableQuantity ?? this.availableQuantity,
    category: category ?? this.category,
    farmerId: farmerId ?? this.farmerId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    farmerPhone: farmerPhone ?? this.farmerPhone,
    farmerName: farmerName ?? this.farmerName,
    isActive: isActive ?? this.isActive,
    distance: distance ?? this.distance,
  );

  bool matchesFilter(String filter) {
    final filterLower = filter.toLowerCase();
    return category.toLowerCase().contains(filterLower) ||
        productName.toLowerCase().contains(filterLower) ||
        description.toLowerCase().contains(filterLower) ||
        (location != null && location!.toLowerCase().contains(filterLower)) ||
        (address != null && address!.toLowerCase().contains(filterLower));
  }

  static Set<String> getAvailableFilters(List<Product> products) {
    final filters = <String>{};
    for (final product in products) {
      if (product.category.isNotEmpty) {
        filters.add(product.category);
      }
    }
    return filters;
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
