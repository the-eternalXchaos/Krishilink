import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/lottie/pop_up.dart';
import 'package:lottie/lottie.dart';
import 'package:krishi_link/src/features/product/presentation/controllers/product_controller.dart';
import 'package:krishi_link/src/features/product/presentation/widgets/product_card.dart';
import 'package:krishi_link/src/core/components/material_ui/pop_up.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/src/core/constants/lottie_assets.dart';

class ProductGrid extends StatelessWidget {
  final ProductController controller;
  final List<dynamic>? products; // backward-compat (expects List<Product>)
  ProductGrid({super.key, ProductController? controller, this.products})
    : controller =
          controller ??
          (Get.isRegistered<ProductController>()
              ? Get.find<ProductController>()
              : throw Exception('ProductController must be initialized first'));

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final list =
          (products ??
                  (controller.filteredProducts.isNotEmpty
                      ? controller.filteredProducts
                      : controller.products))
              .cast<dynamic>();
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (list.isEmpty) {
        return RefreshIndicator(
          onRefresh: () async {
            try {
              await controller.fetchProducts();
            } catch (e) {
              PopupService.showSnackbar(
                type: PopupType.error,
                title: 'error'.tr,
                message: e.toString().trim(),
              );
            }
          },

          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lottie animation
                Lottie.asset(
                  LottieAssets.notAvailable,
                  height: 250,
                  repeat: true,
                ),
                const SizedBox(height: 16),
                Text(
                  'no products'.tr,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.fetchProducts(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('retry'.tr),
                      const SizedBox(width: 8),
                      const Icon(Icons.refresh),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
        ),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final p = list[i];
          return ProductCard(product: p);
        },
      );
    });
  }
}
