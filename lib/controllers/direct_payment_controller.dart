import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:krishi_link/features/cart/models/cart_item.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/src/features/payment/data/khalti_direct_payment_service.dart';
import 'package:krishi_link/src/core/config/payment_config.dart';

/// Example controller showing how to use direct Khalti payments
class DirectPaymentController extends GetxController {
  final KhaltiDirectPaymentService _paymentService =
      KhaltiDirectPaymentService();

  final RxBool isProcessingPayment = false.obs;
  final RxString lastTransactionId = ''.obs;

  /// Process payment directly with Khalti (no backend needed)
  Future<void> processDirectPayment({
    required List<CartItem> cartItems,
    required double totalAmount,
    required String customerName,
    required String customerPhone,
    String? customerEmail,
  }) async {
    try {
      isProcessingPayment.value = true;

      debugPrint('[Payment] Starting direct payment for Rs. $totalAmount');

      await _paymentService.initiateDirectPayment(
        items: cartItems,
        amount: totalAmount,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        onSuccess: (transactionId) {
          debugPrint('[Payment] Payment successful: $transactionId');
          lastTransactionId.value = transactionId;

          PopupService.success(
            'Payment successful!\nTransaction ID: $transactionId',
            title: 'Payment Complete',
          );

          // You can now clear cart, show success screen, etc.
          _onPaymentSuccess(transactionId, cartItems, totalAmount);

          // Navigate to configured post-payment destination (e.g., Payment History)
          PaymentConfig.navigateAfterSuccess();
        },
        onFailure: (error) {
          debugPrint('[Payment] Payment failed: $error');
          PopupService.error('Payment failed: $error', title: 'Payment Error');
        },
        onCancel: () {
          debugPrint('[Payment] Payment cancelled by user');
          PopupService.info(
            'Payment was cancelled',
            title: 'Payment Cancelled',
          );
        },
      );
    } catch (e) {
      debugPrint('[Payment] Error processing payment: $e');
      PopupService.error(
        'Failed to process payment: $e',
        title: 'Payment Error',
      );
    } finally {
      isProcessingPayment.value = false;
    }
  }

  /// Handle successful payment
  void _onPaymentSuccess(
    String transactionId,
    List<CartItem> items,
    double amount,
  ) {
    // Here you can:
    // 1. Clear the cart
    // 2. Save order locally
    // 3. Navigate to success page
    // 4. Send order details to farmer (when backend is ready)

    debugPrint('[Payment] Processing successful payment...');
    debugPrint('[Payment] Transaction ID: $transactionId');
    debugPrint('[Payment] Items: ${items.length}');
    debugPrint('[Payment] Amount: Rs. $amount');

    // Example: Save order locally
    _saveOrderLocally(transactionId, items, amount);
  }

  /// Save order details locally (since backend is not ready)
  Future<void> _saveOrderLocally(
    String transactionId,
    List<CartItem> items,
    double amount,
  ) async {
    try {
      //  local storage

      debugPrint('[Payment] Saving order locally...');

      final orderData = {
        'transactionId': transactionId,
        'items':
            items
                .map(
                  (item) => {
                    'id': item.id,
                    'name': item.name,
                    'price': item.price,
                    'quantity': item.quantity,
                    'imageUrl': item.image, // Use CartItem.image for image URL
                  },
                )
                .toList(),
        'totalAmount': amount,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'paid',
      };

      // You can save this to SharedPreferences, Hive, or any local database
      debugPrint('[Payment] Order saved: $orderData');
    } catch (e) {
      debugPrint('[Payment] Failed to save order locally: $e');
    }
  }

  /// Get payment history
  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    return await _paymentService.getPaymentHistory();
  }

  /// Test Khalti connection
  Future<bool> testKhaltiConnection() async {
    return await _paymentService.testConnection();
  }

  /// Verify a payment
  Future<Map<String, dynamic>?> verifyPayment(String pidx) async {
    return await _paymentService.verifyPayment(pidx);
  }
}
