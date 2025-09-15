import 'package:get/get.dart';
import 'package:krishi_link/src/features/product/presentation/controllers/product_controller.dart';

/// Product detail page binding
class ProductDetailBinding extends Bindings {
  @override
  void dependencies() {
    // Page-specific controller for product details
    Get.create<ProductController>(() => ProductController());
  }
}
