import 'package:get/get.dart';
import 'package:krishi_link/src/features/payment/presentation/controllers/direct_payment_controller.dart';

/// Payment page binding
class PaymentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DirectPaymentController(), fenix: true);
  }
}
