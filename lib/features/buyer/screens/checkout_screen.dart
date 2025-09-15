import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/components/app_text_input_field.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/features/cart/models/cart_item.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/auth/controller/cart_controller.dart';
import 'package:krishi_link/services/popup_service.dart';
import 'package:krishi_link/core/components/material_ui/popup.dart';
import 'package:krishi_link/src/features/payment/data/payment_service.dart';
import 'package:krishi_link/src/features/payment/data/khalti_direct_payment_service.dart';
import 'package:krishi_link/src/features/payment/data/payment_keys.dart';
import 'package:krishi_link/src/core/config/payment_config.dart';
import 'package:krishi_link/core/components/product/location_picker.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem>? items;
  final CartItem? singleItem;
  final bool isFromCart;

  const CheckoutScreen({
    super.key,
    this.items,
    this.singleItem,
    this.isFromCart = true,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final AuthController authController =
      Get.isRegistered<AuthController>()
          ? Get.find<AuthController>()
          : Get.put(AuthController());
  final CartController cartController =
      Get.isRegistered<CartController>()
          ? Get.find<CartController>()
          : Get.put(CartController());
  final PaymentService paymentService = Get.put(PaymentService());
  final KhaltiDirectPaymentService khaltiDirectPaymentService = Get.put(
    PaymentKeys.isConfigured
        ? KhaltiDirectPaymentService(
          khaltiPublicKey: PaymentKeys.publicKey,
          khaltiSecretKey: PaymentKeys.secretKey,
        )
        : KhaltiDirectPaymentService(),
  );

  String selectedPaymentMethod = 'cash_on_delivery';
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  // Location variables
  double selectedLatitude = 0.0;
  double selectedLongitude = 0.0;
  String selectedLocationAddress = '';

  bool isProcessingPayment = false;

  List<CartItem> get checkoutItems {
    if (widget.singleItem != null) {
      return [widget.singleItem!];
    }
    return widget.items ?? cartController.cartItems;
  }

  double get totalAmount {
    return checkoutItems.fold(
      0,
      (sum, item) => sum + (double.parse(item.price) * item.quantity),
    );
  }

  double get deliveryFee => totalAmount > 500 ? 0 : 50;
  double get finalTotal => totalAmount + deliveryFee;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = authController.currentUser.value;
    if (user != null) {
      _phoneController.text = user.phoneNumber ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('checkout'.tr),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary
            _buildOrderSummary(colorScheme, textTheme),
            const SizedBox(height: 20),

            // Delivery Information
            _buildDeliveryInfo(colorScheme, textTheme),
            const SizedBox(height: 20),

            // Payment Methods
            _buildPaymentMethods(colorScheme, textTheme),
            const SizedBox(height: 20),

            // Order Notes
            _buildOrderNotes(colorScheme, textTheme),
            const SizedBox(height: 100), // Space for bottom button
          ],
        ),
      ),
      bottomNavigationBar: _buildCheckoutButton(colorScheme),
    );
  }

  Widget _buildOrderSummary(ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'order_summary'.tr,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...checkoutItems.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.name} x${item.quantity}',
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      'Rs ${(double.parse(item.price) * item.quantity).toStringAsFixed(2)}',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(child: Text('subtotal'.tr)),
                Text('Rs ${totalAmount.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: Text('delivery_fee'.tr)),
                Text('Rs ${deliveryFee.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'total'.tr,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'Rs ${finalTotal.toStringAsFixed(2)}',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfo(ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'delivery_information'.tr,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            const SizedBox(height: 12),

            // user my custom text field  for phone number
            AppTextInputField(
              controller: _phoneController,
              label: 'phone_number'.tr,
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            Text(
              'select_delivery_location'.tr,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            LocationPicker(
              initialLatitude: selectedLatitude,
              initialLongitude: selectedLongitude,
              initialAddress: selectedLocationAddress,
              onLocationSelected: (latitude, longitude, address) {
                setState(() {
                  selectedLatitude = latitude;
                  selectedLongitude = longitude;
                  selectedLocationAddress = address;
                  _addressController.text = address;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethods(ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'payment_method'.tr,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              'cash_on_delivery',
              'cash_on_delivery'.tr,
              Icons.money,
              colorScheme,
            ),
            _buildPaymentOption(
              'esewa',
              'esewa'.tr,
              Icons.account_balance_wallet,
              colorScheme,
              subtitle: 'digital_wallet_payment'.tr,
            ),
            _buildPaymentOption(
              'khalti',
              'khalti'.tr,
              Icons.payment,
              colorScheme,
              subtitle: 'digital_wallet_payment'.tr,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    String value,
    String title,
    IconData icon,
    ColorScheme colorScheme, {
    String? subtitle,
  }) {
    return RadioListTile<String>(
      value: value,
      groupValue: selectedPaymentMethod,
      onChanged: (String? newValue) {
        setState(() {
          selectedPaymentMethod = newValue!;
        });
      },
      title: Row(
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      activeColor: colorScheme.primary,
    );
  }

  Widget _buildOrderNotes(ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'order_notes'.tr,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // user my custom text field for order notes
            AppTextInputField(
              controller: _notesController,
              label: 'special_instructions'.tr,
              icon: Icons.note,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutButton(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: isProcessingPayment ? null : _processOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child:
                isProcessingPayment
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                      'place_order_rs'.trParams({
                        'amount': finalTotal.toStringAsFixed(2),
                      }),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ),
      ),
    );
  }

  Future<void> _processOrder() async {
    // Debug: log order context
    debugPrint(
      '[Checkout] _processOrder start | method=$selectedPaymentMethod, '
      'items=${checkoutItems.length}, subtotal=${totalAmount.toStringAsFixed(2)}, '
      'deliveryFee=${deliveryFee.toStringAsFixed(2)}, total=${finalTotal.toStringAsFixed(2)}',
    );
    debugPrint(
      '[Checkout] Address="${_addressController.text.trim()}" '
      'lat=$selectedLatitude, lng=$selectedLongitude, phone=${_phoneController.text.trim()}',
    );
    // Validate inputs
    if (_addressController.text.trim().isEmpty) {
      PopupService.warning(
        'please_enter_delivery_address'.tr,
        title: 'validation_error'.tr,
      );
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      PopupService.warning(
        'please_enter_phone_number'.tr,
        title: 'validation_error'.tr,
      );
      return;
    }

    if (mounted) {
      setState(() {
        isProcessingPayment = true;
      });
    }

    try {
      if (selectedPaymentMethod == 'cash_on_delivery') {
        await _processCashOnDelivery();
      } else if (selectedPaymentMethod == 'esewa') {
        await _processEsewaPayment();
      } else if (selectedPaymentMethod == 'khalti') {
        debugPrint('[Checkout] Proceeding with Khalti payment flow');
        await _processKhaltiPayment();
      }
    } catch (e) {
      // Provide more context in logs and user feedback
      debugPrint('[Checkout] Order processing failed: $e');
      PopupService.error('order_processing_failed'.tr, title: 'error'.tr);
    } finally {
      if (mounted) {
        setState(() {
          isProcessingPayment = false;
        });
      }
    }
  }

  Future<void> _processCashOnDelivery() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    PopupService.success(
      'your_order_has_been_placed_successfully'.tr,
      title: 'order_placed'.tr,
    );

    // Clear cart if from cart
    if (widget.isFromCart) {
      cartController.clearCart();
    }

    // Navigate back to home
    Get.offAllNamed('/buyer-dashboard');
  }

  Future<void> _processEsewaPayment() async {
    // For now, show a message that eSewa integration is coming soon
    PopupService.warning(
      'esewa_integration_coming_soon'.tr,
      title: 'coming_soon'.tr,
    );
  }

  Future<void> _processKhaltiPayment() async {
    try {
      final user = authController.currentUser.value;
      if (user == null) {
        PopupService.error('User not logged in');
        return;
      }

      // Use direct in-app Khalti flow (no backend)
      debugPrint(
        '[Khalti] Using in-app direct flow, amount=${finalTotal.toStringAsFixed(2)}',
      );
      await khaltiDirectPaymentService.initiateDirectPayment(
        items: checkoutItems,
        amount: finalTotal,
        customerName: user.fullName ?? 'Customer',
        customerPhone: _phoneController.text.trim(),
        customerEmail: user.email,
        deliveryAddress: _addressController.text.trim(),
        latitude: selectedLatitude,
        longitude: selectedLongitude,
        onSuccess: (transactionId) {
          debugPrint('[Khalti] Payment success: $transactionId');
          if (widget.isFromCart) {
            try {
              Get.find<CartController>().clearCart();
            } catch (_) {}
          }
          PopupService.success('Payment successful!');
          // Centralized navigation behavior
          PaymentConfig.navigateAfterSuccess();
        },
        onFailure: (error) {
          PopupService.error('Payment failed: $error');
        },
        onCancel: () {
          PopupService.warning('Payment cancelled');
        },
      );
    } catch (e) {
      debugPrint('[Khalti] Payment processing failed: $e');
      PopupService.error('Payment processing failed: $e');
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
