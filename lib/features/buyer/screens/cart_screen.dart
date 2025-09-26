import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/lottie/pop_up.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/core/utils/api_constants.dart';
export 'package:krishi_link/src/features/cart/models/cart_item.dart';
import 'package:krishi_link/src/features/product/data/models/product_model.dart';
import 'package:krishi_link/features/auth/controller/cart_controller.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/product/screens/product_detail_page.dart';
import 'package:krishi_link/src/core/components/confirm%20box/custom_confirm_dialog.dart';
import 'package:krishi_link/src/core/components/material_ui/pop_up.dart';
import 'package:krishi_link/src/core/constants/constants.dart';
import 'package:krishi_link/src/features/cart/models/cart_item.dart';
import 'package:krishi_link/widgets/safe_network_image.dart';
import 'package:lottie/lottie.dart';
import 'package:krishi_link/features/buyer/screens/checkout_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.put(CartController());
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text('${('your_cart'.tr)} (${cartController.totalItems})'),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          Obx(
            () =>
                cartController.cartItems.isEmpty
                    ? const SizedBox()
                    : PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'clear') {
                          _showClearCartDialog(context, cartController);
                        }
                      },
                      itemBuilder:
                          (context) => [
                            PopupMenuItem(
                              value: 'clear',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.delete_forever,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Text('clear_cart'.tr),
                                ],
                              ),
                            ),
                          ],
                    ),
          ),
        ],
      ),
      body: Obx(() {
        if (cartController.isLoading.value &&
            cartController.cartItems.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading cart...'),
              ],
            ),
          );
        }

        if (cartController.cartItems.isEmpty) {
          return _buildEmptyState(context);
        }

        return RefreshIndicator(
          onRefresh: () => cartController.fetchCartItems(),
          child: ListView.builder(
            itemCount: cartController.cartItems.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final item = cartController.cartItems[index];
              return _CartItemCard(
                key: ValueKey(item.id),
                item: item,
                cartController: cartController,
              );
            },
          ),
        );
      }),
      bottomNavigationBar: Obx(() {
        if (cartController.cartItems.isEmpty) return const SizedBox();

        return _buildBottomCheckoutBar(context, cartController);
      }),
    );
  }

  Widget _buildBottomCheckoutBar(
    BuildContext context,
    CartController cartController,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Order summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${'items'.tr}: ${cartController.totalItems}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${'total'.tr}: Rs ${cartController.totalPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Checkout button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    cartController.isLoading.value
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
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.shopping_cart_checkout),
                label: Text(
                  'proceed_to_checkout'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              AssetPaths.emptyCart,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            Text(
              'your_cart_is_empty'.tr,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'start_adding_products_description'.tr,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => Get.back(),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
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

  void _showClearCartDialog(
    BuildContext context,
    CartController cartController,
  ) {
    String title = 'clear_cart'.tr;
    String content = 'clear_cart_confirmation'.tr;
    String confirmText = 'clear'.tr;
    String cancelText = 'cancel'.tr;

    void onConfirm() {
      Get.back();
      cartController.clearCart();
    }

    void onCancel() {
      Get.back();
    }

    showDialog(
      context: context,
      builder:
          (context) => CustomConfirmDialog(
            title: title,
            content: content,
            confirmText: confirmText,
            cancelText: cancelText,
            onConfirm: onConfirm,
            onCancel: onCancel,
          ),
    );
  }
}

/// Enhanced cart item card with better image handling and UX
class _CartItemCard extends StatefulWidget {
  final CartItem item;
  final CartController cartController;

  const _CartItemCard({
    super.key,
    required this.item,
    required this.cartController,
  });

  @override
  State<_CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<_CartItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  Widget _buildQuantityButton({
    required IconData icon,
    Color? color,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onPressed,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color:
                onPressed != null
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color:
                onPressed != null
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).disabledColor,
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: FadeTransition(
        opacity: _slideAnimation,
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildProductImage(),
                const SizedBox(width: 12),
                Expanded(child: _buildProductInfo()),
                _buildQuantityControls(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return Hero(
      tag: 'cart_item_${widget.item.id}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            children: [
              SafeNetworkImage(imageUrl: widget.item.image),
              Obx(
                () =>
                    widget.cartController.isImageLoading[widget.item.id] == true
                        ? Container(
                          color: Colors.black26,
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          ),
                        )
                        : const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.item.name,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          "Rs ${widget.item.price}",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'subtotal_rs'.trParams({
            'amount': (double.parse(widget.item.price) * widget.item.quantity)
                .toStringAsFixed(2),
          }),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).textTheme.bodySmall?.color?.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityControls() {
    return Obx(() {
      final isLoading = widget.cartController.isLoading.value;
      return Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildQuantityButton(
                  icon: Icons.remove,
                  onPressed:
                      isLoading
                          ? null
                          : () {
                            widget.cartController.removeFromCart(
                              widget.item.productId,
                            );
                          },
                ),
                Container(
                  width: 50,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child:
                      isLoading
                          ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                          : Text(
                            '${widget.item.quantity}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                ),
                _buildQuantityButton(
                  icon: Icons.add,
                  color: Colors.white,

                  onPressed:
                      isLoading
                          ? null
                          : () {
                            if (widget.item.quantity >= 20) {
                              PopupService.showSnackbar(
                                type: PopupType.error,
                                title: 'maximum_quantity_reached'.tr,
                                message: 'you_can_only_add_up_to_20_items'.tr,
                                position: SnackPosition.BOTTOM,
                              );
                              return;
                            }
                            if (widget.item.product != null) {
                              widget.cartController.addProductWithReference(
                                widget.item.product!,
                              );
                            } else {
                              widget.cartController.addProductToCart(
                                widget.item.productId,
                              );
                            }
                          },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Remove button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showRemoveDialog(),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.red.shade400,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  void _showRemoveDialog() {
    String title = 'remove_item'.tr;
    String content = 'remove_item_confirmation'.trParams({
      'item': widget.item.name,
    });
    String confirmText = 'remove'.tr;
    String cancelText = 'cancel'.tr;

    void onConfirm() {
      Get.back();
      _animateRemoval();
    }

    void onCancel() {
      Get.back();
    }

    showDialog(
      context: context,
      builder:
          (context) => CustomConfirmDialog(
            title: title,
            content: content,
            confirmText: confirmText,
            cancelText: cancelText,
            onConfirm: onConfirm,
            onCancel: onCancel,
          ),
    );
  }

  void _animateRemoval() {
    _animationController.reverse().then((_) {
      widget.cartController.removeFromCart(widget.item.productId);
    });
  }

  // animate add use paxi garni
  void _animateAddition() {
    _animationController.forward(from: 0).then((_) {
      widget.cartController.addProductToCart(widget.item.productId);
    });
  }
}
