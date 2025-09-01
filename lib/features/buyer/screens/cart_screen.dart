import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/utils/constants.dart';
import 'package:krishi_link/features/auth/controller/cart_controller.dart';
import 'package:krishi_link/features/buyer/controllers/wishlist_controller.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
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
    final WishlistController wishlistController =
        Get.isRegistered()
            ? Get.find<WishlistController>()
            : Get.put(WishlistController());
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      // silverbar
      // silverappbar
      appBar: AppBar(
        title: Text('your_cart'.tr),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            onPressed: () => cartController.clearCart(),
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
      body: Obx(() {
        final cartItems = cartController.cartItems;

        if (cartItems.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(emptyCart),
                  const SizedBox(height: 16),
                  Text(
                    'your_cart_is_empty'.tr,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'start_adding_products'.tr,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text('shop_now'.tr),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: cartItems.length,
                padding: const EdgeInsets.all(12),
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading:
                          item.imageUrl.isEmpty
                              ? Image.asset(
                                plantPlaceholder,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              )
                              : Image.network(
                                item.imageUrl,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => Image.asset(
                                      plantPlaceholder,
                                      fit: BoxFit.cover,
                                    ),
                              ),
                      title: Text(item.name),
                      subtitle: Text('₹${item.price} x ${item.quantity}'),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => cartController.removeFromCart(item.id),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Obx(() {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${'total'.tr}: RS ${cartController.totalPrice.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed:
                                  cartController.cartItems.isEmpty
                                      ? null
                                      : () {
                                        Get.to(
                                          () => CheckoutScreen(
                                            items: cartController.cartItems,
                                            isFromCart: true,
                                          ),
                                        );
                                      },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              child: Text('checkout'.tr),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ),
          ],
        );
      }),
    );
  }
}
