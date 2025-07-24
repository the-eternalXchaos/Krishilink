import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/features/auth/controller/cart_controller.dart';
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
        final items =
            (data['cartItems'] as List)
                .map(
                  (item) => CartItem(
                    id: item['id'],
                    name: item['name'],
                    price: item['price'],
                    imageUrl: item['imageUrl'] ?? '',
                    quantity: item['quantity'],
                  ),
                )
                .toList();
        _cartItems.assignAll(items);
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
        Get.toNamed('/login');
        return;
      }

      final response = await http.post(
        Uri.parse(ApiConstants.addToCartEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'productId': item.id, 'quantity': item.quantity}),
      );

      if (response.statusCode == 200) {
        final index = _cartItems.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _cartItems[index] = _cartItems[index].copyWith(
            quantity: _cartItems[index].quantity + item.quantity,
          );
        } else {
          _cartItems.add(item);
        }
        PopupService.success('${item.name} added to cart', title: 'Success');
      } else {
        throw Exception('Failed to add to cart: ${response.statusCode}');
      }
    } catch (e) {
      PopupService.error('Failed to add to cart: $e', title: 'Error');
    }
  }

  Future<void> removeFromCart(CartItem item) async {
    try {
      final token = await TokenService.getAccessToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse(ApiConstants.removeFromCartEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'productId': item.id,
          'quantity': 1, // Decrease by 1
        }),
      );

      if (response.statusCode == 200) {
        final index = _cartItems.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          if (_cartItems[index].quantity > 1) {
            _cartItems[index] = _cartItems[index].copyWith(
              quantity: _cartItems[index].quantity - 1,
            );
          } else {
            _cartItems.removeAt(index);
          }
        }
        PopupService.success(
          '${item.name} removed from cart',
          title: 'Success',
        );
      } else {
        throw Exception('Failed to remove from cart: ${response.statusCode}');
      }
    } catch (e) {
      PopupService.error('Failed to remove from cart: $e', title: 'Error');
    }
  }

  void clearCart() => _cartItems.clear();
}
