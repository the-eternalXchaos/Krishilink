// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:krishi_link/controllers/product_controller.dart';
// import 'package:krishi_link/core/utils/constants.dart';
// export 'package:krishi_link/src/features/cart/models/cart_item.dart';
// import 'package:krishi_link/features/admin/models/product_model.dart';
// import 'package:krishi_link/features/auth/controller/auth_controller.dart';
// import 'package:krishi_link/features/auth/controller/cart_controller.dart';
// import 'package:krishi_link/features/buyer/controllers/wishlist_controller.dart';
// import 'package:krishi_link/src/features/chat/presentation/controllers/live_chat_controller.dart';
// import 'package:krishi_link/widgets/product_detail_page.dart';
// import 'package:krishi_link/core/lottie/popup_service.dart';

// class ProductCard extends StatelessWidget {
//   final Product product;

//   const ProductCard({super.key, required this.product});

//   @override
//   Widget build(BuildContext context) {
//     final authController =
//         Get.isRegistered<AuthController>()
//             ? Get.find<AuthController>()
//             : Get.put(AuthController());

//     final liveChatController =
//         Get.isRegistered<LiveChatController>()
//             ? Get.find<LiveChatController>()
//             : Get.put(
//               LiveChatController(
//                 productId: product.id,
//                 productName: product.productName,
//                 farmerName: product.farmerName.toString(),
//                 emailOrPhone: product.farmerPhone.toString(),
//               ),
//             );
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       liveChatController.fetchFarmerLiveStatus(product.id);
//     });
//     final theme = Theme.of(context);
//     final cartController =
//         Get.isRegistered<CartController>()
//             ? Get.find<CartController>()
//             : Get.put(CartController());
//     final wishlistController =
//         Get.isRegistered<WishlistController>()
//             ? Get.find<WishlistController>()
//             : Get.put(WishlistController());

//     return GestureDetector(
//       onTap: () {
//         Get.to(() => ProductDetailPage(product: product));
//         debugPrint('productid: ${product.id}');
//       },
//       child: Card(
//         elevation: 8,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         clipBehavior: Clip.antiAlias,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Image + Wishlist
//             Stack(
//               children: [
//                 CachedNetworkImage(
//                   imageUrl: product.image.isNotEmpty ? product.image : '',
//                   height: Get.height * .15,
//                   width: double.infinity,
//                   fit: BoxFit.cover,
//                   placeholder:
//                       (_, _) => Container(
//                         height: 130,
//                         color: theme.colorScheme.surfaceContainerHighest,
//                         child: const Center(child: CircularProgressIndicator()),
//                       ),
//                   errorWidget:
//                       (_, _, _) => Image.asset(
//                         plantPlaceholder,
//                         fit: BoxFit.cover,
//                         height: 130,
//                       ),
//                 ),
//                 Positioned(
//                   top: 8,
//                   right: 8,
//                   child: Obx(() {
//                     final isWishlisted = wishlistController.isInWishlist(
//                       product.id,
//                     );
//                     return GestureDetector(
//                       onTap: () {
//                         if (authController.isLoggedIn) {
//                           wishlistController.toggleWishlist(product);
//                         } else {
//                           PopupService.info(
//                             'please_login_to_add_to_wishlist'.tr,
//                             title: 'login_required'.tr,
//                           );
//                         }
//                       },
//                       child: Container(
//                         decoration: BoxDecoration(
//                           color: theme.colorScheme.surface.withValues(
//                             alpha: 0.9,
//                           ),
//                           shape: BoxShape.circle,
//                         ),
//                         padding: const EdgeInsets.all(6),
//                         child: Icon(
//                           isWishlisted ? Icons.favorite : Icons.favorite_border,
//                           color:
//                               isWishlisted
//                                   ? Colors.red
//                                   : theme.colorScheme.onSurface,
//                           size: 20,
//                         ),
//                       ),
//                     );
//                   }),
//                 ),
//               ],
//             ),

