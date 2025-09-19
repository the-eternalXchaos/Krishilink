import 'package:get/get.dart';
import 'package:krishi_link/src/features/product/presentation/controllers/product_controller.dart';

/// Product detail page binding
class ProductDetailBinding extends Bindings {
  @override
  void dependencies() {
    // Lazy product controller (shared singleton) reused by detail pages
    Get.lazyPut<ProductController>(() => ProductController(), fenix: true);
  }
}
