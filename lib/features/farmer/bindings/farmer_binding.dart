import 'package:get/get.dart';
import 'package:krishi_link/src/features/product/presentation/controllers/product_controller.dart';
import 'package:krishi_link/features/farmer/controller/farmer_controller.dart';

/// Farmer dashboard binding
class FarmerBinding extends Bindings {
  @override
  void dependencies() {
    // Shared product controller with fenix recreation
    Get.lazyPut<ProductController>(() => ProductController(), fenix: true);

    // Farmer-specific controllers with fenix for recreation
    Get.lazyPut(() => FarmerController(), fenix: true);
  }
}
