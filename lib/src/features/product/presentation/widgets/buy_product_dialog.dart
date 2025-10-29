import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/features/buyer/screens/checkout_screen.dart';
import 'package:krishi_link/src/features/cart/models/cart_item.dart';
import 'package:krishi_link/src/features/product/data/models/product_model.dart';
import 'package:krishi_link/widgets/safe_network_image.dart';

class BuyProductDialog extends StatefulWidget {
  final Product product;

  const BuyProductDialog({super.key, required this.product});

  @override
  State<BuyProductDialog> createState() => _BuyProductDialogState();
}

class _BuyProductDialogState extends State<BuyProductDialog> {
  int quantity = 1;

  void _incrementQuantity() {
    if (quantity < widget.product.availableQuantity) {
      setState(() => quantity++);
    }
  }

  void _decrementQuantity() {
    if (quantity > 1) {
      setState(() => quantity--);
    }
  }

  void _proceedToCheckout() {
    // Create a CartItem from the product with selected quantity
    final cartItem = CartItem.fromProduct(widget.product, quantity: quantity);

    // Close bottom sheet
    Navigator.pop(context);

    // Navigate to checkout with this single item
    Get.to(() => CheckoutScreen(singleItem: cartItem, isFromCart: false));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final totalPrice = widget.product.rate * quantity;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'buy_now'.tr,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Product Info Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SafeNetworkImage(
                    imageUrl: widget.product.image,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),

                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.productName,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rs. ${widget.product.rate.toStringAsFixed(2)} / ${widget.product.unit}',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${'available'.tr}: ${widget.product.availableQuantity.toStringAsFixed(0)} ${widget.product.unit}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quantity Control
          Text(
            'quantity'.tr,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Decrement Button
              IconButton(
                onPressed: quantity > 1 ? _decrementQuantity : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: colorScheme.primary,
                iconSize: 32,
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.primaryContainer.withOpacity(
                    0.5,
                  ),
                  disabledBackgroundColor: colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(width: 16),

              // Quantity Display
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  quantity.toString(),
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Increment Button
              IconButton(
                onPressed:
                    quantity < widget.product.availableQuantity
                        ? _incrementQuantity
                        : null,
                icon: const Icon(Icons.add_circle_outline),
                color: colorScheme.primary,
                iconSize: 32,
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.primaryContainer.withOpacity(
                    0.5,
                  ),
                  disabledBackgroundColor: colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Total Price
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'total_price'.tr,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Rs. ${totalPrice.toStringAsFixed(2)}',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              // Cancel Button
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: colorScheme.outline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'cancel'.tr,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Checkout Button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _proceedToCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: Expanded(
                    child: Text(
                      'proceed_to_checkout'.tr,
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
