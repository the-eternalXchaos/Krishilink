import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/widgets/buttons.dart';
import 'package:krishi_link/src/core/components/app_text_input_field.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/auth/controller/cart_controller.dart';
import 'package:krishi_link/src/features/cart/models/cart_item.dart';
import 'package:krishi_link/src/features/payment/data/payment_service.dart';
import 'package:krishi_link/src/features/payment/data/khalti_direct_payment_service.dart';
import 'package:krishi_link/src/features/payment/data/payment_keys.dart';
import 'package:krishi_link/src/core/config/payment_config.dart';
import 'package:krishi_link/src/core/components/product/location_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  double selectedLatitude = 0.0;
  double selectedLongitude = 0.0;
  String selectedLocationAddress = '';

  bool isProcessingPayment = false;

  List<CartItem> get checkoutItems {
    if (widget.singleItem != null) return [widget.singleItem!];
    return widget.items ?? cartController.cartItems;
  }

  double get totalAmount => checkoutItems.fold(
    0,
    (sum, item) => sum + (double.parse(item.price) * item.quantity),
  );

  double get deliveryFee => totalAmount > 500 ? 0 : 50;
  double get finalTotal => totalAmount + deliveryFee;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = authController.currentUser.value;
    if (user != null) _phoneController.text = user.phoneNumber ?? '';
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _savePaymentHistory({
    required String status,
    required String transactionId,
    required String pidx,
  }) async {
    try {
      debugPrint('[PaymentHistory] Getting SharedPreferences instance...');
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('payment_history');
      debugPrint('[PaymentHistory] Existing payment_history: $jsonString');
      List<dynamic> data =
          jsonString != null && jsonString.isNotEmpty
              ? List<dynamic>.from(json.decode(jsonString) as List<dynamic>)
              : [];

      final payment = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'transactionId': transactionId,
        'pidx': pidx,
        'totalAmount': finalTotal,
        'status': status,
        'timestamp': DateTime.now().toIso8601String(),
        'fee': deliveryFee,
        'refunded': false,
        'purchaseOrderId': null,
        'purchaseOrderName': null,
        'items': checkoutItems.map((e) => e.toJson()).toList(),
        'customerName': authController.currentUser.value?.fullName ?? '',
        'customerPhone': _phoneController.text.trim(),
        'customerEmail': authController.currentUser.value?.email ?? '',
        'deliveryAddress': _addressController.text.trim(),
        'latitude': selectedLatitude,
        'longitude': selectedLongitude,
      };
      debugPrint('[PaymentHistory] New payment entry: ${json.encode(payment)}');
      data.add(payment);
      debugPrint(
        '[PaymentHistory] Updated payment_history: ${json.encode(data)}',
      );
      await prefs.setString('payment_history', json.encode(data));
      debugPrint(
        '[PaymentHistory] Saved payment_history to SharedPreferences.',
      );
    } catch (e) {
      debugPrint('[PaymentHistory] Failed to save payment history: $e');
    }
  }

  Future<void> _processOrder() async {
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

    setState(() => isProcessingPayment = true);

    try {
      if (selectedPaymentMethod == 'cash_on_delivery') {
        await _processCashOnDelivery();
      } else if (selectedPaymentMethod == 'esewa') {
        await _processEsewaPayment();
      } else if (selectedPaymentMethod == 'khalti') {
        await _processKhaltiPayment();
      }
    } catch (e) {
      debugPrint('[Checkout] Order processing failed: $e');
      PopupService.error('order_processing_failed'.tr, title: 'error'.tr);
    } finally {
      if (mounted) setState(() => isProcessingPayment = false);
    }
  }

  Future<void> _processCashOnDelivery() async {
    await Future.delayed(const Duration(seconds: 2));
    PopupService.success(
      'your_order_has_been_placed_successfully'.tr,
      title: 'order_placed'.tr,
    );
    if (widget.isFromCart) cartController.clearCart();
    await _savePaymentHistory(
      status: 'success',
      transactionId: DateTime.now().millisecondsSinceEpoch.toString(),
      pidx: 'cod',
    );
  }

  Future<void> _processEsewaPayment() async {
    try {
      // Implement your Esewa API integration here
      final transactionId = 'ES${DateTime.now().millisecondsSinceEpoch}';
      PopupService.success('esewa_payment_success'.tr, title: 'success'.tr);
      await _savePaymentHistory(
        status: 'success',
        transactionId: transactionId,
        pidx: 'esewa',
      );
    } catch (e) {
      PopupService.error('esewa_payment_failed'.tr, title: 'error'.tr);
    }
  }

  Future<void> _processKhaltiPayment() async {
    try {
      await khaltiDirectPaymentService.initiateDirectPayment(
        items: checkoutItems,
        amount: finalTotal,
        customerName:
            authController.currentUser.value != null
                ? authController.currentUser.value!.fullName
                : '',
        customerPhone: _phoneController.text.trim(),
        customerEmail:
            authController.currentUser.value != null
                ? authController.currentUser.value!.email
                : '',
        deliveryAddress: _addressController.text.trim(),
        latitude: selectedLatitude,
        longitude: selectedLongitude,
        onSuccess: (txId) async {
          PopupService.success(
            'khalti_payment_success'.tr,
            title: 'success'.tr,
          );
          await _savePaymentHistory(
            status: 'success',
            transactionId: txId,
            pidx: 'khalti',
          );
          Get.toNamed('payment-history');
        },
        onFailure:
            (error) => PopupService.error(
              'khalti_payment_failed'.tr,
              title: 'error'.tr,
            ),
        onCancel: () => PopupService.warning('Payment cancelled'),
      );
    } catch (e) {
      PopupService.error('khalti_payment_failed'.tr, title: 'error'.tr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
            _OrderSummaryCard(
              checkoutItems: checkoutItems,
              totalAmount: totalAmount,
              deliveryFee: deliveryFee,
              finalTotal: finalTotal,
            ),
            const SizedBox(height: 20),
            _DeliveryInfoCard(
              phoneController: _phoneController,
              addressController: _addressController,
              onLocationSelected: (lat, lng, address) {
                setState(() {
                  selectedLatitude = lat;
                  selectedLongitude = lng;
                  selectedLocationAddress = address;
                  _addressController.text = address;
                });
              },
            ),
            const SizedBox(height: 20),
            _PaymentMethodsCard(
              selectedPaymentMethod: selectedPaymentMethod,
              onChanged: (val) => setState(() => selectedPaymentMethod = val),
            ),
            const SizedBox(height: 20),
            _OrderNotesCard(notesController: _notesController),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildCheckoutButton(colorScheme),
    );
  }

  Widget _buildCheckoutButton(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Buttons.primary(
          text: 'place_order_rs'.trParams({
            'amount': finalTotal.toStringAsFixed(2),
          }),
          onPressed: _processOrder,
          loading: isProcessingPayment,
          colorScheme: colorScheme,
        ),
      ),
    );
  }
}

