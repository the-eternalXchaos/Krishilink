import 'package:get/get.dart';
import 'package:krishi_link/features/order_summary/controllers/order_summary_controller.dart';

class OrderSummaryBinding extends Bindings {
  @override
  void dependencies() {
    // Ephemeral: destroyed when page is popped
    Get.create<OrderSummaryController>(() => OrderSummaryController());
  }
}
