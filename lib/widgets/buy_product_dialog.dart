import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/features/admin/models/cart_item.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/auth/controller/cart_controller.dart';
import 'package:krishi_link/features/buyer/screens/checkout_screen.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';

class BuyProductDialog extends StatefulWidget {
  final List<CartItem>? cartItems;
  final CartItem? singleItem;

  BuyProductDialog({super.key, this.cartItems, this.singleItem})
    : assert(cartItems != null || singleItem != null);

  @override
  State<BuyProductDialog> createState() => _BuyProductDialogState();
}

class _BuyProductDialogState extends State<BuyProductDialog> {
  final RxMap<String, int> quantities = <String, int>{}.obs;

  late final AuthController authController = Get.find<AuthController>();
  late final CartController cartController = Get.find<CartController>();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() {
    if (widget.singleItem != null) {
      quantities[widget.singleItem!.id] = 1;
    } else {
      for (var item in widget.cartItems!) {
        quantities[item.id] = item.quantity;
      }
    }
  }

  List<CartItem> get items {
    if (widget.singleItem != null) {
      return [widget.singleItem!];
    }
    return widget.cartItems!;
  }

  double get totalAmount {
    return items.fold(
      0,
      (sum, item) =>
          sum + (double.parse(item.price) * (quantities[item.id] ?? 1)),
    );
  }

  void _proceedToCheckout() {
    // Create updated cart items with selected quantities
    final updatedItems =
        items.map((item) {
          final quantity = quantities[item.id] ?? 1;
          return CartItem(
            id: item.id,
            name: item.name,
            price: item.price,
            imageUrl: item.imageUrl,
            quantity: quantity,
          );
        }).toList();

    // Close dialog and navigate to checkout
    Get.back();
    Get.to(() => CheckoutScreen(items: updatedItems, isFromCart: false));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Obx(() {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select Quantity',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Product Info
              _buildProductInfo(textTheme, colorScheme),
              const SizedBox(height: 20),

              // Quantity Selection
              _buildQuantitySection(textTheme, colorScheme),
              const SizedBox(height: 20),

              // Total Price
              _buildTotalPrice(textTheme, colorScheme),
              const SizedBox(height: 20),

              // Checkout Button
              _buildCheckoutButton(colorScheme),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildProductInfo(TextTheme textTheme, ColorScheme colorScheme) {
    final item = items.first;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, color: Colors.grey),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rs ${item.price}',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySection(TextTheme textTheme, ColorScheme colorScheme) {
    final item = items.first;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quantity',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Select the quantity you want to purchase',
                    style: textTheme.bodyMedium,
                  ),
                ),
                QuantityControl(
                  quantity: quantities[item.id] ?? 1,
                  onIncrement:
                      () =>
                          quantities[item.id] = (quantities[item.id] ?? 1) + 1,
                  onDecrement: () {
                    final current = quantities[item.id] ?? 1;
                    if (current > 1) {
                      quantities[item.id] = current - 1;
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalPrice(TextTheme textTheme, ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Total Price:',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              'Rs ${totalAmount.toStringAsFixed(2)}',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _proceedToCheckout,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          'Proceed to Checkout',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const QuantityControl({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          color: quantity > 1 ? colorScheme.primary : Colors.grey,
          iconSize: 28,
          onPressed: quantity > 1 ? onDecrement : null,
          splashRadius: 20,
          tooltip: 'Decrease quantity',
        ),
        Text(
          quantity.toString(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          icon: Icon(Icons.add_circle_outline, color: colorScheme.primary),
          iconSize: 28,
          onPressed: onIncrement,
          splashRadius: 20,
          tooltip: 'Increase quantity',
        ),
      ],
    );
  }
}