//             // Padding for details
//             Padding(
//               padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Product Name
//                   Row(
//                     children: [
//                       // showing farmer active status isFarmerLiveEndpoint  api/Chat/IsFarmerLive'
//                       Expanded(
//                         child: Text(
//                           product.distance != null
//                               ? '${product.productName} (${product.distance!.toStringAsFixed(1)}km)'
//                               : product.productName,
//                           style: theme.textTheme.titleMedium?.copyWith(
//                             fontWeight: FontWeight.bold,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                       Obx(() {
//                         final isLive = liveChatController.isFarmerLive(
//                           product.id,
//                         );
//                         return Container(
//                           width: 10,
//                           height: 10,
//                           decoration: BoxDecoration(
//                             color: isLive ? Colors.green : Colors.red,
//                             shape: BoxShape.circle,
//                           ),
//                         );
//                       }),
//                     ],
//                   ),

//                   const SizedBox(height: 4),

//                   // Location Row
//                   Row(
//                     children: [
//                       Icon(
//                         Icons.location_on,
//                         size: 14,
//                         color: theme.colorScheme.secondary,
//                       ),
//                       const SizedBox(width: 4),
//                       Expanded(
//                         child: Text(
//                           product.location ?? 'Unknown location',
//                           style: theme.textTheme.bodySmall,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 6),

