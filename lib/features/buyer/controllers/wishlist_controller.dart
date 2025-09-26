import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:krishi_link/core/lottie/pop_up.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/src/features/product/data/models/product_model.dart';
import 'package:krishi_link/features/buyer/models/wishlist_item.dart';
import 'package:krishi_link/src/core/components/material_ui/pop_up.dart';

class WishlistController extends GetxController {
  final _storage = GetStorage();
  final _wishlistItems = <WishlistItem>[].obs;

  List<WishlistItem> get wishlistItems => _wishlistItems;

  // Check if a product is in wishlist
  bool isInWishlist(String productId) {
    return _wishlistItems.any((item) => item.id == productId);
  }

  @override
  void onInit() {
    super.onInit();
    _loadWishlistFromStorage();
  }

  // Load wishlist from local storage
  void _loadWishlistFromStorage() {
    try {
      final wishlistData = _storage.read('wishlist_items');
      if (wishlistData != null) {
        final List<dynamic> jsonList = jsonDecode(wishlistData);
        _wishlistItems.assignAll(
          jsonList.map((json) => WishlistItem.fromJson(json)).toList(),
        );
      }
    } catch (e) {
      debugPrint('Error loading wishlist: $e');
    }
  }

  // Save wishlist to local storage
  void _saveWishlistToStorage() {
    try {
      final jsonList = _wishlistItems.map((item) => item.toJson()).toList();
      _storage.write('wishlist_items', jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving wishlist: $e');
    }
  }

  // Add product to wishlist
  void addToWishlist(Product product) {
    try {
      // Check if already in wishlist
      if (isInWishlist(product.id)) {
        PopupService.show(
          type: PopupType.warning,
          title: 'already_in_wishlist'.tr,
          message: 'product_already_in_wishlist'.tr,
          autoDismiss: true,
        );
        return;
      }

      final wishlistItem = WishlistItem.fromProduct(product);
      _wishlistItems.add(wishlistItem);
      _saveWishlistToStorage();

      PopupService.show(
        type: PopupType.success,
        title: 'added_to_wishlist'.tr,
        message: 'product_added_to_wishlist'.tr,
        autoDismiss: true,
      );
    } catch (e) {
      PopupService.show(
        type: PopupType.error,
        title: 'error'.tr,
        message: 'failed_to_add_to_wishlist'.tr,
        autoDismiss: true,
      );
    }
  }

  // Remove product from wishlist
  void removeFromWishlist(String productId) {
    try {
      _wishlistItems.removeWhere((item) => item.id == productId);
      _saveWishlistToStorage();

      PopupService.show(
        type: PopupType.success,
        title: 'removed_from_wishlist'.tr,
        message: 'product_removed_from_wishlist'.tr,
        autoDismiss: true,
      );
    } catch (e) {
      PopupService.show(
        type: PopupType.error,
        title: 'error'.tr,
        message: 'failed_to_remove_from_wishlist'.tr,
        autoDismiss: true,
      );
    }
  }

  // Toggle wishlist status
  void toggleWishlist(Product product) {
    if (isInWishlist(product.id)) {
      removeFromWishlist(product.id);
    } else {
      addToWishlist(product);
    }
  }

  // Clear entire wishlist
  void clearWishlist() {
    _wishlistItems.clear();
    _storage.remove('wishlist_items');

    PopupService.show(
      type: PopupType.success,
      title: 'wishlist_cleared'.tr,
      message: 'all_items_removed_from_wishlist'.tr,
      autoDismiss: true,
    );
  }

  // Get wishlist count
  int get wishlistCount => _wishlistItems.length;
}
