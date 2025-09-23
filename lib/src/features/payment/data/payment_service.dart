import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:khalti_checkout_flutter/khalti_checkout_flutter.dart';
import 'package:krishi_link/src/features/payment/models/payment_history.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:krishi_link/src/features/payment/data/local/payment_history_local_data_source.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:krishi_link/src/core/networking/base_service.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/features/cart/models/cart_item.dart';
import 'package:krishi_link/features/auth/controller/cart_controller.dart';
import 'package:krishi_link/src/core/config/payment_config.dart';

// DTOs and Models
class PaymentInitiateRequest {
  final String returnUrl;
  final String websiteUrl;
  final int amount;
  final String purchaseOrderId;
  final String purchaseOrderName;
  final Map<String, dynamic> customerInfo;
  final List<Map<String, dynamic>> productDetails;

  PaymentInitiateRequest({
    required this.returnUrl,
    required this.websiteUrl,
    required this.amount,
    required this.purchaseOrderId,
    required this.purchaseOrderName,
    required this.customerInfo,
    required this.productDetails,
  });

  Map<String, dynamic> toJson() => {
        'return_url': returnUrl,
        'website_url': websiteUrl,
        'amount': amount,
        'purchase_order_id': purchaseOrderId,
        'purchase_order_name': purchaseOrderName,
        'customer_info': customerInfo,
        'product_details': productDetails,
      };
}

class PaymentInitiateResponse {
  final String pidx;
  final String paymentUrl;
  final DateTime expiresAt;
  final int expiresIn;

  PaymentInitiateResponse({
    required this.pidx,
    required this.paymentUrl,
    required this.expiresAt,
    required this.expiresIn,
  });

  factory PaymentInitiateResponse.fromJson(Map<String, dynamic> json) {
    return PaymentInitiateResponse(
      pidx: json['pidx'] as String,
      paymentUrl: json['payment_url'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      expiresIn: json['expires_in'] as int,
    );
  }
}

/// Payment service using the new architecture
class PaymentService extends BaseService {
  static const String _khaltiPublicKeyTest =
      'test_public_key_dc74e0fd57cb46cd93832aee0a390234';
  static const String _khaltiSecretKeyTest =
      'test_secret_key_f59e8b7629b4431db8264e09fc830d76';

  final String _khaltiPublicKey;
  final String _khaltiSecretKey;

  // Pending context to enrich history after successful payment
  Map<String, dynamic>? _pendingContext;

  // When true, do not call Khalti servers; simulate sandbox locally
  final bool clientOnlySandbox;

  PaymentService({
    super.apiClient,
    String? khaltiPublicKey,
    String? khaltiSecretKey,
    this.clientOnlySandbox = true,
  })  : _khaltiPublicKey = khaltiPublicKey ?? _khaltiPublicKeyTest,
        _khaltiSecretKey = khaltiSecretKey ?? _khaltiSecretKeyTest;

  /// Initiate payment with Khalti
  Future<PaymentInitiateResponse> initiatePayment({
    required List<CartItem> items,
    required double amount,
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    String? deliveryAddress,
    double? latitude,
    double? longitude,
  }) async {
    if (clientOnlySandbox) {
      final amountPaisa = (amount * 100).round();
      final purchaseOrderId =
          'KL-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';

      final fake = PaymentInitiateResponse(
        pidx:
            'MOCK-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}',
        paymentUrl: 'about:blank',
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        expiresIn: 900,
      );

      _pendingContext = {
        'items': items,
        'amount': amount,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerEmail': customerEmail,
        'deliveryAddress': deliveryAddress ?? '',
        'latitude': latitude ?? 0.0,
        'longitude': longitude ?? 0.0,
        'purchaseOrderId': purchaseOrderId,
      };
      debugPrint(
        '[Payment] Client-only sandbox initiate: pidx=${fake.pidx}, amount=$amountPaisa',
      );
      return fake;
    }

    return executeApiCall(() async {
      final amountPaisa = (amount * 100).round();
      final purchaseOrderId =
          'KL-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';

      final request = PaymentInitiateRequest(
        returnUrl: 'https://example.com/payment/',
        websiteUrl: 'https://example.com/',
        amount: amountPaisa,
        purchaseOrderId: purchaseOrderId,
        purchaseOrderName: 'Krishi Link Order',
        customerInfo: {
          'name': customerName,
          if (customerEmail != null) 'email': customerEmail,
          'phone': customerPhone,
        },
        productDetails: items
            .map(
              (e) => {
                'identity': e.id,
                'name': e.name,
                'total_price':
                    (double.parse(e.price) * e.quantity * 100).round(),
                'quantity': e.quantity,
                'unit_price': (double.parse(e.price) * 100).round(),
              },
            )
            .toList(),
      );

      final response = await apiClient.post(
        'https://dev.khalti.com/api/v2/epayment/initiate/',
        data: request.toJson(),
        options: Options(headers: {'Authorization': 'key $_khaltiSecretKey'}),
      );

      if (response.data == null) {
        throw Exception('Failed to initiate payment');
      }

      final init = PaymentInitiateResponse.fromJson(response.data);

      // Save pending context for history creation after success
      _pendingContext = {
        'items': items,
        'amount': amount,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerEmail': customerEmail,
        'deliveryAddress': deliveryAddress ?? '',
        'latitude': latitude ?? 0.0,
        'longitude': longitude ?? 0.0,
        'purchaseOrderId': init.pidx, // fallback id if needed
      };

      return init;
    });
  }

