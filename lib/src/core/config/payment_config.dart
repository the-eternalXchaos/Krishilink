/// Minimal placeholder for PaymentConfig referenced in legacy code.
/// TODO: Implement real navigation / post-payment behaviour.
library;

import 'package:get/get.dart';

/// Basic navigation strategy after successful payment (can be expanded later)
class PaymentConfig {
  static void navigateAfterSuccess() {
    if (Get.currentRoute != '/buyer-dashboard') {
      Get.offAllNamed('/buyer-dashboard');
    }
  }
}
