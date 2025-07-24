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
