import 'package:krishi_link/features/admin/models/product_model.dart';

class CartItem {
  final String id;
  final String name;
  final String price;
  final String imageUrl;
  final int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.quantity,
  });

  CartItem copyWith({
    String? id,
    String? name,
    String? price,
    String? imageUrl,
    int? quantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
    );
  }

//  factory CartItem.fromJson(Map<String, dynamic> json) {
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      name: json['name'] as String,
      price: json['price'] as String,
      imageUrl: json['imageUrl'] as String,
      quantity: json['quantity'] as int,
    );
  }
  // to json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'quantity': quantity,
    };
  }

   factory CartItem.fromProduct(Product product, {required int quantity}) {
    return CartItem(
      id: product.id,
      name: product.productName,
      price: product.rate.toString(),
      imageUrl: product.image,
      quantity: quantity,
    );
  }
}
