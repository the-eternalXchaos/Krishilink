import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/features/cart/models/cart_item.dart';
import 'package:krishi_link/features/auth/controller/cart_controller.dart';
import 'package:krishi_link/features/buyer/controllers/wishlist_controller.dart';
import 'package:krishi_link/src/core/constants/constants.dart';
import 'package:lottie/lottie.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final WishlistController wishlistController =
        Get.isRegistered<WishlistController>()
            ? Get.find<WishlistController>()
            : Get.put(WishlistController());
    final CartController cartController =
        Get.isRegistered<CartController>()
            ? Get.find<CartController>()
            : Get.put(CartController());
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('wishlist'.tr),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          Obx(
            () =>
                wishlistController.wishlistItems.isNotEmpty
                    ? IconButton(
                      icon: const Icon(Icons.clear_all),
                      onPressed:
                          () => _showClearWishlistDialog(
                            context,
                            wishlistController,
                          ),
                    )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Obx(() {
        final wishlistItems = wishlistController.wishlistItems;

        if (wishlistItems.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    AssetPaths
                        .emptyCart, // You can create a separate wishlist animation
                    height: 200,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'your_wishlist_is_empty'.tr,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'add_products_to_wishlist'.tr,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text('explore_products'.tr),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: wishlistItems.length,
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, index) {
            final item = wishlistItems[index];
            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Product Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child:
                          item.imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                imageUrl: item.imageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Container(
                                      width: 80,
                                      height: 80,
                                      color: colorScheme.surface,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: colorScheme.primary,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: colorScheme.surface,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.5,
                                        ),
                                        size: 30,
                                      ),
                                    ),
                              )
                              : Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                  size: 30,
                                ),
                              ),
                    ),
                    const SizedBox(width: 12),
                    // Product Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'price_per_kg'.trParams({'price': item.price}),
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: colorScheme.secondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.location,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'farmer_name'.trParams({'name': item.farmerName}),
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Action Buttons
                    Column(
                      children: [
                        // Add to Cart Button
                        IconButton(
                          icon: Icon(
                            Icons.add_shopping_cart,
                            color: colorScheme.primary,
                          ),
                          onPressed: () {
                            // Convert wishlist item to cart item
                            final cartItem = CartItem(
                              id: item.id,
                              name: item.name,
                              price: item.price,
                              quantity: 1,
                              productId: item.id,
                              image: item.imageUrl,
                            );
                            cartController.addToCart(cartItem);
                          },
                        ),
                        // Remove from Wishlist Button
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: colorScheme.error,
                          ),
                          onPressed:
                              () => wishlistController.removeFromWishlist(
                                item.id,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _showClearWishlistDialog(
    BuildContext context,
    WishlistController controller,
  ) {
    Get.dialog(
      AlertDialog(
        title: Text('clear_wishlist'.tr),
        content: Text('are_you_sure_clear_wishlist'.tr),
        actions: [
          TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.clearWishlist();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text('clear'.tr),
          ),
        ],
      ),
    );
  }
}
