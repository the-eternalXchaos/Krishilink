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
    // Core browsing controllers as lazy singletons; recreate with fenix when needed
    Get.lazyPut<ProductController>(() => ProductController(), fenix: true);
    Get.lazyPut<FilterController>(() => FilterController(), fenix: true);

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
    Get.lazyPut<ProductController>(() => ProductController(), fenix: true);
    Get.lazyPut<FilterController>(() => FilterController(), fenix: true);
  }
}
