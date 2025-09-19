import 'package:krishi_link/features/admin/models/product_model.dart';

class ProductFormData {
  String productName;
  String description;
  double rate;
  String unit;
  double latitude;
  double longitude;
  String? location;
  String imagePath;
  double availableQuantity;
  String category;
  String farmerContact;

  ProductFormData({
    this.productName = '',
    this.description = '',
    this.rate = 0,
    this.unit = 'kg',
    this.latitude = 0,
    this.longitude = 0,
    this.location = '',
    this.imagePath = '',
    this.availableQuantity = 0,
    this.category = '',
    this.farmerContact = '',
  });

  // Create from Product model
  factory ProductFormData.fromProduct(Product product) {
    return ProductFormData(
      productName: product.productName,
      description: product.description,
      rate: product.rate,
      unit: product.unit,
      latitude: product.latitude,
      longitude: product.longitude,
      // location: product.location ?? '',
      imagePath: product.image,
      availableQuantity: product.availableQuantity,
      category: product.category,
      farmerContact: product.farmerPhone ?? '',
    );
  }

  // Validation method
  bool isValid() {
    return productName.trim().isNotEmpty &&
        rate > 0 &&
        availableQuantity >= 0 &&
        category.trim().isNotEmpty &&
        // location!.trim().isNotEmpty &&
        latitude != 0 &&
        longitude != 0;
  }

  // Copy with method for immutability
  ProductFormData copyWith({
    String? productName,
    String? description,
    double? rate,
    String? unit,
    double? latitude,
    double? longitude,
    String? location,
    String? imagePath,
    double? availableQuantity,
    String? category,
    String? farmerContact,
  }) {
    return ProductFormData(
      productName: productName ?? this.productName,
      description: description ?? this.description,
      rate: rate ?? this.rate,
      unit: unit ?? this.unit,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      location: location ?? this.location,
      imagePath: imagePath ?? this.imagePath,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      category: category ?? this.category,
      farmerContact: farmerContact ?? this.farmerContact,
    );
  }
}
