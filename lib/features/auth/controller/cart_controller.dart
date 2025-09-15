import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/components/material_ui/popup.dart';
import 'package:krishi_link/core/lottie/popup.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/features/admin/models/product_model.dart';
import 'package:krishi_link/features/cart/models/cart_item.dart';
import 'package:krishi_link/services/api_services/api_service.dart';
import 'package:krishi_link/services/popup_service.dart';
import 'package:krishi_link/services/token_service.dart';

class CartController extends GetxController {
  final _cartItems = <CartItem>[].obs;
  final isLoading = false.obs;
  List<CartItem> get cartItems => _cartItems;

  // Use centralized ApiService with interceptors (adds Authorization header)
  late final ApiService _api =
      Get.isRegistered<ApiService>() ? Get.find<ApiService>() : ApiService();

  double get totalPrice => _cartItems.fold(
    0,
    (sum, item) => sum + double.parse(item.price) * item.quantity,
  );

  @override
  void onInit() {
    super.onInit();
    debugPrint('🛒 [CartController] Controller initialized');
    debugPrint('🛒 [CartController] Current cart items: ${_cartItems.length}');
    Future.delayed(Duration.zero, () {
      debugPrint('🛒 [CartController] Starting initial fetchCartItems...');
      fetchCartItems();
    });
  }