//                   // Price
//                   Text(
//                     '₹${product.rate}/kg',
//                     style: theme.textTheme.bodyMedium?.copyWith(
//                       color: theme.colorScheme.primary,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             // Add to Cart Button - full width
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               child: SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton.icon(
//                   icon: const Icon(Icons.add_shopping_cart, size: 18),
//                   label: Text('add_to_cart'.tr),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: theme.primaryColor,
//                     foregroundColor: theme.colorScheme.onPrimary,
//                     padding: const EdgeInsets.symmetric(vertical: 10),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     elevation: 2,
//                   ),
//                   onPressed: () {
//                     if (authController.isLoggedIn) {
//                       cartController.addToCart(
//                         CartItem.fromProduct(product, quantity: 1),
//                       );
//                     } else {
//                       PopupService.info(
//                         'please_login_to_add_to_cart'.tr,
//                         title: 'login_required'.tr,
//                       );
//                     }
//                   },
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // extension on Type {
// //   operator >(() other) {}
// // }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/auth/controller/cart_controller.dart';
import 'package:krishi_link/features/buyer/controllers/wishlist_controller.dart';
import 'package:krishi_link/features/product/screens/product_detail_page.dart';
import 'package:krishi_link/src/core/constants/constants.dart';
import 'package:krishi_link/src/features/cart/models/cart_item.dart';
import 'package:krishi_link/src/features/chat/presentation/controllers/live_chat_controller.dart';
import 'package:krishi_link/src/features/product/data/models/product_model.dart';
import 'package:krishi_link/widgets/safe_network_image.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final bool isGridView;
  final double? cardWidth;

  const ProductCard({
    super.key,
    required this.product,
    this.isGridView = true,
    this.cardWidth,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isPressed = false;
  bool _isControllerDisposed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _isControllerDisposed = true;
    try {
      _animationController.dispose();
    } catch (e) {
      // Controller might already be disposed, ignore error
      debugPrint('Animation controller dispose failed: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);

    // Responsive dimensions
    final cardHeight = _getCardHeight(size);
    final imageHeight = _getImageHeight(size);
    final isSmallScreen = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1200;

    // Initialize live chat controller
    final liveChatController = _getOrPutLiveChatController();

    // Fetch farmer live status after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      liveChatController.fetchFarmerLiveStatus(widget.product.id);
    });

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: GestureDetector(
              onTapDown: (_) => _onTapDown(),
              onTapUp: (_) => _onTapUp(),
              onTapCancel: _onTapCancel,
              onTap: () => _navigateToDetail(),
              child: SizedBox(
                width: widget.cardWidth,
                height: widget.isGridView ? cardHeight : null,
                child: Card(
                  elevation: _isPressed ? 2 : 8,
                  shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child:
                      widget.isGridView
                          ? _buildGridCard(theme, imageHeight, isSmallScreen)
                          : _buildListCard(theme, imageHeight, isTablet),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridCard(
    ThemeData theme,
    double imageHeight,
    bool isSmallScreen,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImageSection(theme, imageHeight),
        Expanded(
          child: _buildContentSection(theme, isSmallScreen: isSmallScreen),
        ),
      ],
    );
  }

  Widget _buildListCard(ThemeData theme, double imageHeight, bool isTablet) {
    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: imageHeight * 1.2,
            child: _buildImageSection(theme, imageHeight),
          ),
          Expanded(
            child: _buildContentSection(
              theme,
              isHorizontal: true,
              isTablet: isTablet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(ThemeData theme, double imageHeight) {
    return Stack(
      children: [
        Hero(
          tag: 'product-${widget.product.id}',
          child: SafeNetworkImage(
            imageUrl: widget.product.image,
            height: imageHeight,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: _buildImagePlaceholder(theme, imageHeight),
            errorWidget: _buildErrorImage(imageHeight),
          ),
        ),
        _buildImageOverlay(theme),
        _buildWishlistButton(theme),
        _buildLiveIndicator(),
        if (widget.product.distance != null) _buildDistanceBadge(theme),
      ],
    );
  }

  Widget _buildImagePlaceholder(ThemeData theme, double imageHeight) {
    return Container(
      height: imageHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surfaceContainerHighest,
            theme.colorScheme.surfaceContainer,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
            const SizedBox(height: 8),
            Text(
              'loading'.tr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorImage(double imageHeight) {
    return Container(
      height: imageHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey.shade200, Colors.grey.shade100],
        ),
      ),
      child: Image.asset(AssetPaths.plantPlaceholder, fit: BoxFit.cover),
    );
  }

  Widget _buildImageOverlay(ThemeData theme) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.1)],
          ),
        ),
      ),
    );
  }

  Widget _buildWishlistButton(ThemeData theme) {
    final wishlistController =
        Get.isRegistered<WishlistController>()
            ? Get.find<WishlistController>()
            : Get.put(WishlistController());

    return Positioned(
      top: 12,
      right: 12,
      child: Obx(() {
        final isWishlisted = wishlistController.isInWishlist(widget.product.id);
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          tween: Tween(begin: 0.0, end: isWishlisted ? 1.0 : 0.0),
          builder: (context, value, child) {
            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.95),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _handleWishlistTap(),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isWishlisted ? Icons.favorite : Icons.favorite_border,
                        key: ValueKey(isWishlisted),
                        color:
                            isWishlisted
                                ? Colors.red
                                : theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildLiveIndicator() {
    try {
      final liveChatController = Get.find<LiveChatController>();

      return Positioned(
        top: 12,
        left: 12,
        child: Obx(() {
          final isLive = liveChatController.isFarmerLive(widget.product.id);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isLive ? Colors.green : Colors.grey.shade600,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (isLive ? Colors.green : Colors.grey.shade600)
                      .withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  isLive ? 'live'.tr : 'offline'.tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }),
      );
    } catch (e) {
      // LiveChatController not found, return empty container
      return const SizedBox.shrink();
    }
  }

  Widget _buildDistanceBadge(ThemeData theme) {
    return Positioned(
      bottom: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          '${widget.product.distance!.toStringAsFixed(1)}km',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildContentSection(
    ThemeData theme, {
    bool isSmallScreen = false,
    bool isHorizontal = false,
    bool isTablet = false,
  }) {
    return Padding(
      padding: EdgeInsets.all(isHorizontal ? 16 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildProductHeader(theme, isSmallScreen),
          SizedBox(height: isSmallScreen ? 6 : 8),
          _buildLocationRow(theme, isSmallScreen),
          SizedBox(height: isSmallScreen ? 6 : 8),
          _buildPriceSection(theme, isSmallScreen),
          if (!isHorizontal) ...[
            const Spacer(),
            _buildAddToCartButton(theme, isSmallScreen),
          ] else ...[
            SizedBox(height: isTablet ? 12 : 16),
            _buildAddToCartButton(theme, isSmallScreen, isHorizontal: true),
          ],
        ],
      ),
    );
  }

  Widget _buildProductHeader(ThemeData theme, bool isSmallScreen) {
    return Text(
      widget.product.productName,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: isSmallScreen ? 14 : 16,
        height: 1.2,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildLocationRow(ThemeData theme, bool isSmallScreen) {
    return Row(
      children: [
        Icon(
          Icons.location_on_rounded,
          size: isSmallScreen ? 14 : 16,
          color: theme.colorScheme.primary.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            widget.product.location ?? 'unknown_location'.tr,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: isSmallScreen ? 11 : 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection(ThemeData theme, bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        '₹${widget.product.rate}/kg',
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          fontSize: isSmallScreen ? 13 : 15,
        ),
      ),
    );
  }

  Widget _buildAddToCartButton(
    ThemeData theme,
    bool isSmallScreen, {
    bool isHorizontal = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: isSmallScreen ? 36 : 42,
      child: ElevatedButton.icon(
        icon: Icon(
          Icons.add_shopping_cart_rounded,
          size: isSmallScreen ? 16 : 18,
        ),
        label: Text(
          'add_to_cart'.tr,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          shadowColor: theme.colorScheme.primary.withValues(alpha: 0.3),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.pressed)) {
              return theme.colorScheme.onPrimary.withValues(alpha: 0.1);
            }
            if (states.contains(WidgetState.hovered)) {
              return theme.colorScheme.onPrimary.withValues(alpha: 0.05);
            }
            return null;
          }),
        ),
        onPressed: () => _handleAddToCart(),
      ),
    );
  }

  // Helper methods
  LiveChatController _getOrPutLiveChatController() {
    return Get.isRegistered<LiveChatController>()
        ? Get.find<LiveChatController>()
        : Get.put(
          LiveChatController(
            productId: widget.product.id,
            productName: widget.product.productName,
            farmerName: widget.product.farmerName.toString(),
            emailOrPhone: widget.product.farmerPhone.toString(),
          ),
        );
  }

  double _getCardHeight(Size size) {
    if (size.width < 400) return 280; // Small phones
    if (size.width < 600) return 300; // Regular phones
    if (size.width < 1200) return 320; // Tablets
    return 340; // Large tablets/desktop
  }

  double _getImageHeight(Size size) {
    if (widget.isGridView) {
      if (size.width < 400) return size.height * 0.12; // Small phones
      if (size.width < 600) return size.height * 0.14; // Regular phones
      return size.height * 0.15; // Tablets and larger
    } else {
      // List view
      return size.width < 600 ? 100 : 120;
    }
  }

  // Event handlers
  void _onTapDown() {
    if (!mounted || _isControllerDisposed) return;
    setState(() => _isPressed = true);
    if (!_isControllerDisposed && mounted) {
      try {
        _animationController.forward();
      } catch (e) {
        // Animation controller might be disposed, ignore error
        debugPrint('Animation controller forward failed: $e');
      }
    }
  }

  void _onTapUp() {
    if (!mounted || _isControllerDisposed) return;
    setState(() => _isPressed = false);
    if (!_isControllerDisposed && mounted) {
      try {
        _animationController.reverse();
      } catch (e) {
        // Animation controller might be disposed, ignore error
        debugPrint('Animation controller reverse failed: $e');
      }
    }
  }

  void _onTapCancel() {
    if (!mounted || _isControllerDisposed) return;
    setState(() => _isPressed = false);
    if (!_isControllerDisposed && mounted) {
      try {
        _animationController.reverse();
      } catch (e) {
        // Animation controller might be disposed, ignore error
        debugPrint('Animation controller reverse failed: $e');
      }
    }
  }

  void _navigateToDetail() {
    Get.to(
      () => ProductDetailPage(product: widget.product),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 300),
    );
    debugPrint('productid: ${widget.product.id}');
  }

  void _handleWishlistTap() {
    final authController =
        Get.isRegistered<AuthController>()
            ? Get.find<AuthController>()
            : Get.put(AuthController());
    final wishlistController =
        Get.isRegistered<WishlistController>()
            ? Get.find<WishlistController>()
            : Get.put(WishlistController());

    if (authController.isLoggedIn) {
      wishlistController.toggleWishlist(widget.product);

      // Haptic feedback
      // HapticFeedback.lightImpact(); // Uncomment if you want haptic feedback
    } else {
      PopupService.info(
        'please_login_to_add_to_wishlist'.tr,
        title: 'login_required'.tr,
      );
    }
  }

  void _handleAddToCart() {
    final authController =
        Get.isRegistered<AuthController>()
            ? Get.find<AuthController>()
            : Get.put(AuthController());
    final cartController =
        Get.isRegistered<CartController>()
            ? Get.find<CartController>()
            : Get.put(CartController());

    if (authController.isLoggedIn) {
      cartController.addToCart(
        CartItem.fromProduct(widget.product, quantity: 1),
      );

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'added_to_cart'.tr}: ${widget.product.productName}'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      PopupService.info(
        'please_login_to_add_to_cart'.tr,
        title: 'login_required'.tr,
      );
    }
  }
}
