import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/utils/constants.dart';
import 'package:krishi_link/features/admin/models/cart_item.dart';
import 'package:krishi_link/features/admin/models/product_model.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/auth/controller/cart_controller.dart';
import 'package:krishi_link/features/buyer/controllers/wishlist_controller.dart';
import 'package:krishi_link/widgets/product_detail_page.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authController = Get.find<AuthController>();
    final cartController =
        Get.isRegistered<CartController>()
            ? Get.find<CartController>()
            : Get.put(CartController());
    final wishlistController =
        Get.isRegistered<WishlistController>()
            ? Get.find<WishlistController>()
            : Get.put(WishlistController());

    return GestureDetector(
      onTap: () => Get.to(() => ProductDetailPage(product: product)),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + Wishlist
            Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: product.image.isNotEmpty ? product.image : '',
                  height: Get.height * .15,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder:
                      (_, __) => Container(
                        height: 130,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  errorWidget:
                      (_, __, ___) => Image.asset(
                        plantPlaceholder,
                        fit: BoxFit.cover,
                        height: 130,
                      ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Obx(() {
                    final isWishlisted = wishlistController.isInWishlist(
                      product.id,
                    );
                    return GestureDetector(
                      onTap: () {
                        if (authController.isLoggedIn) {
                          wishlistController.toggleWishlist(product);
                        } else {
                          PopupService.info(
                            'please_login_to_add_to_wishlist'.tr,
                            title: 'login_required'.tr,
                          );
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                                  color: theme.colorScheme.surface.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          isWishlisted ? Icons.favorite : Icons.favorite_border,
                          color:
                              isWishlisted
                                  ? Colors.red
                                  : theme.colorScheme.onSurface,
                          size: 20,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),

            // Padding for details
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    product.distance != null
                        ? '${product.productName} (${product.distance!.toStringAsFixed(1)}km)'
                        : product.productName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Location Row
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.location ?? 'Unknown location',
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Price
                  Text(
                    '₹${product.rate}/kg',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Add to Cart Button - full width
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: Text('add_to_cart'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () {
                    if (authController.isLoggedIn) {
                      cartController.addToCart(
                        CartItem.fromProduct(product, quantity: 1),
                      );
                    } else {
                      PopupService.info(
                        'please_login_to_add_to_cart'.tr,
                        title: 'login_required'.tr,
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// extension on Type {
//   operator >(() other) {}
// }
