import 'package:krishi_link/src/features/product/data/models/product_model.dart';
import 'package:krishi_link/core/utils/api_constants.dart';

class CartItem {
  final String id;
  final String name;
  final String price; // stored as string in existing API responses
  final String productId;
  final int quantity;
  final String image; // Image URL or path, constructed like Product model
  final Product?
  product; // Optional Product reference for better image handling

  const CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.productId,
    required this.quantity,
    required this.image,
    this.product,
  });

  CartItem copyWith({
    String? id,
    String? name,
    String? price,
    String? productId,
    int? quantity,
    String? image,
    Product? product,
  }) => CartItem(
    id: id ?? this.id,
    name: name ?? this.name,
    price: price ?? this.price,
    productId: productId ?? this.productId,
    quantity: quantity ?? this.quantity,
    image: image ?? this.image,
    product: product ?? this.product,
  );

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id']?.toString() ?? '',
    name: json['productName']?.toString() ?? json['name']?.toString() ?? '',
    price: json['price']?.toString() ?? json['rate']?.toString() ?? '',
    productId: json['productId']?.toString() ?? '',
    quantity:
        json['quantity'] is int
            ? json['quantity']
            : int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
    image:
        (json['productImageCode'] != null
            ? '${ApiConstants.getProductImageEndpoint}/${json['productImageCode']}?t=${DateTime.now().millisecondsSinceEpoch}'
            : ''),
    product: null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'productId': productId,
    'image': image,
    'quantity': quantity,
  };

  factory CartItem.fromProduct(Product product, {required int quantity}) =>
      CartItem(
        id: product.id,
        name: product.productName,
        price: product.rate.toString(),
        productId: product.id,
        image: product.image,
        quantity: quantity,
        product: product, // Store the product reference
      );

  /// Get the image URL for the cart item
  String get properImageUrl => image;

  /// Check if we have a Product reference for better image handling
  bool get hasProductReference => product != null;

  @override
  String toString() =>
      'CartItem(id: $id, name: $name, price: ₹$price, quantity: $quantity, productId: $productId, image: $image, hasProduct: $hasProductReference)';
}
