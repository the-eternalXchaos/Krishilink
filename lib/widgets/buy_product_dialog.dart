import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/features/admin/models/cart_item.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/auth/controller/cart_controller.dart';

class BuyProductDialog extends StatelessWidget {
  final List<CartItem>? cartItems;
  final CartItem? singleItem;

  BuyProductDialog({super.key, this.cartItems, this.singleItem})
    : assert(cartItems != null || singleItem != null);

  final RxMap<String, int> quantities = <String, int>{}.obs;
  final RxString selectedAddress = ''.obs;
  final RxString selectedPaymentMethod = 'COD'.obs;
  final List<String> paymentMethods = ['COD', 'Online'];

  late final AuthController authController = Get.find<AuthController>();
  late final CartController cartController = Get.find<CartController>();

  void initialize() {
    if (singleItem != null) {
      quantities[singleItem!.id] = 1;
    } else {
      for (var item in cartItems!) {
        quantities[item.id] = item.quantity;
      }
    }

    final user = authController.currentUser.value;
    if (user?.address != null && user!.address!.isNotEmpty) {
      selectedAddress.value = user.address!;
    }
  }

  @override
  Widget build(BuildContext context) {
    initialize();

    final textTheme = Theme.of(context).textTheme;
    final items = singleItem != null ? [singleItem!] : cartItems!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Obx(() {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  singleItem != null ? 'Buy Now' : 'Checkout',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Items List (scrollable if many)
                Expanded(
                  child: Scrollbar(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Rs ${item.price}',
                                        style: textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                QuantityControl(
                                  quantity: quantities[item.id] ?? 1,
                                  onIncrement:
                                      () =>
                                          quantities[item.id] =
                                              (quantities[item.id] ?? 1) + 1,
                                  onDecrement: () {
                                    final current = quantities[item.id] ?? 1;
                                    if (current > 1) {
                                      quantities[item.id] = current - 1;
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Delivery Address
                Text('Delivery Address', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                AddressSelector(selectedAddress: selectedAddress),

                const SizedBox(height: 20),

                // Payment Method
                Text('Payment Method', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                PaymentMethodSelector(
                  selectedPaymentMethod: selectedPaymentMethod,
                  paymentMethods: paymentMethods,
                ),

                const SizedBox(height: 30),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        child: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Place order logic here, disabled if loading
                        },
                        child: const Text('Confirm Purchase'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
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

class AddressSelector extends StatelessWidget {
  final RxString selectedAddress;

  const AddressSelector({super.key, required this.selectedAddress});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return TextFormField(
        maxLines: 2,
        decoration: InputDecoration(
          hintText: 'Enter delivery address',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          suffixIcon:
              selectedAddress.value.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => selectedAddress.value = '',
                  )
                  : null,
        ),
        initialValue: selectedAddress.value,
        onChanged: (val) => selectedAddress.value = val.trim(),
      );
    });
  }
}

class PaymentMethodSelector extends StatelessWidget {
  final RxString selectedPaymentMethod;
  final List<String> paymentMethods;

  const PaymentMethodSelector({
    super.key,
    required this.selectedPaymentMethod,
    required this.paymentMethods,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Wrap(
        spacing: 12,
        children:
            paymentMethods.map((method) {
              final isSelected = selectedPaymentMethod.value == method;
              return ChoiceChip(
                label: Text(method),
                selected: isSelected,
                onSelected: (_) => selectedPaymentMethod.value = method,
                selectedColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              );
            }).toList(),
      );
    });
  }
}
