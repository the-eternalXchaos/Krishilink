import 'package:get/get.dart';
import 'package:krishi_link/src/features/product/presentation/controllers/filter_controller.dart';
import 'package:krishi_link/src/features/product/presentation/controllers/product_controller.dart';

class GuestProductBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProductController>(() => ProductController());
    Get.lazyPut<FilterController>(() => FilterController());
  }
}
