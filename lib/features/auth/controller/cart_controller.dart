import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/src/features/product/data/models/product_model.dart';
import 'package:krishi_link/features/buyer/screens/cart_screen.dart';
import 'package:krishi_link/src/core/networking/api_service.dart';
import 'package:krishi_link/src/features/auth/data/token_service.dart';
import 'package:krishi_link/src/core/components/material_ui/pop_up.dart';

class CartController extends GetxController {
  final _cartItems = <CartItem>[].obs;
  final isLoading = false.obs;
  final isImageLoading = <String, bool>{}.obs;
  final _imageCache = <String, String>{}.obs; // Cache for product images

  List<CartItem> get cartItems => _cartItems;

  late final ApiService _api =
      Get.isRegistered<ApiService>() ? Get.find<ApiService>() : ApiService();

  double get totalPrice => _cartItems.fold(
    0,
    (sum, item) => sum + double.parse(item.price) * item.quantity,
  );

  int get totalItems => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  @override
  void onInit() {
    super.onInit();
    debugPrint('🛒 [CartController] Controller initialized');
    Future.delayed(Duration.zero, fetchCartItems);
  }

  /// Optimized cart fetching with better error handling and caching
  Future<void> fetchCartItems() async {
    if (isLoading.value) return; // Prevent concurrent calls

    try {
      debugPrint('🛒 [CartController] 🚀 Starting fetchCartItems...');
      isLoading.value = true;

      final response = await _api.dio.get(ApiConstants.getCartEndpoint);
      debugPrint('🛒 [CartController] 📥 Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        await _processCartResponse(response.data);
      } else {
        throw Exception('Failed to fetch cart: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _handleDioError(e, 'fetch cart');
    } catch (e) {
      debugPrint('🛒 [CartController] ❌ Error: $e');
      PopupService.error('Failed to load cart', title: 'Error');
    } finally {
      isLoading.value = false;
    }
  }

  /// Process cart response data with optimized image loading
  Future<void> _processCartResponse(dynamic responseData) async {
    try {
      final data =
          responseData is String ? jsonDecode(responseData) : responseData;

      if (data['success'] != true || data['data'] is! List) {
        _cartItems.clear();
        return;
      }

      final cartDataList = data['data'] as List;
      if (cartDataList.isEmpty || cartDataList[0]['items'] == null) {
        _cartItems.clear();
        return;
      }

      final itemsList = cartDataList[0]['items'] as List;
      debugPrint('🛒 [CartController] Processing ${itemsList.length} items');

      // Use CartItem.fromJson directly for each item
      final items = itemsList.map((item) => CartItem.fromJson(item)).toList();
      _cartItems.assignAll(items);
      debugPrint('🛒 [CartController] ✅ Loaded ${_cartItems.length} items');
    } catch (e) {
      debugPrint('🛒 [CartController] ❌ Error processing cart response: $e');
      _cartItems.clear();
    }
  }

  // ...existing code...

  /// Add item to cart with optimized flow
  Future<void> addToCart(CartItem item) async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;

      // Check authentication
      final token = await TokenService.getAccessToken();
      if (token == null || token.isEmpty) {
        _showLoginRequired();
        return;
      }

      // Check if item already exists and update quantity instead
      final existingIndex = _cartItems.indexWhere(
        (cartItem) => cartItem.id == item.id,
      );
      if (existingIndex != -1) {
        final existingItem = _cartItems[existingIndex];
        await _updateCartItemQuantity(
          item.id,
          existingItem.quantity + item.quantity,
        );
        return;
      }

      await _performAddToCartAPI(item);
    } finally {
      isLoading.value = false;
    }
  }

