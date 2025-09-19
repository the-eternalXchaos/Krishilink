import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/features/auth/controller/cart_controller.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/src/core/constants/constants.dart';
import 'package:lottie/lottie.dart';
import 'package:krishi_link/features/buyer/screens/checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CartController cartController =
        Get.isRegistered()
            ? Get.find<CartController>()
            : Get.put(CartController());

    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('your_cart'.tr),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          Obx(
            () =>
                cartController.cartItems.isEmpty
                    ? const SizedBox()
                    : IconButton(
                      onPressed: () => cartController.clearCart(),
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                    ),
          ),
        ],
      ),
      body: Obx(() {
        if (cartController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (cartController.cartItems.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          itemCount: cartController.cartItems.length,
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, index) {
            final item = cartController.cartItems[index];
            return _CartItemCard(
              name: item.name,

              price: item.price,
              quantity: item.quantity,
              imageUrl:
                  '${ApiConstants.getProductImageEndpoint}/${item.id}?t=${DateTime.now().millisecondsSinceEpoch}',
              onRemove: () => cartController.removeFromCart(item.id),
              onQuantityChanged: (newQty) {
                if (newQty > 0) {
                  cartController.updateQuantity(item.id, newQty);
                }
              },
            );
          },
        );
      }),
      bottomNavigationBar: Obx(() {
        if (cartController.cartItems.isEmpty) return const SizedBox();
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${'total'.tr}: Rs ${cartController.totalPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Get.to(
                      () => CheckoutScreen(
                        items: cartController.cartItems,
                        isFromCart: true,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('checkout'.tr),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(AssetPaths.emptyCart, height: 200),
            const SizedBox(height: 16),
            Text(
              'your_cart_is_empty'.tr,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'start_adding_products'.tr,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Get.back(),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
              ),
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text('shop_now'.tr),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🛒 Custom cart item card with quantity stepper
class _CartItemCard extends StatelessWidget {
  final String name;
  final String price;
  final int quantity;
  final String imageUrl;
  final VoidCallback onRemove;
  final Function(int newQty) onQuantityChanged;

  const _CartItemCard({
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stack) => Image.asset(
                      AssetPaths.plantPlaceholder,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Rs $price",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => onQuantityChanged(quantity - 1),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$quantity'),
                    IconButton(
                      onPressed: () => onQuantityChanged(quantity + 1),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
