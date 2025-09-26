import 'package:krishi_link/src/features/product/data/models/product_model.dart';

class WishlistItem {
  final String id;
  final String name;
  final String price;
  final String imageUrl;
  final String location;
  final String farmerName;
  final DateTime addedDate;

  WishlistItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.location,
    required this.farmerName,
    required this.addedDate,
  });

  factory WishlistItem.fromProduct(Product product) {
    return WishlistItem(
      id: product.id,
      name: product.productName,
      price: product.rate.toString(),
      imageUrl: product.image,
      location: product.location.toString(),
      farmerName: product.farmerName ?? 'Unknown Farmer',
      addedDate: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'location': location,
      'farmerName': farmerName,
      'addedDate': addedDate.toIso8601String(),
    };
  }

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      imageUrl: json['imageUrl'],
      location: json['location'],
      farmerName: json['farmerName'],
      addedDate: DateTime.parse(json['addedDate']),
    );
  }
}
