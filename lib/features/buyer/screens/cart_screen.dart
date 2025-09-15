import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/utils/api_constants.dart';
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
    debugPrint('🛒 [CartScreen] 🖼️ Building CartScreen widget...');

    final CartController cartController =
        Get.isRegistered()
            ? Get.find<CartController>()
            : Get.put(CartController());
    debugPrint(
      '🛒 [CartScreen] ✅ CartController obtained: ${cartController.runtimeType}',
    );

    // final WishlistController wishlistController =
    //     Get.isRegistered()
    //         ? Get.find<WishlistController>()
    //         : Get.put(WishlistController());
    debugPrint('🛒 [CartScreen] ✅ WishlistController obtained');

    final AuthController authController = Get.find<AuthController>();
    debugPrint(
      '🛒 [CartScreen] ✅ AuthController obtained - User logged in: ${authController.isLoggedIn}',
    );
    debugPrint(
      '🛒 [CartScreen] 🛍️ Current cart items: ${cartController.cartItems.length}',
    );

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
        debugPrint(
          '🛒 [CartScreen] 🔄 Obx rebuilding - Cart items count: ${cartItems.length}',
        );
        debugPrint(
          '🛒 [CartScreen] 📊 Loading state: ${cartController.isLoading.value}',
        );
        debugPrint(
          '🛒 [CartScreen] 💰 Total price: ₹${cartController.totalPrice}',
        );

        if (cartController.isLoading.value) {
          debugPrint('🛒 [CartScreen] ⏳ Showing loading indicator');
          return const Center(child: CircularProgressIndicator());
        }

        if (cartItems.isEmpty) {
          debugPrint('🛒 [CartScreen] 📭 Cart is empty, showing empty state');
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

        debugPrint(
          '🛒 [CartScreen] 🛍️ Showing cart with ${cartItems.length} items',
        );
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: cartItems.length,
                padding: const EdgeInsets.all(12),
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  debugPrint(
                    '🛒 [CartScreen] 📋 Building item $index: ${item.name}',
                  );
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Builder(
                        builder: (context) {
                          debugPrint(
                            '🛒 [CartScreen] 🖼️ Original Image URL for ${item.name}: "${item.imageUrl}"',
                          );
                          debugPrint(
                            '🛒 [CartScreen] 🖼️ Image URL isEmpty: ${item.imageUrl.isEmpty}',
                          );

                          // Construct proper image URL using the API endpoint and product ID
                          final constructedImageUrl =
                              '${ApiConstants.getProductImageEndpoint}/${item.id}';
                          debugPrint(
                            '🛒 [CartScreen] 🔧 Constructed image URL: "$constructedImageUrl"',
                          );

                          if (item.imageUrl.isEmpty) {
                            debugPrint(
                              '🛒 [CartScreen] 🖼️ Using placeholder image for ${item.name}',
                            );
                            return Image.asset(
                              plantPlaceholder,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            );
                          } else {
                            // Always construct the image URL using the API endpoint and product ID
                            // This ensures we use the correct endpoint regardless of what's stored in imageUrl
                            final imageUrl =
                                '${ApiConstants.getProductImageEndpoint}/${item.id}?t=${DateTime.now().millisecondsSinceEpoch}';

                            debugPrint(
                              '🛒 [CartScreen] 🔧 Using constructed image URL: "$imageUrl"',
                            );
                            debugPrint(
                              '🛒 [CartScreen] 🌐 Loading image for ${item.name} using product ID: ${item.id}',
                            );
                            return Image.network(
                              imageUrl,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) {
                                  debugPrint(
                                    '🛒 [CartScreen] ✅ Image loaded successfully for ${item.name}',
                                  );
                                  return child;
                                }
                                debugPrint(
                                  '🛒 [CartScreen] ⏳ Loading image for ${item.name}: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes ?? 'unknown'}',
                                );
                                return Container(
                                  width: 48,
                                  height: 48,
                                  alignment: Alignment.center,
                                  child: CircularProgressIndicator(
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint(
                                  '🛒 [CartScreen] ❌ Image failed to load for ${item.name}: $error',
                                );
                                debugPrint(
                                  '🛒 [CartScreen] 🔄 Falling back to placeholder',
                                );
                                return Image.asset(
                                  plantPlaceholder,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                );
                              },
                            );
                          }
                        },
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
