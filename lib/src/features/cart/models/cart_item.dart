import 'package:krishi_link/features/admin/models/product_model.dart';

/// Canonical CartItem model (migrated to src/features/cart/models)
class CartItem {
  final String id;
  final String name;
  final String price; // stored as string in existing API responses
  final String imageUrl;
  final int quantity;
  final Product?
  product; // Optional Product reference for better image handling

  const CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    this.product,
  });

  CartItem copyWith({
    String? id,
    String? name,
    String? price,
    String? imageUrl,
    int? quantity,
    Product? product,
  }) => CartItem(
    id: id ?? this.id,
    name: name ?? this.name,
    price: price ?? this.price,
    imageUrl: imageUrl ?? this.imageUrl,
    quantity: quantity ?? this.quantity,
    product: product ?? this.product,
  );

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'] as String,
    name: json['name'] as String,
    price: json['price'] as String,
    imageUrl: json['imageUrl'] as String,
    quantity: json['quantity'] as int,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'imageUrl': imageUrl,
    'quantity': quantity,
  };

  factory CartItem.fromProduct(Product product, {required int quantity}) =>
      CartItem(
        id: product.id,
        name: product.productName,
        price: product.rate.toString(),
        imageUrl: product.image,
        quantity: quantity,
        product: product, // Store the product reference
      );

  /// Get the proper image URL - uses Product model's image if available, falls back to stored imageUrl
  String get properImageUrl => product?.image ?? imageUrl;

  /// Check if we have a Product reference for better image handling
  bool get hasProductReference => product != null;

  @override
  String toString() =>
      'CartItem(id: $id, name: $name, price: ₹$price, quantity: $quantity, hasProduct: $hasProductReference)';
}
