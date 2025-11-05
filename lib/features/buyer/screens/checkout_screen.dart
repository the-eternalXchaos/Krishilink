import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/core/widgets/buttons.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/auth/controller/cart_controller.dart';
import 'package:krishi_link/src/core/components/app_text_input_field.dart';
import 'package:krishi_link/src/core/components/product/location_picker.dart';
import 'package:krishi_link/src/core/constants/api_constants.dart';
import 'package:krishi_link/src/core/errors/app_exception.dart';
import 'package:krishi_link/src/features/auth/data/token_service.dart';
import 'package:krishi_link/src/features/cart/models/cart_item.dart';
import 'package:krishi_link/src/features/payment/data/backend_payment_service.dart';
import 'package:krishi_link/src/features/payment/presentation/screens/payment_webview_screen.dart';
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
  final BackendPaymentService backendPaymentService = Get.put(
    BackendPaymentService(),
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

  // Business rule: fixed delivery fee Rs. 100 and 1% tax applied on (subtotal + delivery)
  static const double _deliveryFeeFixed = 100.0;
  static const double _taxRate = 0.01; // 1%

  double get deliveryFee => _deliveryFeeFixed;
  double get taxAmount {
    final base = totalAmount + deliveryFee;
    // Round tax to 2 decimals for currency consistency
    return double.parse((base * _taxRate).toStringAsFixed(2));
  }

  double get finalTotal {
    final base = totalAmount + deliveryFee;
    // Apply tax and round grand total to 2 decimals
    return double.parse((base * (1 + _taxRate)).toStringAsFixed(2));
  }

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
    // Require authentication before placing order or initiating payment
    final hasAuth = await TokenService.hasTokens();
    if (!hasAuth) {
      PopupService.error('Please login to continue', title: 'Session Required');
      Get.offAllNamed('/login');
      return;
    }
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
    try {
      // Ensure we have a cart id
      if (cartController.currentCartId.value.isEmpty) {
        await cartController.fetchCartItems();
      }
      final cartId = cartController.currentCartId.value;
      if (cartId.isEmpty) {
        throw Exception('Missing cart id');
      }

      final res = await backendPaymentService.cashOnDelivery(
        cartId: cartId,
        totalPayableAmount: finalTotal,
      );
      if (res.statusCode != null &&
          res.statusCode! >= 200 &&
          res.statusCode! < 300) {
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
      } else {
        throw Exception('COD failed: ${res.statusCode}');
      }
    } catch (e) {
      PopupService.error('Failed to place COD order', title: 'error'.tr);
    }
  }

  Future<void> _processEsewaPayment() async {
    try {
      debugPrint('[Checkout][eSewa] Starting payment flow');
      // Ensure we have a cart id
      if (cartController.currentCartId.value.isEmpty) {
        debugPrint('[Checkout][eSewa] cartId missing; fetching cart...');
        await cartController.fetchCartItems();
      }
      final cartId = cartController.currentCartId.value;
      debugPrint('[Checkout][eSewa] Using cartId: $cartId');
      debugPrint(
        '[Checkout][eSewa] totalPayableAmount: ${finalTotal.toStringAsFixed(2)}',
      );
      if (cartId.isEmpty) {
        throw Exception('Missing cart id');
      }

      final response = await backendPaymentService.initiateEsewa(
        cartId: cartId,
        totalPayableAmount: finalTotal,
      );
      debugPrint('[Checkout][eSewa] Initiate status: ${response.statusCode}');
      debugPrint('[Checkout][eSewa] Initiate body: ${response.data}');
      if (response.statusCode == 200 && response.data is Map) {
        final data = Map<String, dynamic>.from(response.data as Map);
        final missing = <String>[];
        for (final k in [
          'amount',
          'tax_amount',
          'total_amount',
          'transaction_uuid',
          'product_code',
          'product_service_charge',
          'product_delivery_charge',
          'success_url',
          'failure_url',
          'signed_field_names',
          'signature',
        ]) {
          if (!data.containsKey(k)) missing.add(k);
        }
        if (missing.isNotEmpty) {
          debugPrint(
            '[Checkout][eSewa][WARN] Missing fields from backend: $missing',
          );
        }
        final html = _buildEsewaAutoSubmitHtml(data);
        debugPrint(
          '[Checkout][eSewa] Built eSewa form HTML (first 300 chars):\n${html.substring(0, html.length.clamp(0, 300))}',
        );
        // Open payment webview with form auto-submit and success/failure detection
        await Get.to(
          () => PaymentWebViewScreen(
            htmlContent: html,
            successUrls: const [
              ApiConstants.esewaSuccessEndpoint,
              ApiConstants.paymentSuccessEndpoint,
            ],
            failureUrls: const [
              ApiConstants.esewaFailureEndpoint,
              ApiConstants.paymentFailureEndpoint,
            ],
            clearCartOnSuccess: true,
          ),
        );
      } else {
        throw Exception('Failed to initiate eSewa payment');
      }
    } catch (e) {
      debugPrint('[Checkout][eSewa][ERROR] $e');
      PopupService.error('esewa_payment_failed'.tr, title: 'error'.tr);
    }
  }

  Future<void> _processKhaltiPayment() async {
    try {
      debugPrint('[Checkout][Khalti] Starting payment flow');

      if (cartController.currentCartId.value.isEmpty) {
        debugPrint('[Checkout][Khalti] cartId missing; fetching cart...');
        await cartController.fetchCartItems();
      }

      final cartId = cartController.currentCartId.value;
      debugPrint('[Checkout][Khalti] Using cartId: $cartId');
      debugPrint(
        '[Checkout][Khalti] totalPayableAmount: ${finalTotal.toStringAsFixed(2)}',
      );

      if (cartId.isEmpty) {
        throw Exception('Missing cart id');
      }

      final response = await backendPaymentService.initiateKhalti(
        cartId: cartId,
        totalPayableAmount: finalTotal,
      );

      debugPrint('[Checkout][Khalti] Initiate status: ${response.statusCode}');
      debugPrint('[Checkout][Khalti] Initiate body: ${response.data}');

      if (response.statusCode != 200) {
        final message =
            _extractMessage(response.data) ??
            'Failed to initiate Khalti payment';
        throw AppException(message);
      }

      final parsed = _parseKhaltiPaymentResponse(response.data);
      final paymentUrl = parsed['url'];
      final pidx = parsed['pidx'];

      debugPrint('[Checkout][Khalti] paymentUrl: $paymentUrl');
      debugPrint('[Checkout][Khalti] pidx: $pidx');

      if (paymentUrl == null || paymentUrl.isEmpty) {
        throw AppException('Missing payment URL');
      }

      await Get.to(
        () => PaymentWebViewScreen(
          url: paymentUrl,
          successUrls: const [
            ApiConstants.khaltiResponseEndpoint,
            ApiConstants.paymentSuccessEndpoint,
          ],
          failureUrls: const [ApiConstants.paymentFailureEndpoint],
          clearCartOnSuccess: true,
        ),
        arguments: {'pidx': pidx, 'source': 'khalti'},
      );
    } on AppException catch (e) {
      debugPrint('[Checkout][Khalti][APP-ERROR] ${e.message}');
      PopupService.error(e.message, title: 'khalti'.tr);
    } catch (e) {
      debugPrint('[Checkout][Khalti][ERROR] $e');
      PopupService.error('khalti_payment_failed'.tr, title: 'error'.tr);
    }
  }

  Map<String, String?> _parseKhaltiPaymentResponse(dynamic body) {
    Map<String, dynamic>? rootMap;
    String? paymentUrl;
    String? pidx;

    if (body is Map) {
      rootMap = Map<String, dynamic>.from(body);
    } else if (body is String) {
      final trimmed = body.trim();
      if (trimmed.isEmpty) {
        throw AppException('Empty response from payment service');
      }
      if (trimmed.startsWith('{')) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is Map) {
            rootMap = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {}
      }
      if (rootMap == null) {
        final normalized = _normalizeUrl(trimmed);
        if (normalized == null) {
          throw AppException('Unexpected response from payment service');
        }
        paymentUrl = normalized;
        pidx = Uri.tryParse(normalized)?.queryParameters['pidx'];
        return {'url': paymentUrl, 'pidx': pidx};
      }
    } else {
      throw AppException('Unexpected response format from payment service');
    }

    final Map<String, dynamic> map = rootMap;
    final successField = map['success'];
    final hasExplicitSuccess = successField != null;
    final isSuccess =
        successField is bool
            ? successField
            : successField?.toString().toLowerCase().trim() == 'true';

    if (hasExplicitSuccess && !isSuccess) {
      final serverMessage = map['message']?.toString();
      throw AppException(
        serverMessage?.isNotEmpty == true
            ? serverMessage!
            : 'Khalti payment initiation failed',
      );
    }

    dynamic payload = map['data'];
    if (payload is Map) {
      payload = Map<String, dynamic>.from(payload);
    } else if (payload is String) {
      final trimmed = payload.trim();
      if (trimmed.startsWith('{')) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is Map) {
            payload = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {}
      }
      if (payload is! Map) {
        final normalized = _normalizeUrl(trimmed);
        if (normalized != null) {
          paymentUrl = normalized;
          pidx = Uri.tryParse(normalized)?.queryParameters['pidx'];
          return {'url': paymentUrl, 'pidx': pidx};
        }
      }
    }

    final effective = payload is Map ? payload : map;

    paymentUrl = _extractUrlFromMap(Map<String, dynamic>.from(effective));
    pidx = (effective['pidx'] ?? effective['pIdx'] ?? map['pidx'])?.toString();

    if (paymentUrl == null || paymentUrl.isEmpty) {
      final message = map['message']?.toString() ?? 'Missing payment URL';
      throw AppException(message);
    }

    pidx ??= Uri.tryParse(paymentUrl)?.queryParameters['pidx'];

    return {'url': paymentUrl, 'pidx': pidx};
  }

  String? _normalizeUrl(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.scheme.isEmpty) return null;
    return trimmed;
  }

  String? _extractUrlFromMap(Map<String, dynamic> source) {
    final candidates = [
      source['paymentUrl'],
      source['payment_url'],
      source['url'],
    ];
    for (final candidate in candidates) {
      final normalized = candidate is String ? _normalizeUrl(candidate) : null;
      if (normalized != null) return normalized;
    }

    for (final entry in source.entries) {
      final value = entry.value;
      if (value is String) {
        final normalized = _normalizeUrl(value);
        if (normalized != null) return normalized;
      } else if (value is Map) {
        final nested = _extractUrlFromMap(Map<String, dynamic>.from(value));
        if (nested != null) return nested;
      }
    }
    return null;
  }

  String? _extractMessage(dynamic body) {
    if (body == null) return null;
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      final message = map['message'] ?? map['error'] ?? map['detail'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
      if (map['data'] != null && map['data'] is String) {
        final nestedMessage = _extractMessage(map['data']);
        if (nestedMessage != null) return nestedMessage;
      }
      return null;
    }
    if (body is String) {
      final trimmed = body.trim();
      if (trimmed.isEmpty) return null;
      if (trimmed.startsWith('{')) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is Map) {
            return _extractMessage(decoded);
          }
        } catch (_) {}
      }
      return trimmed;
    }
    return null;
  }

  String _buildEsewaAutoSubmitHtml(Map<String, dynamic> fields) {
    // Map fields to a form that posts to eSewa form URL; auto-submit on load
    final amount = fields['amount']?.toString() ?? '';
    final taxAmount = fields['tax_amount']?.toString() ?? '';
    final totalAmount = fields['total_amount']?.toString() ?? '';
    final transactionUuid = fields['transaction_uuid']?.toString() ?? '';
    final productCode = fields['product_code']?.toString() ?? '';
    final pdc = fields['product_delivery_charge']?.toString() ?? '0';
    final psc = fields['product_service_charge']?.toString() ?? '0';
    final successUrl = fields['success_url']?.toString() ?? '';
    final failureUrl = fields['failure_url']?.toString() ?? '';
    final signedFieldNames = fields['signed_field_names']?.toString() ?? '';
    final signature = fields['signature']?.toString() ?? '';

    return '''
<!doctype html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>eSewa Payment</title>
  </head>
  <body onload="document.forms[0].submit()" style="font-family: sans-serif;">
    <p>Redirecting to eSewa...</p>
    <form action="${ApiConstants.esewaFormUrl}" method="POST">
      <input type="hidden" name="amount" value="$amount" />
      <input type="hidden" name="tax_amount" value="$taxAmount" />
      <input type="hidden" name="total_amount" value="$totalAmount" />
      <input type="hidden" name="transaction_uuid" value="$transactionUuid" />
      <input type="hidden" name="product_code" value="$productCode" />
      <input type="hidden" name="product_service_charge" value="$psc" />
      <input type="hidden" name="product_delivery_charge" value="$pdc" />
      <input type="hidden" name="success_url" value="$successUrl" />
      <input type="hidden" name="failure_url" value="$failureUrl" />
      <input type="hidden" name="signed_field_names" value="$signedFieldNames" />
      <input type="hidden" name="signature" value="$signature" />
      <noscript>
        <button type="submit">Pay with eSewa</button>
      </noscript>
    </form>
  </body>
 </html>
''';
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
              taxAmount: taxAmount,
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
  final double taxAmount;
  final double finalTotal;

  const _OrderSummaryCard({
    required this.checkoutItems,
    required this.totalAmount,
    required this.deliveryFee,
    required this.taxAmount,
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
            _buildRow('tax (1%)', taxAmount),
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
