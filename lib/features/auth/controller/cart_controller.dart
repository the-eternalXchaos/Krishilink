import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:krishi_link/core/lottie/popup.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/services/token_service.dart';
import 'package:krishi_link/services/popup_service.dart';
import 'package:krishi_link/core/components/material_ui/popup.dart';
import 'package:krishi_link/features/admin/models/cart_item.dart';

class CartController extends GetxController {
  final _cartItems = <CartItem>[].obs;
  List<CartItem> get cartItems => _cartItems;

  double get totalPrice => _cartItems.fold(
    0,
    (sum, item) => sum + double.parse(item.price) * item.quantity,
  );

  @override
  void onInit() {
    super.onInit();
    fetchCartItems();
  }

  Future<void> fetchCartItems() async {
    try {
      final token = await TokenService.getAccessToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse(ApiConstants.getCartEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final items =
              (data['data'] as List)
                  .map(
                    (item) => CartItem(
                      id: item['productId'] ?? item['id'] ?? '',
                      name: item['productName'] ?? item['name'] ?? '',
                      price: (item['price'] ?? item['rate'] ?? 0).toString(),
                      imageUrl: item['imageUrl'] ?? item['image'] ?? '',
                      quantity: item['quantity'] ?? 1,
                    ),
                  )
                  .toList();
          _cartItems.assignAll(items);
        } else {
          _cartItems.clear();
        }
      } else {
        throw Exception('Failed to fetch cart: ${response.statusCode}');
      }
    } catch (e) {
      PopupService.error('Failed to load cart: $e', title: 'Error');
    }
  }

  Future<void> addToCart(CartItem item) async {
    try {
      final token = await TokenService.getAccessToken();
      if (token == null) {
        PopupService.warning(
          'Please login to add items to cart',
          title: 'Login Required',
        );
        Get.to('/login');
        return;
      }

      // Format according to the API specification
      final requestBody = {
        'items': [
          {'productId': item.id, 'quantity': item.quantity},
        ],
      };

      final response = await http.post(
        Uri.parse(ApiConstants.addToCartEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Check if item already exists in cart
          final existingIndex = _cartItems.indexWhere((i) => i.id == item.id);
          if (existingIndex != -1) {
            // Update quantity
            _cartItems[existingIndex] = _cartItems[existingIndex].copyWith(
              quantity: _cartItems[existingIndex].quantity + item.quantity,
            );
          } else {
            // Add new item
            _cartItems.add(item);
          }
          PopupService.show(
            message: '${item.name} added to cart',
            autoDismiss: true,
            type: PopupType.addedToCart,
            title: 'Success',
          );
        } else {
          throw Exception(data['message'] ?? 'Failed to add to cart');
        }
      } else {
        throw Exception('Failed to add to cart: ${response.statusCode}');
      }
    } catch (e) {
      PopupService.error('Failed to add to cart: $e', title: 'Error');
    }
  }

  Future<void> removeFromCart(String productId) async {
    try {
      final token = await TokenService.getAccessToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.delete(
        Uri.parse(
          '${ApiConstants.removeFromCartEndpoint}?productId=$productId',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Remove item from local cart
          _cartItems.removeWhere((item) => item.id == productId);
          PopupService.success('Item removed from cart', title: 'Success');
        } else {
          throw Exception(data['message'] ?? 'Failed to remove from cart');
        }
      } else {
        throw Exception('Failed to remove from cart: ${response.statusCode}');
      }
    } catch (e) {
      PopupService.error('Failed to remove from cart: $e', title: 'Error');
    }
  }

  Future<void> clearCart() async {
    try {
      final token = await TokenService.getAccessToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.delete(
        Uri.parse(ApiConstants.clearCartEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _cartItems.clear();
          PopupService.success('Cart cleared successfully', title: 'Success');
        } else {
          throw Exception(data['message'] ?? 'Failed to clear cart');
        }
      } else {
        throw Exception('Failed to clear cart: ${response.statusCode}');
      }
    } catch (e) {
      PopupService.error('Failed to clear cart: $e', title: 'Error');
    }
  }

  // Helper method to add product to cart
  Future<void> addProductToCart(
    String productId,
    String productName,
    String price,
    String imageUrl, {
    int quantity = 1,
  }) async {
    final cartItem = CartItem(
      id: productId,
      name: productName,
      price: price,
      imageUrl: imageUrl,
      quantity: quantity,
    );
    await addToCart(cartItem);
  }

  // Helper method to update quantity
  Future<void> updateQuantity(String productId, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeFromCart(productId);
      return;
    }

    final index = _cartItems.indexWhere((item) => item.id == productId);
    if (index != -1) {
      final item = _cartItems[index];
      final updatedItem = item.copyWith(quantity: newQuantity);

      // Remove the old item and add the updated one
      await removeFromCart(productId);
      await addToCart(updatedItem);
    }
  }
}