  /// Perform the actual add to cart API call
  Future<void> _performAddToCartAPI(CartItem item) async {
    final requestBody = {
      'items': [
        {'productId': item.id, 'quantity': item.quantity},
      ],
    };

    try {
      final response = await _api.dio.post(
        ApiConstants.addToCartEndpoint,
        data: requestBody,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (_isSuccessResponse(response)) {
        final data =
            response.data is String ? jsonDecode(response.data) : response.data;
        if (data['success'] == true) {
          // Update local cart instead of full refresh for better UX
          await _updateLocalCart(item, isAdd: true);
          _showSuccessMessage('${item.name} added to cart');
          // Always refresh cart from backend after add
          await fetchCartItems();
        } else {
          throw Exception(data['message'] ?? 'Failed to add to cart');
        }
      } else {
        throw Exception('Failed to add to cart: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _handleDioError(e, 'add to cart');
    }
  }

  /// Update local cart optimistically
  Future<void> _updateLocalCart(CartItem item, {required bool isAdd}) async {
    if (isAdd) {
      final existingIndex = _cartItems.indexWhere(
        (cartItem) => cartItem.id == item.id,
      );
      if (existingIndex != -1) {
        // Update existing item quantity
        final existingItem = _cartItems[existingIndex];
        _cartItems[existingIndex] = existingItem.copyWith(
          quantity: existingItem.quantity + item.quantity,
        );
      } else {
        // Add new item
        _cartItems.add(item);
      }
    }

    // Trigger UI update
    _cartItems.refresh();
  }

  // /// Update item quantity with optimized API calls
  // Future<void> updateQuantity(String productId, int newQuantity) async {
  //   if (newQuantity <= 0) {
  //     await removeFromCart(productId);
  //     return;
  //   }

  //   await _updateCartItemQuantity(productId, newQuantity);
  // }

  /// Internal method to update cart item quantity
  Future<void> _updateCartItemQuantity(
    String productId,
    int newQuantity,
  ) async {
    final index = _cartItems.indexWhere((item) => item.id == productId);
    if (index == -1) return;

    final item = _cartItems[index];

    try {
      isLoading.value = true;

      // Optimistic update
      _cartItems[index] = item.copyWith(quantity: newQuantity);

      // Remove and re-add with new quantity (as per existing API)
      await _performRemoveFromCartAPI(productId, showMessage: false);
      await _performAddToCartAPI(item.copyWith(quantity: newQuantity));
    } catch (e) {
      // Revert optimistic update on error
      _cartItems[index] = item;
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Remove item from cart with better error handling
  Future<void> removeFromCart(String productId) async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      await _performRemoveFromCartAPI(productId);
    } finally {
      isLoading.value = false;
    }
  }

  /// Perform remove from cart API call
  Future<void> _performRemoveFromCartAPI(
    String productId, {
    bool showMessage = true,
  }) async {
    try {
      final response = await _api.dio.delete(
        ApiConstants.removeFromCartEndpoint,
        queryParameters: {'productId': productId},
      );

      if (_isSuccessResponse(response)) {
        final data =
            response.data is String ? jsonDecode(response.data) : response.data;
        if (data['success'] == true) {
          // Remove from local cart
          _cartItems.removeWhere((item) => item.id == productId);
          if (showMessage) {
            _showSuccessMessage('Item removed from cart');
          }
          // Always refresh cart from backend after remove
          await fetchCartItems();
        } else {
          throw Exception(data['message'] ?? 'Failed to remove from cart');
        }
      } else {
        throw Exception('Failed to remove from cart: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _handleDioError(e, 'remove from cart');
    }
  }

  /// Clear entire cart
  Future<void> clearCart() async {
    if (isLoading.value || _cartItems.isEmpty) return;

    try {
      isLoading.value = true;
      final response = await _api.dio.delete(ApiConstants.clearCartEndpoint);

      if (_isSuccessResponse(response)) {
        final data =
            response.data is String ? jsonDecode(response.data) : response.data;
        if (data['success'] == true) {
          _cartItems.clear();
          _imageCache.clear(); // Clear image cache
          _showSuccessMessage('Cart cleared successfully');
        } else {
          throw Exception(data['message'] ?? 'Failed to clear cart');
        }
      } else {
        throw Exception('Failed to clear cart: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _handleDioError(e, 'clear cart');
    } finally {
      isLoading.value = false;
    }
  }

  /// Add product to cart (legacy method - maintained for compatibility)
  Future<void> addProductToCart(String productId) async {
    debugPrint('🛒 [CartController] 🚀 addProductToCart (refactored)');
    // Try to get product details from cache or cart
    Product? product;
    // Check if product is in cart
    final existingItem = getCartItem(productId);
    if (existingItem?.product != null) {
      product = existingItem!.product;
    } else {
      // Try to get from image cache (if you have a product cache, use that)
      // Otherwise, fallback to legacy
      // You may want to implement a proper product cache for best UX
    }
    if (product != null) {
      await addProductWithReference(product);
    } else {
      // Fallback: legacy, but try to use details from existing cart item if possible
      final cartItem = CartItem(
        id: productId,
        productId: productId,
        name: existingItem?.name ?? '',
        price: existingItem?.price ?? '0',
        image: existingItem?.image ?? '',
        quantity: 1,
        product: existingItem?.product,
      );
      await addToCart(cartItem);
    }
  }

  /// Add product with full Product reference (recommended method)
  Future<void> addProductWithReference(
    Product product, {
    int quantity = 1,
  }) async {
    debugPrint('🛒 [CartController] 🚀 addProductWithReference');

    // Cache the product image immediately
    if (product.image.isNotEmpty) {
      _imageCache[product.id] = product.image;
    }

    final cartItem = CartItem.fromProduct(product, quantity: quantity);
    await addToCart(cartItem);
  }

  /// Check if product is in cart
  bool isProductInCart(String productId) {
    return _cartItems.any((item) => item.id == productId);
  }

  /// Get quantity of specific product in cart
  int getProductQuantity(String productId) {
    final item = _cartItems.firstWhereOrNull((item) => item.id == productId);
    return item?.quantity ?? 0;
  }

  /// Get cart item by product ID
  CartItem? getCartItem(String productId) {
    return _cartItems.firstWhereOrNull((item) => item.id == productId);
  }

  // Helper methods
  bool _isSuccessResponse(Response response) {
    return response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300;
  }

  void _handleDioError(DioException e, String operation) {
    debugPrint(
      '❌ [CartController] DioException $operation: ${e.type} ${e.message}',
    );
    PopupService.error('Failed to $operation: ${e.message}', title: 'Error');
  }

  void _showLoginRequired() {
    PopupService.warning(
      'Please login to add items to cart',
      title: 'Login Required',
    );
    Get.toNamed('/login');
  }

  void _showSuccessMessage(String message) {
    PopupService.showSnackbar(
      message: message,
      type: PopupType.success,
      title: 'Success',
    );

    fetchCartItems(); // Refresh cart after addition
  }

  @override
  void onClose() {
    _imageCache.clear();
    super.onClose();
  }
}
