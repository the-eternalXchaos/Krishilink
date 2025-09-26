import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/src/features/order/controllers/order_summary_controller.dart';

class OrderSummaryPage extends StatelessWidget {
  const OrderSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth =
        Get.isRegistered<AuthController>()
            ? Get.find<AuthController>()
            : Get.put(AuthController(), permanent: true);
    final ctrl = Get.find<OrderSummaryController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Order Summary')),
      body: Obx(() {
        if (!auth.isLoggedIn) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 56),
                const SizedBox(height: 12),
                const Text('Login to view your order summary.'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Get.toNamed('/login'),
                  child: const Text('Login'),
                ),
              ],
            ),
          );
        }
        if (ctrl.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (ctrl.error.isNotEmpty) {
          return Center(child: Text('Error: ${ctrl.error.value}'));
        }
        return const Center(child: Text('Your order details appear here.'));
      }),
    );
  }
}
