import 'package:get/get.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/auth/controller/cart_controller.dart';
import 'package:krishi_link/features/buyer/controllers/wishlist_controller.dart';
import 'package:krishi_link/src/features/product/presentation/controllers/product_controller.dart';
import 'package:krishi_link/src/features/product/presentation/controllers/filter_controller.dart';

/// Buyer dashboard binding - includes product browsing and auth-dependent features
class BuyerBinding extends Bindings {
  @override
  void dependencies() {
    // Page-specific controllers (disposed when leaving page)
    Get.create<ProductController>(() => ProductController());
    Get.create<FilterController>(() => FilterController());

    // Auth-dependent controllers - only create if logged in
    final auth = Get.find<AuthController>();
    if (auth.isLoggedIn) {
      Get.lazyPut<CartController>(() => CartController(), fenix: true);
      Get.lazyPut<WishlistController>(() => WishlistController(), fenix: true);
    }
  }
}

/// Guest-safe product binding for welcome page and product details
class GuestBuyerBinding extends Bindings {
  @override
  void dependencies() {
    // Only product-related controllers, no auth-dependent ones
    Get.create<ProductController>(() => ProductController());
    Get.create<FilterController>(() => FilterController());
  }
}