  Future<void> fetchCartItems() async {
    try {
      debugPrint('🛒 [CartController] 🚀 Starting fetchCartItems...');
      isLoading.value = true;

      debugPrint(
        '🛒 [CartController] 📡 Making API call to: ${ApiConstants.getCartEndpoint}',
      );
      final response = await _api.dio.get(ApiConstants.getCartEndpoint);

      debugPrint(
        '🛒 [CartController] 📥 Response received - Status: ${response.statusCode}',
      );
      debugPrint(
        '🛒 [CartController] 📄 Response data type: ${response.data.runtimeType}',
      );
      debugPrint('🛒 [CartController] 📄 Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data =
            response.data is String ? jsonDecode(response.data) : response.data;
        debugPrint('🛒 [CartController] 📊 Parsed data: $data');
        debugPrint('🛒 [CartController] ✅ Success flag: ${data['success']}');

        if (data['success'] == true && data['data'] is List) {
          final cartDataList = data['data'] as List;
          debugPrint(
            '🛒 [CartController] 📦 Cart data list length: ${cartDataList.length}',
          );

          if (cartDataList.isNotEmpty && cartDataList[0]['items'] != null) {
            final itemsList = cartDataList[0]['items'] as List;
            debugPrint(
              '🛒 [CartController] 🎯 Items list length: ${itemsList.length}',
            );
            debugPrint('🛒 [CartController] 🛍️ Items data: $itemsList');

            final items =
                itemsList.map((item) {
                  final imageUrl = item['imageUrl'] ?? item['image'] ?? '';
                  final productName = item['productName'] ?? '';
                  final productId =
                      item['productId'] ??
                      ''; // This is the actual product ID for image fetching

                  debugPrint(
                    '🛒 [CartController] 🖼️ Processing item: $productName',
                  );
                  debugPrint(
                    '🛒 [CartController] 🖼️ Cart Item ID: "${item['id']}"',
                  );
                  debugPrint(
                    '🛒 [CartController] 🖼️ Product ID (for image): "$productId"',
                  );
                  debugPrint(
                    '🛒 [CartController] 🖼️ Raw API image data: imageUrl="${item['imageUrl']}", image="${item['image']}"',
                  );
                  debugPrint(
                    '🛒 [CartController] 🖼️ Final imageUrl: "$imageUrl"',
                  );

                  return CartItem(
                    id: productId, // Use productId as the id for image fetching
                    name: productName,
                    price: (item['price'] ?? item['rate'] ?? 0).toString(),
                    imageUrl: imageUrl,
                    quantity: item['quantity'] ?? 1,
                  );
                }).toList();
            _cartItems.assignAll(items);
            debugPrint(
              '🛒 [CartController] ✅ Cart items assigned: ${_cartItems.length} items',
            );

            for (int i = 0; i < _cartItems.length; i++) {
              final item = _cartItems[i];
              debugPrint(
                '🛒 [CartController] 📋 Item $i: ${item.name} (${item.id}) - ₹${item.price} x ${item.quantity}',
              );
              debugPrint(
                '🛒 [CartController] 🖼️ Item $i image: "${item.imageUrl}" (${item.imageUrl.isEmpty ? "EMPTY" : "NOT EMPTY"})',
              );
            }
          } else {
            debugPrint('🛒 [CartController] 📭 No items found in cart data');
            _cartItems.clear();
          }
        } else {
          debugPrint(
            '🛒 [CartController] ❌ API response not successful or invalid format',
          );
          _cartItems.clear();
        }
      } else {
        debugPrint('🛒 [CartController] ❌ HTTP error: ${response.statusCode}');
        throw Exception('Failed to fetch cart: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint(
        '🛒 [CartController] ❌ DioException in fetchCartItems: ${e.type}',
      );
      debugPrint('🛒 [CartController] ❌ Error message: ${e.message}');
      debugPrint(
        '🛒 [CartController] ❌ Request: ${e.requestOptions.method} ${e.requestOptions.uri}',
      );
      debugPrint('🛒 [CartController] ❌ Response: ${e.response?.data}');
      PopupService.error('Failed to load cart: ${e.message}', title: 'Error');
    } catch (e) {
      debugPrint(
        '🛒 [CartController] ❌ General exception in fetchCartItems: $e',
      );
      PopupService.error('Failed to load cart: $e', title: 'Error');
    } finally {
      isLoading.value = false;
      debugPrint(
        '🛒 [CartController] 🏁 fetchCartItems completed. Final cart count: ${_cartItems.length}',
      );
      debugPrint(
        '🛒 [CartController] 💰 Total price: ₹${totalPrice.toStringAsFixed(2)}',
      );
    }
  }

  Future<void> addToCart(CartItem item) async {
    try {
      isLoading.value = true;
      final token = await TokenService.getAccessToken();
      if (token == null || token.isEmpty) {
        PopupService.warning(
          'Please login to add items to cart',
          title: 'Login Required',
        );
        Get.to('/login');
        return;
      }

      final requestBody = {
        'items': [
          {'productId': item.id, 'quantity': item.quantity},
        ],
      };

      debugPrint('🛒 [Cart] addToCart -> ${ApiConstants.addToCartEndpoint}');
      debugPrint('🛒 [Cart] payload: $requestBody');
      final response = await _api.dio.post(
        ApiConstants.addToCartEndpoint,
        data: requestBody,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      debugPrint('🛒 [Cart] status: ${response.statusCode}');
      debugPrint('🛒 [Cart] response: ${response.data}');
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final data =
            response.data is String ? jsonDecode(response.data) : response.data;
        if (data['success'] == true) {
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
    } on DioException catch (e) {
      debugPrint('❌ [Cart] DioException addToCart: ${e.type} ${e.message}');
      debugPrint(
        '❌ [Cart] request: ${e.requestOptions.method} ${e.requestOptions.uri}',
      );
      debugPrint('❌ [Cart] data: ${e.response?.data}');
      PopupService.error('Failed to add to cart: ${e.message}', title: 'Error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeFromCart(String productId) async {
    try {
      isLoading.value = true;
      final response = await _api.dio.delete(
        ApiConstants.removeFromCartEndpoint,
        queryParameters: {'productId': productId},
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final data =
            response.data is String ? jsonDecode(response.data) : response.data;
        if (data['success'] == true) {
          await fetchCartItems();
          PopupService.success('Item removed from cart', title: 'Success');
        } else {
          throw Exception(data['message'] ?? 'Failed to remove from cart');
        }
      } else {
        throw Exception('Failed to remove from cart: ${response.statusCode}');
      }
    } on DioException catch (e) {
      PopupService.error(
        'Failed to remove from cart: ${e.message}',
        title: 'Error',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> clearCart() async {
    try {
      isLoading.value = true;
      final response = await _api.dio.delete(ApiConstants.clearCartEndpoint);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final data =
            response.data is String ? jsonDecode(response.data) : response.data;
        if (data['success'] == true) {
          _cartItems.clear();
          PopupService.success('Cart cleared successfully', title: 'Success');
        } else {
          throw Exception(data['message'] ?? 'Failed to clear cart');
        }
      } else {
        throw Exception('Failed to clear cart: ${response.statusCode}');
      }
    } on DioException catch (e) {
      PopupService.error('Failed to clear cart: ${e.message}', title: 'Error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addProductToCart(
    String productId,
    String productName,
    String price,
    String imageUrl, {
    int quantity = 1,
  }) async {
    debugPrint('🛒 [CartController] 🚀 addProductToCart called with:');
    debugPrint('🛒 [CartController]   - Product ID: $productId');
    debugPrint('🛒 [CartController]   - Product Name: $productName');
    debugPrint('🛒 [CartController]   - Price: ₹$price');
    debugPrint(
      '🛒 [CartController]   - Image URL: "$imageUrl" (${imageUrl.isEmpty ? "EMPTY" : "NOT EMPTY"})',
    );
    debugPrint('🛒 [CartController]   - Quantity: $quantity');

    final cartItem = CartItem(
      id: productId,
      name: productName,
      price: price,
      imageUrl: imageUrl,
      quantity: quantity,
    );

    debugPrint(
      '🛒 [CartController] 📦 CartItem created: ${cartItem.toString()}',
    );
    debugPrint('🛒 [CartController] 🔄 Calling addToCart method...');

    await addToCart(cartItem);

    debugPrint('🛒 [CartController] ✅ addProductToCart completed');
    debugPrint(
      '🛒 [CartController] 🛍️ Current cart items count: ${_cartItems.length}',
    );
  }

  /// Enhanced method that accepts full Product reference for better image handling
  Future<void> addProductWithReference(
    Product product, {
    int quantity = 1,
  }) async {
    debugPrint('🛒 [CartController] 🚀 addProductWithReference called with:');
    debugPrint('🛒 [CartController]   - Product ID: ${product.id}');
    debugPrint('🛒 [CartController]   - Product Name: ${product.productName}');
    debugPrint('🛒 [CartController]   - Price: ₹${product.rate}');
    debugPrint(
      '🛒 [CartController]   - Product Image: "${product.image}" (${product.image.isEmpty ? "EMPTY" : "NOT EMPTY"})',
    );
    debugPrint('🛒 [CartController]   - Quantity: $quantity');
    debugPrint(
      '🛒 [CartController]   - Full Product Reference: Available for proper image handling',
    );

    final cartItem = CartItem.fromProduct(product, quantity: quantity);

    debugPrint(
      '🛒 [CartController] 📦 CartItem created with Product reference: ${cartItem.toString()}',
    );
    debugPrint('🛒 [CartController] 🔄 Calling addToCart method...');

    await addToCart(cartItem);

    debugPrint('🛒 [CartController] ✅ addProductWithReference completed');
    debugPrint(
      '🛒 [CartController] 🛍️ Current cart items count: ${_cartItems.length}',
    );
  }

  Future<void> updateQuantity(String productId, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeFromCart(productId);
      return;
    }

    final index = _cartItems.indexWhere((item) => item.id == productId);
    if (index != -1) {
      final item = _cartItems[index];
      final updatedItem = item.copyWith(quantity: newQuantity);
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