  /// Launch Khalti payment interface
  Future<bool> launchPayment({
    required String pidx,
    required Function(String transactionId) onSuccess,
    required Function(String error) onFailure,
    required Function() onCancel,
  }) async {
    if (clientOnlySandbox) {
      debugPrint('[Payment] Client-only sandbox launch for pidx=$pidx');
      await Future.delayed(const Duration(milliseconds: 800));
      final ctx = _pendingContext ?? const {};
      final payload = {
        'transactionId': 'TRX-${DateTime.now().millisecondsSinceEpoch}',
        'pidx': pidx,
        'totalAmount': ((ctx['amount'] as double? ?? 0.0) * 100).round(),
        'status': 'Completed',
        'fee': 0,
        'refunded': false,
        'purchaseOrderId': ctx['purchaseOrderId'] ?? pidx,
        'purchaseOrderName': 'Krishi Link Order',
      };
      await _storePaymentRecord(payload);
      onSuccess(payload['transactionId'] as String);
      try {
        if (Get.isRegistered<CartController>()) {
          Get.find<CartController>().clearCart();
        }
      } catch (_) {}
      PopupService.success('Payment successful!');
      if (Get.currentRoute != '/buyer-dashboard') {
        Get.offAllNamed('/buyer-dashboard');
      }
      return true;
    }
    try {
      final payConfig = KhaltiPayConfig(
        publicKey: _khaltiPublicKey,
        pidx: pidx,
        environment: Environment.test,
      );

      final khalti = await Khalti.init(
        enableDebugging: true,
        payConfig: payConfig,
        onPaymentResult: (paymentResult, khalti) async {
          final payload = paymentResult.payload;
          if (payload != null && payload.transactionId != null) {
            await _storePaymentRecord(payload);
            onSuccess(payload.transactionId!);
            // Close Khalti UI
            khalti.close(Get.context!);
            // Clear cart and navigate to dashboard
            try {
              if (Get.isRegistered<CartController>()) {
                Get.find<CartController>().clearCart();
              }
            } catch (_) {}
            PopupService.success('Payment successful!');
            // End payment session per config
            PaymentConfig.navigateAfterSuccess();
          }
        },
        onMessage: (
          khalti, {
          description,
          statusCode,
          event,
          needsPaymentConfirmation,
        }) async {
          if (needsPaymentConfirmation == true) {
            try {
              await khalti.verify();
            } catch (e) {
              debugPrint('[Payment] Verification failed: $e');
            }
          }
          if (event != null && event != KhaltiEvent.unknown) {
            onFailure(description?.toString() ?? 'Payment failed');
          }
        },
        onReturn: () {
          debugPrint('[Payment] Successfully redirected to return_url');
        },
      );

      khalti.open(Get.context!);
      return true;
    } catch (e) {
      onFailure('Failed to initialize payment: $e');
      return false;
    }
  }

