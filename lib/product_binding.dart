import 'package:get/get.dart';
// Canonical src-layer imports
import 'package:krishi_link/src/features/product/presentation/controllers/filter_controller.dart';
import 'package:krishi_link/src/features/product/presentation/controllers/product_controller.dart';
import 'package:krishi_link/features/auth/controller/cart_controller.dart';
import 'package:krishi_link/features/buyer/controllers/wishlist_controller.dart';

class ProductBinding extends Bindings {
  @override
  void dependencies() {
    // Use lazyPut to avoid initializing controllers until they're actually needed
    // This prevents unnecessary API calls on login/welcome pages
    Get.lazyPut<ProductController>(() => ProductController(), fenix: true);
    Get.lazyPut<FilterController>(() => FilterController(), fenix: true);
    Get.lazyPut<CartController>(() => CartController());
    Get.lazyPut<WishlistController>(() => WishlistController());
  }
}
