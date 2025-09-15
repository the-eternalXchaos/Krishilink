import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:khalti_checkout_flutter/khalti_checkout_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:krishi_link/src/features/payment/data/local/payment_history_local_data_source.dart';

import 'package:krishi_link/features/cart/models/cart_item.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/features/payment/models/payment_history.dart';
import 'package:krishi_link/features/auth/controller/cart_controller.dart';
import 'package:krishi_link/src/core/config/payment_config.dart';

/// Standalone Khalti Payment Service / sand box ,   backend api xaina so
///  , aba last ma payment history pani save garna parcha backend ma save garera rakhna sakiyo

class KhaltiDirectPaymentService {
  // Test API keys for development (replace with production keys later)
  static const String _khaltiPublicKeyTest = 'e642a0a852084ab5b1b500b5aea0a99e';
  static const String _khaltiSecretKeyTest = '21c193a64b724d3ebfa943246872eee5';

  final String _khaltiPublicKey;
  final String _khaltiSecretKey;
  late final Dio _dioClient;
  Map<String, dynamic>? _pendingContext;

  KhaltiDirectPaymentService({String? khaltiPublicKey, String? khaltiSecretKey})
    : _khaltiPublicKey = khaltiPublicKey ?? _khaltiPublicKeyTest,
      _khaltiSecretKey = khaltiSecretKey ?? _khaltiSecretKeyTest {
    // Create a separate Dio client for Khalti API (no backend auth)
    _dioClient = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        // Do NOT throw DioError for non-2xx; we will handle status codes ourselves
        validateStatus: (status) => true,
      ),
    );

    // Add logging interceptor for debugging
    _dioClient.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint('[Khalti API] $obj'),
      ),
    );
  }

  /// Initialize direct payment with Khalti (no backend needed)
  Future<String> initiateDirectPayment({
    required List<CartItem> items,
    required double amount,
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    String? deliveryAddress,
    double? latitude,
    double? longitude,
    Function(String transactionId)? onSuccess,
    Function(String error)? onFailure,
    Function()? onCancel,
  }) async {
    try {
      debugPrint('[Khalti] Starting direct payment for amount: Rs. $amount');

      final amountPaisa = (amount * 100).round();
      final purchaseOrderId =
          'KL-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';

      // Prepare payment request
      final paymentRequest = {
        'return_url': 'https://test.com/payment/success/',
        'website_url': 'https://test.com/',
        'amount': amountPaisa,
        'purchase_order_id': purchaseOrderId,
        'purchase_order_name': 'Krishi Link Order',
        'customer_info': {
          'name': customerName,
          if (customerEmail != null) 'email': customerEmail,
          'phone': customerPhone,
        },
        'product_details':
            items
                .map(
                  (item) => {
                    'identity': item.id,
                    'name': item.name,
                    'total_price':
                        (double.parse(item.price) * item.quantity * 100)
                            .round(),
                    'quantity': item.quantity,
                    'unit_price': (double.parse(item.price) * 100).round(),
                  },
                )
                .toList(),
      };

      debugPrint('[Khalti] Payment request: ${jsonEncode(paymentRequest)}');

      // Save context for history enrichment
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

      // Call Khalti API directly
      final response = await _dioClient.post(
        'https://dev.khalti.com/api/v2/epayment/initiate/',
        data: paymentRequest,
        options: Options(
          headers: {
            'Authorization': 'key $_khaltiSecretKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final pidx = response.data['pidx'] as String;
        debugPrint('[Khalti] Payment initiated successfully. PIDX: $pidx');

        // Launch payment UI
        await _launchKhaltiPayment(
          pidx: pidx,
          onSuccess:
              onSuccess ??
              (transactionId) {
                PopupService.success('Payment successful!');
                try {
                  if (Get.isRegistered<CartController>()) {
                    Get.find<CartController>().clearCart();
                  }
                } catch (_) {}
                PaymentConfig.navigateAfterSuccess();
              },
          onFailure:
              onFailure ??
              (error) {
                PopupService.error('Payment failed: $error');
              },
          onCancel:
              onCancel ??
              () {
                PopupService.info('Payment cancelled by user');
              },
        );

        return pidx;
      } else {
        if (response.statusCode == 401) {
          throw Exception(
            'Khalti returned 401 Invalid token. Please provide valid test keys '
            '(public/secret) from your merchant sandbox and pass them via '
            "--dart-define=KHALTI_PUBLIC_KEY=... --dart-define=KHALTI_SECRET_KEY=...",
          );
        }
        throw Exception(
          'Invalid response from Khalti API (status ${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('[Khalti] Payment initiation failed: $e');

      String errorMessage = 'Payment initialization failed';
      if (e is DioException) {
        if (e.response?.data != null) {
          final errorData = e.response!.data;
          if (errorData is Map && errorData.containsKey('detail')) {
            errorMessage = errorData['detail'].toString();
          } else if (errorData is Map && errorData.containsKey('message')) {
            errorMessage = errorData['message'].toString();
          }
        }
        errorMessage += ' (${e.response?.statusCode ?? 'Unknown'})';
      }

      // Help the developer quickly when keys are missing/invalid
      if (errorMessage.toLowerCase().contains('invalid token') ||
          errorMessage.contains('401')) {
        errorMessage =
            'Khalti sandbox keys invalid or missing. Set valid test keys via\n'
            '  --dart-define=KHALTI_PUBLIC_KEY=your_test_public_key\n'
            '  --dart-define=KHALTI_SECRET_KEY=your_test_secret_key\n'
            'and ensure Return/Website URLs are allowed in your Khalti merchant profile.';
      }

      if (onFailure != null) {
        onFailure(errorMessage);
      } else {
        PopupService.error(errorMessage);
      }

      throw Exception(errorMessage);
    }
  }

  /// Launch Khalti payment interface
  Future<bool> _launchKhaltiPayment({
    required String pidx,
    required Function(String transactionId) onSuccess,
    required Function(String error) onFailure,
    required Function() onCancel,
  }) async {
    try {
      final payConfig = KhaltiPayConfig(
        publicKey: _khaltiPublicKey,
        pidx: pidx,
        environment:
            Environment.test, // Change to Environment.prod for production
      );

      final khalti = await Khalti.init(
        enableDebugging: true,
        payConfig: payConfig,
        onPaymentResult: (paymentResult, khalti) async {
          debugPrint('[Khalti] Payment result received');
          final payload = paymentResult.payload;

          if (payload != null && payload.transactionId != null) {
            debugPrint('[Khalti] Payment successful: ${payload.transactionId}');

            // Store payment record locally
            await _storePaymentRecord(payload);

            // Call success callback
            onSuccess(payload.transactionId!);

            // Close Khalti
            khalti.close(Get.context!);
          } else {
            debugPrint('[Khalti] Payment result payload is null');
            onFailure('Payment verification failed');
          }
        },
        onMessage: (
          khalti, {
          description,
          statusCode,
          event,
          needsPaymentConfirmation,
        }) async {
          debugPrint(
            '[Khalti] Message received - Event: $event, Description: $description',
          );

          if (needsPaymentConfirmation == true) {
            try {
              debugPrint('[Khalti] Verifying payment...');
              await khalti.verify();
            } catch (e) {
              debugPrint('[Khalti] Verification failed: $e');
              onFailure('Payment verification failed: $e');
            }
          }

          // Handle events (simplified to avoid unknown constants)
          if (event != null && event != KhaltiEvent.unknown) {
            debugPrint(
              '[Khalti] Event received: $event, Description: $description',
            );
            if (description != null &&
                description.toString().toLowerCase().contains('cancel')) {
              onCancel();
            } else if (description != null &&
                description.toString().toLowerCase().contains('fail')) {
              onFailure(description.toString());
            }
          }
        },
        onReturn: () {
          debugPrint('[Khalti] Return URL triggered');
        },
      );

      // Open Khalti payment page
      khalti.open(Get.context!);
      return true;
    } catch (e) {
      debugPrint('[Khalti] Failed to launch payment: $e');
      onFailure('Failed to initialize payment: $e');
      return false;
    }
  }

  /// Store payment record locally in the format used by PaymentHistoryScreen
  Future<void> _storePaymentRecord(dynamic payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ctx = _pendingContext ?? const {};
      final items = (ctx['items'] as List<CartItem>?) ?? <CartItem>[];
      // Support both object payload and map payload
      final dynamicTotalAmount =
          (payload is Map) ? payload['totalAmount'] : payload.totalAmount;
      final totalAmount =
          (ctx['amount'] as double?) ??
          (dynamicTotalAmount is num ? (dynamicTotalAmount / 100.0) : 0.0);

      final history = PaymentHistory(
        id:
            (payload is Map)
                ? (payload['pidx'] ??
                        payload['transactionId'] ??
                        UniqueKey().toString())
                    .toString()
                : (payload.pidx ??
                        payload.transactionId ??
                        UniqueKey().toString())
                    .toString(),
        transactionId:
            (payload is Map)
                ? (payload['transactionId'] ?? '').toString()
                : (payload.transactionId ?? '').toString(),
        pidx:
            (payload is Map)
                ? (payload['pidx'] ?? '').toString()
                : (payload.pidx ?? '').toString(),
        totalAmount: totalAmount,
        status:
            (payload is Map)
                ? (payload['status'] ?? 'Completed').toString()
                : (payload.status ?? 'Completed').toString(),
        timestamp: DateTime.now(),
        fee:
            (payload is Map)
                ? ((payload['fee'] is num) ? (payload['fee'] / 100.0) : 0.0)
                : ((payload.fee is num) ? (payload.fee / 100.0) : 0.0),
        refunded:
            (payload is Map)
                ? (payload['refunded'] == true)
                : payload.refunded == true,
        purchaseOrderId:
            (payload is Map)
                ? payload['purchaseOrderId']?.toString()
                : payload.purchaseOrderId?.toString(),
        purchaseOrderName:
            (payload is Map)
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

      // Write to canonical JSON array key
      final jsonString = prefs.getString('payment_history');
      final List<dynamic> list =
          jsonString != null && jsonString.isNotEmpty
              ? (json.decode(jsonString) as List<dynamic>)
              : <dynamic>[];
      list.add(history.toJson());
      await prefs.setString('payment_history', json.encode(list));
      // Also write to Hive for robust local storage
      try {
        await PaymentHistoryLocalDataSource.instance.add(history);
      } catch (e) {
        debugPrint('[Khalti] Hive store failed: $e');
      }

      // Also write a compatible copy to legacy list key for older screens/tools
      final legacy = prefs.getStringList('khalti_payment_records') ?? [];
      legacy.add(
        json.encode({
          'transactionId': history.transactionId,
          'pidx': history.pidx,
          'totalAmount': (history.totalAmount * 100).round(), // store in paisa
          'status': history.status,
          'fee': (history.fee * 100).round(),
          'refunded': history.refunded,
          'purchaseOrderId': history.purchaseOrderId,
          'purchaseOrderName': history.purchaseOrderName,
          'timestamp': history.timestamp.toIso8601String(),
          'customerInfo': {
            'name': history.customerName,
            'email': history.customerEmail,
            'phone': history.customerPhone,
          },
        }),
      );
      await prefs.setStringList('khalti_payment_records', legacy);
      _pendingContext = null;
      debugPrint('[Khalti] Payment record stored to payment_history');
    } catch (e) {
      debugPrint('[Khalti] Failed to store payment record: $e');
    }
  }

  /// Get payment history from local storage (compat with legacy key)
  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    try {
      // Prefer Hive-backed history
      final hiveList =
          await PaymentHistoryLocalDataSource.instance.getAllSortedDesc();
      if (hiveList.isNotEmpty) {
        return hiveList.map((e) => e.toJson()).toList();
      }

      // Fallback to legacy SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('payment_history');
      if (jsonString != null && jsonString.isNotEmpty) {
        final arr = json.decode(jsonString) as List<dynamic>;
        return arr.whereType<Map<String, dynamic>>().toList().reversed.toList();
      }
      final records = prefs.getStringList('khalti_payment_records') ?? [];
      return records
          .map((r) => jsonDecode(r) as Map<String, dynamic>)
          .toList()
          .reversed
          .toList();
    } catch (e) {
      debugPrint('[Khalti] Failed to get payment history: $e');
      return [];
    }
  }

  /// Clear payment history
  Future<void> clearPaymentHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('khalti_payment_records');
      await prefs.remove('payment_history');
      // clear() is synchronous; remove await to avoid awaiting void
      PaymentHistoryLocalDataSource.instance.clear();
      debugPrint('[Khalti] Payment history cleared');
    } catch (e) {
      debugPrint('[Khalti] Failed to clear payment history: $e');
    }
  }

  /// Verify payment status directly with Khalti
  Future<Map<String, dynamic>?> verifyPayment(String pidx) async {
    try {
      final response = await _dioClient.post(
        'https://dev.khalti.com/api/v2/epayment/lookup/',
        data: {'pidx': pidx},
        options: Options(
          headers: {
            'Authorization': 'key $_khaltiSecretKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('[Khalti] Payment verification failed: $e');
      return null;
    }
  }

  /// Test connection to Khalti API
  Future<bool> testConnection() async {
    try {
      final response = await _dioClient.get('https://dev.khalti.com/api/v2/');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[Khalti] Connection test failed: $e');
      return false;
    }
  }
}
