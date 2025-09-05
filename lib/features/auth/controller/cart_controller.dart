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
  final isLoading = false.obs;
  List<CartItem> get cartItems => _cartItems;

  double get totalPrice => _cartItems.fold(
    0,
    (sum, item) => sum + double.parse(item.price) * item.quantity,
  );

  @override
  void onInit() {
    super.onInit();
    // Defer cart items loading to avoid setState during build
    Future.delayed(Duration.zero, () => fetchCartItems());
  }

  Future<void> fetchCartItems() async {
    try {
      isLoading.value = true;
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
        if (data['success'] == true &&
            data['data'] != null &&
            data['data'] is List) {
          final cartDataList = data['data'] as List;
          if (cartDataList.isNotEmpty && cartDataList[0]['items'] != null) {
            final itemsList = cartDataList[0]['items'] as List;
            final items =
                itemsList
                    .map(
                      (item) => CartItem(
                        id: item['productId'] ?? '',
                        name: item['productName'] ?? '',
                        price: (item['price'] ?? item['rate'] ?? 0).toString(),
                        // The API response for cart does not contain an image URL.
                        // This will be an empty string for now.
                        imageUrl: item['imageUrl'] ?? item['image'] ?? '',
                        quantity: item['quantity'] ?? 1,
                      ),
                    )
                    .toList();
            _cartItems.assignAll(items);
          } else {
            // Cart is empty or data format is unexpected.
            _cartItems.clear();
          }
        } else {
          // API reports success: false or no data.
          _cartItems.clear();
        }
      } else {
        throw Exception('Failed to fetch cart: ${response.statusCode}');
      }
    } catch (e) {
      PopupService.error('Failed to load cart: $e', title: 'Error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addToCart(CartItem item) async {
    try {
      isLoading.value = true;
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
          // To ensure consistency, refetch the entire cart from the server
          // instead of performing an optimistic local update.
          await fetchCartItems();
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
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeFromCart(String productId) async {
    try {
      isLoading.value = true;
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
          // To ensure consistency, refetch the cart from the server
          // instead of performing an optimistic local update.
          await fetchCartItems();
          PopupService.success('Item removed from cart', title: 'Success');
        } else {
          throw Exception(data['message'] ?? 'Failed to remove from cart');
        }
      } else {
        throw Exception('Failed to remove from cart: ${response.statusCode}');
      }
    } catch (e) {
      PopupService.error('Failed to remove from cart: $e', title: 'Error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> clearCart() async {
    try {
      isLoading.value = true;
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
          // After clearing on the server, clear the local list.
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
    } finally {
      isLoading.value = false;
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

      // WARNING: This performs two separate API operations (remove then add),
      // which is inefficient and may cause a flicker in the UI as the cart
      // is refetched twice. A dedicated backend endpoint to update an item's
      // quantity (e.g., PUT /api/Cart/items/{productId}) is highly recommended.
      try {
        isLoading.value = true;
        await removeFromCart(productId);
        await addToCart(updatedItem);
      } finally {
        isLoading.value = false;
      }
    }
  }
}
