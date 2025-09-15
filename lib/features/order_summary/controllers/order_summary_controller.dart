import 'package:get/get.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';

class OrderSummaryController extends GetxController {
  final loading = false.obs;
  final error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final auth =
        Get.isRegistered<AuthController>()
            ? Get.find<AuthController>()
            : Get.put(AuthController(), permanent: true);

    if (!auth.isLoggedIn) {
      // Guest-safe: skip secure calls
      return;
    }
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      loading.value = true;
      // TODO: call secure API(s) to load order summary
      await Future.delayed(const Duration(milliseconds: 400));
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }
}