// ------------------- UI Cards -------------------

class _OrderSummaryCard extends StatelessWidget {
  final List<CartItem> checkoutItems;
  final double totalAmount;
  final double deliveryFee;
  final double finalTotal;

  const _OrderSummaryCard({
    required this.checkoutItems,
    required this.totalAmount,
    required this.deliveryFee,
    required this.finalTotal,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                    Expanded(child: Text('${item.name} x${item.quantity}')),
                    Text(
                      'Rs ${(double.parse(item.price) * item.quantity).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            _buildRow('subtotal'.tr, totalAmount),
            _buildRow('delivery_fee'.tr, deliveryFee),
            const SizedBox(height: 8),
            _buildRow(
              'total'.tr,
              finalTotal,
              bold: true,
              color: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    double amount, {
    bool bold = false,
    Color? color,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          'Rs ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _DeliveryInfoCard extends StatelessWidget {
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final Function(double, double, String) onLocationSelected;

  const _DeliveryInfoCard({
    required this.phoneController,
    required this.addressController,
    required this.onLocationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            AppTextInputField(
              controller: phoneController,
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
              initialLatitude: 0,
              initialLongitude: 0,
              initialAddress: '',
              onLocationSelected: onLocationSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodsCard extends StatelessWidget {
  final String selectedPaymentMethod;
  final ValueChanged<String> onChanged;

  const _PaymentMethodsCard({
    required this.selectedPaymentMethod,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'payment_method'.tr,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildOption(
              'cash_on_delivery',
              'cash_on_delivery'.tr,
              Icons.money,
              colorScheme,
            ),
            _buildOption(
              'esewa',
              'esewa'.tr,
              Icons.account_balance_wallet,
              colorScheme,
              subtitle: 'digital_wallet_payment'.tr,
            ),
            _buildOption(
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

  Widget _buildOption(
    String value,
    String title,
    IconData icon,
    ColorScheme colorScheme, {
    String? subtitle,
  }) {
    return RadioListTile<String>(
      value: value,
      groupValue: selectedPaymentMethod,
      onChanged: (v) => onChanged(v ?? value),
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
}

class _OrderNotesCard extends StatelessWidget {
  final TextEditingController notesController;

  const _OrderNotesCard({required this.notesController});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AppTextInputField(
          controller: notesController,
          label: 'special_instructions'.tr,
          icon: Icons.note,
          maxLines: 3,
        ),
      ),
    );
  }
}
