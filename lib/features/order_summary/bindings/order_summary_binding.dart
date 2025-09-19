import 'package:get/get.dart';
import 'package:krishi_link/features/order_summary/controllers/order_summary_controller.dart';

class OrderSummaryBinding extends Bindings {
  @override
  void dependencies() {
    // Lazy singleton with fenix; recreated if disposed after navigation
    Get.lazyPut<OrderSummaryController>(
      () => OrderSummaryController(),
      fenix: true,
    );
  }
}