  /// Store payment record locally (for PaymentHistory screen)
  Future<void> _storePaymentRecord(dynamic payload) async {
    try {
      // Build a PaymentHistory entry using payload + pending context
      final ctx = _pendingContext ?? const {};
      final items = (ctx['items'] as List<CartItem>?) ?? <CartItem>[];
      final dynamicTotalAmount =
          (payload is Map) ? payload['totalAmount'] : payload.totalAmount;
      final totalAmount =
          (ctx['amount'] as double?) ??
          (dynamicTotalAmount is num ? (dynamicTotalAmount / 100.0) : 0.0);

      final history = PaymentHistory(
        id: (payload is Map)
            ? (payload['pidx'] ??
                    payload['transactionId'] ??
                    UniqueKey().toString())
                .toString()
            : (payload.pidx ??
                    payload.transactionId ??
                    UniqueKey().toString())
                .toString(),
        transactionId: (payload is Map)
            ? (payload['transactionId'] ?? '').toString()
            : (payload.transactionId ?? '').toString(),
        pidx: (payload is Map)
            ? (payload['pidx'] ?? '').toString()
            : (payload.pidx ?? '').toString(),
        totalAmount: totalAmount,
        status: (payload is Map)
            ? (payload['status'] ?? 'Completed').toString()
            : (payload.status ?? 'Completed').toString(),
        timestamp: DateTime.now(),
        fee: (payload is Map)
            ? ((payload['fee'] is num) ? (payload['fee'] / 100.0) : 0.0)
            : ((payload.fee is num) ? (payload.fee / 100.0) : 0.0),
        refunded: (payload is Map)
            ? (payload['refunded'] == true)
            : payload.refunded == true,
        purchaseOrderId: (payload is Map)
            ? payload['purchaseOrderId']?.toString()
            : payload.purchaseOrderId?.toString(),
        purchaseOrderName: (payload is Map)
            ? payload['purchaseOrderName']?.toString()
            : payload.purchaseOrderName?.toString(),
        items: items,
        customerName: (ctx['customerName'] as String?) ?? '',
        customerPhone: (ctx['customerPhone'] as String?) ?? '',
        customerEmail: ctx['customerEmail'] as String?,
        deliveryAddress: (ctx['deliveryAddress'] as String?) ?? '',
        latitude: (ctx['latitude'] as double?) ?? 0.0,
        longitude: (ctx['longitude'] as double?) ?? 0.0,
      );

      // Also write to Hive for robust local storage
      try {
        await PaymentHistoryLocalDataSource.instance.add(history);
      } catch (e) {
        debugPrint('[Payment] Hive store failed: $e');
      }

      // Clear pending context once stored
      _pendingContext = null;
    } catch (e) {
      debugPrint('[Payment] Failed to store payment record: $e');
    }
  }

  /// Get payment history (backward-compatible reader)
  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    try {
      // Prefer Hive-backed history
      final hiveList =
          await PaymentHistoryLocalDataSource.instance.getAllSortedDesc();
      return hiveList.map((e) => e.toJson()).toList();
    } catch (e) {
      debugPrint('[Payment] Failed to get payment history: $e');
      return [];
    }
  }

  /// Verify payment status
  Future<Map<String, dynamic>?> verifyPayment(String pidx) async {
    if (clientOnlySandbox) {
      return {
        'pidx': pidx,
        'status': 'Completed',
        'total_amount':
            ((_pendingContext?['amount'] as double? ?? 0.0) * 100).round(),
      };
    }
    return executeApiCall(() async {
      final response = await apiClient.post(
        'https://dev.khalti.com/api/v2/epayment/lookup/',
        data: {'pidx': pidx},
        options: Options(headers: {'Authorization': 'key $_khaltiSecretKey'}),
      );

      return response.data as Map<String, dynamic>?;
    });
  }

  /// Backward compatibility method for startKhaltiSdkPaymentDirect
  Future<bool> startKhaltiSdkPaymentDirect({
    required List<CartItem> items,
    required double amount,
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    String? deliveryAddress,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await initiatePayment(
        items: items,
        amount: amount,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        deliveryAddress: deliveryAddress,
        latitude: latitude,
        longitude: longitude,
      );

      // Launch Khalti payment with the pidx
      final launched = await launchPayment(
        pidx: response.pidx,
        onSuccess: (transactionId) {
          debugPrint('Payment successful: $transactionId');
        },
        onFailure: (error) {
          debugPrint('Payment failed: $error');
        },
        onCancel: () {
          debugPrint('Payment cancelled');
        },
      );
      return launched;
    } catch (e) {
      debugPrint('Error in startKhaltiSdkPaymentDirect: $e');
      return false;
    }
  }

  /// Backward compatibility method for openKhaltiPayment
  void openKhaltiPayment() {
    // This was likely a simple method to open Khalti
    // In the new implementation, the payment URL is launched directly
    debugPrint(
      'openKhaltiPayment called - payment should be handled via initiatePayment + launchPayment',
    );
  }
}