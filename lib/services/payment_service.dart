import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:khalti_checkout_flutter/khalti_checkout_flutter.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/features/admin/models/cart_item.dart';
import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/services/api_services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:khalti/khalti.dart' hide Khalti;

// Mock classes to simulate Khalti SDK
class MockKhaltiPayConfig {
  final String publicKey;
  final String pidx;
  final MockEnvironment environment;

  MockKhaltiPayConfig({
    required this.publicKey,
    required this.pidx,
    required this.environment,
  });
}

enum MockEnvironment { test, prod }

class MockPaymentResult {
  final MockPaymentPayload? payload;
  final MockKhalti khalti;

  MockPaymentResult({this.payload, required this.khalti});
}

class MockPaymentPayload {
  final String? transactionId;
  final String? pidx;
  final double? totalAmount;
  final String? status;
  final double? fee;
  final bool? refunded;
  final String? purchaseOrderId;
  final String? purchaseOrderName;

  MockPaymentPayload({
    this.transactionId,
    this.pidx,
    this.totalAmount,
    this.status,
    this.fee,
    this.refunded,
    this.purchaseOrderId,
    this.purchaseOrderName,
  });
}

enum MockKhaltiEvent {
  kpgDisposed,
  returnUrlLoadFailure,
  networkFailure,
  paymentLookupfailure,
  unknown,
}

class MockKhalti {
  final MockKhaltiPayConfig payConfig;
  final Function(MockPaymentResult, MockKhalti) onPaymentResult;
  final Function(
    MockKhalti, {
    String? description,
    int? statusCode,
    MockKhaltiEvent? event,
    bool? needsPaymentConfirmation,
  })
  onMessage;
  final VoidCallback onReturn;

  MockKhalti({
    required this.payConfig,
    required this.onPaymentResult,
    required this.onMessage,
    required this.onReturn,
  });

  void open(BuildContext context) {
    // Simulate opening payment interface
    _simulatePaymentProcess();
  }

  void close(BuildContext context) {
    // Simulate closing payment interface
    Get.back();
  }

  Future<void> verify() async {
    // Simulate payment verification
    await Future.delayed(const Duration(seconds: 2));
  }

  void _simulatePaymentProcess() async {
    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 3));

    // Simulate successful payment
    final random = Random();
    final transactionId = 'TXN${random.nextInt(999999)}';

    final payload = MockPaymentPayload(
      transactionId: transactionId,
      pidx: payConfig.pidx,
      totalAmount: 1000.0, // Mock amount
      status: 'Completed',
      fee: 10.0,
      refunded: false,
      purchaseOrderId: 'PO${random.nextInt(999999)}',
      purchaseOrderName: 'Krishi Link Order',
    );

    final result = MockPaymentResult(payload: payload, khalti: this);
    onPaymentResult(result, this);
  }
}

class PaymentService extends GetxService {
  static PaymentService get to => Get.find();

  // Mock Khalti configuration
  static const String _khaltiPublicKey = 'e642a0a852084ab5b1b500b5aea0a99e';
  static const String _khaltiSecretKey = '21c193a64b724d3ebfa943246872eee5';
  static const String _khaltiBaseUrl = 'https://a.khalti.com/api/v2';

  final Dio _dio = Dio();
  MockKhalti? _khalti;
  Map<String, dynamic>? _currentCheckoutContext;
  Future<Khalti>? _khaltiSdkFuture;
  String? _activePidx;

  @override
  void onInit() {
    super.onInit();
    _initializeKhalti();
  }

  void _initializeKhalti() {
    try {
      debugPrint('[MockKhalti] initiatePayment called (local mock)');
      _khalti = MockKhalti(
        payConfig: MockKhaltiPayConfig(
          publicKey: _khaltiPublicKey,
          pidx: '', // Will be set when initiating payment
          environment: MockEnvironment.test,
        ),
        onPaymentResult: (paymentResult, khalti) {
          _handlePaymentResult(paymentResult);
        },
        onMessage: (
          khalti, {
          description,
          statusCode,
          event,
          needsPaymentConfirmation,
        }) async {
          _handlePaymentMessage(
            description: description,
            statusCode: statusCode,
            event: event,
            needsPaymentConfirmation: needsPaymentConfirmation,
          );
        },
        onReturn: () {
          PopupService.success('Payment completed successfully!');
        },
      );
    } catch (e) {
      PopupService.error('Failed to initialize Khalti: $e');
    }
  }

  // ---------------- DIRECT DEV KHALTI (NO BACKEND) ----------------
  /// Initiates a KPG session directly against Khalti's Sandbox API using
  /// the merchant secret key (for development only), then opens the official
  /// Khalti SDK UI. On success, saves payment locally and navigates home.
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
      debugPrint('[MockKhalti] initiatePayment called (local mock)');
      // Save context for later record persistence
      _currentCheckoutContext = {
        'items':
            items
                .map(
                  (e) => {
                    'id': e.id,
                    'name': e.name,
                    'price': e.price,
                    'quantity': e.quantity,
                  },
                )
                .toList(),
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerEmail': customerEmail,
        'deliveryAddress': deliveryAddress,
        'latitude': latitude,
        'longitude': longitude,
        'amount': amount,
      };

      final int amountPaisa = (amount * 100).round();
      final purchaseOrderId =
          'KL-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
      final body = {
        'return_url': 'https://example.com/payment/',
        'website_url': 'https://example.com/',
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
      };

      final resp = await _dio.post(
        'https://dev.khalti.com/api/v2/epayment/initiate/',
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'key $_khaltiSecretKey',
          },
        ),
      );

      if (resp.statusCode != 200 || resp.data == null) {
        PopupService.error('Failed to initiate Khalti payment (dev)');
        return false;
      }

      final data = resp.data is Map ? resp.data as Map : {};
      final pidx = data['pidx'] as String?;
      if (pidx == null || pidx.isEmpty) {
        PopupService.error('Khalti did not return pidx');
        return false;
      }
      _activePidx = pidx;

      final payConfig = KhaltiPayConfig(
        publicKey: _khaltiPublicKey,
        pidx: pidx,
        environment: Environment.test,
      );

      _khaltiSdkFuture = Khalti.init(
        enableDebugging: true,
        payConfig: payConfig,
        onPaymentResult: (paymentResult, k) async {\n          try {
      debugPrint('[MockKhalti] initiatePayment called (local mock)');\n            final payload = paymentResult.payload;\n            if (payload != null) {\n              debugPrint('[KhaltiSDK] onPaymentResult status=' + (payload.status ?? '') + ', txnId=' + (payload.transactionId ?? ''));\n              final mockPayload = MockPaymentPayload(
                transactionId: payload.transactionId,
                pidx: payload.pidx,
                totalAmount: (payload.totalAmount?.toDouble()),
                status: payload.status,
                fee: (payload.fee?.toDouble()),
                refunded: payload.refunded,
                purchaseOrderId: payload.purchaseOrderId,
                purchaseOrderName: payload.purchaseOrderName,
              );
              await _storePaymentRecord(mockPayload);
              PopupService.success(
                'Payment successful! Transaction ID: ${payload.transactionId}',
              );
              try {
      debugPrint('[MockKhalti] initiatePayment called (local mock)');
                k.close(Get.context!);
              } catch (_) {}
              debugPrint('[KhaltiSDK] Navigating to /buyer-dashboard');
              Get.offAllNamed('/buyer-dashboard');
            }
          } catch (e) {
            PopupService.error('Error processing payment: $e');
          }
        },
        onMessage: (
          k, {
          description,
          statusCode,
          event,
          needsPaymentConfirmation,
        }) async {
          if (needsPaymentConfirmation == true) {
            try {
      debugPrint('[MockKhalti] initiatePayment called (local mock)');
              await k.verify();
            } catch (e) {
              PopupService.error('Verification failed: $e');
            }
          } else if (event != null) {
            switch (event) {
              case KhaltiEvent.kpgDisposed:
                PopupService.info('Payment page closed');
                break;
              case KhaltiEvent.returnUrlLoadFailure:
                PopupService.error('Failed to load return URL');
                break;
              case KhaltiEvent.networkFailure:
                PopupService.error('Network error occurred');
                break;
              case KhaltiEvent.paymentLookupfailure:
                PopupService.error('Payment verification failed');
                break;
              case KhaltiEvent.unknown:
                PopupService.error('Unknown payment error');
                break;
            }
          }
        },
        onReturn: () {
          PopupService.info('Returned from Khalti');
        },
      );

      final sdk = await _khaltiSdkFuture!;
      sdk.open(Get.context!);
      return true;
    } catch (e) {
      PopupService.error('Failed to start Khalti SDK: $e');
      return false;
    }
  }

  Future<String?> initiatePayment({
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
      debugPrint('[MockKhalti] initiatePayment called (local mock)');
      // Stash context for record persistence
      _currentCheckoutContext = {
        'items':
            items
                .map(
                  (e) => {
                    'id': e.id,
                    'name': e.name,
                    'price': e.price,
                    'quantity': e.quantity,
                  },
                )
                .toList(),
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerEmail': customerEmail,
        'deliveryAddress': deliveryAddress,
        'latitude': latitude,
        'longitude': longitude,
        'amount': amount,
      };
      // Generate mock pidx
      final pidx = await _generatePidx(
        amount: amount,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        items: items,
      );

      if (pidx != null) {
        debugPrint('[MockKhalti] Generated pidx=' + pidx);
        // Update Khalti configuration with new pidx
        _khalti = MockKhalti(
          payConfig: MockKhaltiPayConfig(
            publicKey: _khaltiPublicKey,
            pidx: pidx,
            environment: MockEnvironment.test,
          ),
          onPaymentResult: (paymentResult, khalti) {
            _handlePaymentResult(paymentResult);
          },
          onMessage: (
            khalti, {
            description,
            statusCode,
            event,
            needsPaymentConfirmation,
          }) async {
            _handlePaymentMessage(
              description: description,
              statusCode: statusCode,
              event: event,
              needsPaymentConfirmation: needsPaymentConfirmation,
            );
          },
          onReturn: () {
            PopupService.success('Payment completed successfully!');
          },
        );
        debugPrint('[MockKhalti] Ready to open mock Khalti with pidx=' + pidx);
        return pidx;
      }
    } catch (e) {
      PopupService.error('Failed to initiate payment: $e');
    }
    return null;
  }

  Future<String?> _generatePidx({
    required double amount,
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    required List<CartItem> items,
  }) async {
    try {
      debugPrint('[MockKhalti] initiatePayment called (local mock)');
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // Generate mock pidx
      final random = Random();
      final pidx =
          'pidx_${random.nextInt(999999)}_${DateTime.now().millisecondsSinceEpoch}';

      debugPrint('[MockKhalti] Ready to open mock Khalti with pidx=' + pidx);
        return pidx;
    } catch (e) {
      PopupService.error('Failed to generate payment ID: $e');
    }
    return null;
  }

  void _handlePaymentResult(MockPaymentResult paymentResult) {
    try {
      debugPrint('[MockKhalti] initiatePayment called (local mock)');
      final payload = paymentResult.payload;
      if (payload != null) {
        // Store payment record
        _storePaymentRecord(payload);

        PopupService.success(
          'Payment successful! Transaction ID: ${payload.transactionId}',
        );

        // Navigate back to home or order confirmation
        debugPrint('[KhaltiSDK] Navigating to /buyer-dashboard');
              Get.offAllNamed('/buyer-dashboard');
      }
    } catch (e) {
      PopupService.error('Error processing payment result: $e');
    }
  }

  void _handlePaymentMessage({
    String? description,
    int? statusCode,
    MockKhaltiEvent? event,
    bool? needsPaymentConfirmation,
  }) {
    if (needsPaymentConfirmation == true) {
      // Verify payment status
      _verifyPayment();
    } else if (event != null) {
      switch (event) {
        case MockKhaltiEvent.kpgDisposed:
          PopupService.info('Payment page closed');
          break;
        case MockKhaltiEvent.returnUrlLoadFailure:
          PopupService.error('Failed to load return URL');
          break;
        case MockKhaltiEvent.networkFailure:
          PopupService.error('Network error occurred');
          break;
        case MockKhaltiEvent.paymentLookupfailure:
          PopupService.error('Payment verification failed');
          break;
        case MockKhaltiEvent.unknown:
          PopupService.error('Unknown error occurred');
          break;
      }
    }
  }

  Future<void> _verifyPayment() async {
    try {
      debugPrint('[MockKhalti] initiatePayment called (local mock)');
      if (_khalti != null) {
        await _khalti!.verify();
      }
    } catch (e) {
      PopupService.error('Payment verification failed: $e');
    }
  }

  Future<void> _storePaymentRecord(MockPaymentPayload payload) async {
    try {
      debugPrint('[MockKhalti] initiatePayment called (local mock)');
      // Build payment record and persist locally
      final ctx = _currentCheckoutContext ?? {};
      final paymentRecord = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'transactionId': payload.transactionId,
        'pidx': payload.pidx,
        'totalAmount': payload.totalAmount ?? ctx['amount'],
        'status': payload.status,
        'timestamp': DateTime.now().toIso8601String(),
        'fee': payload.fee,
        'refunded': payload.refunded,
        'purchaseOrderId': payload.purchaseOrderId,
        'purchaseOrderName': payload.purchaseOrderName,
        'items': ctx['items'] ?? [],
        'customerName': ctx['customerName'] ?? 'Customer',
        'customerPhone': ctx['customerPhone'] ?? '9800000000',
        'customerEmail': ctx['customerEmail'] ?? 'customer@example.com',
        'deliveryAddress': ctx['deliveryAddress'] ?? 'Kathmandu, Nepal',
        'latitude': ctx['latitude'] ?? 27.7172,
        'longitude': ctx['longitude'] ?? 85.3240,
      };

      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString('payment_history');
      List<dynamic> list = [];
      if (existing != null && existing.isNotEmpty) {
        try {
      debugPrint('[MockKhalti] initiatePayment called (local mock)');
          list = jsonDecode(existing) as List<dynamic>;
        } catch (_) {
          list = [];
        }
      }
      list.insert(0, paymentRecord);
      await prefs.setString('payment_history', jsonEncode(list));

      debugPrint('Saved payment record locally (${payload.transactionId})');
    } catch (e) {
      debugPrint('Failed to store payment record: $e');
    }
  }

  void openKhaltiPayment() {
    if (_khalti != null) {
      _khalti!.open(Get.context!);
    } else {
      PopupService.error('Khalti payment is not initialized');
    }
  }

  void closeKhaltiPayment() {
    if (_khalti != null) {
      _khalti!.close(Get.context!);
    }
  }

  @override
  void onClose() {
    _khalti = null;
    super.onClose();
  }

  // ---------------- REAL KPG (TEST) VIA BACKEND + BROWSER ----------------
  /// Calls your backend to create a Khalti KPG session (pidx) and returns
  /// a map containing at least: {'paymentUrl': ..., 'pidx': ...}
  Future<Map<String, String>?> createKhaltiPaymentSession({
    required List<CartItem> items,
    required double amount,
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    bool showErrorOnFail = true,
  }) async {
    try {
      debugPrint('[MockKhalti] initiatePayment called (local mock)');
      final api = ApiService();
      final body = {
        'amount': (amount * 100).round(), // paisa
        'customerName': customerName,
        'customerPhone': customerPhone,
        if (customerEmail != null) 'customerEmail': customerEmail,
        'items':
            items
                .map(
                  (e) => {
                    'id': e.id,
                    'name': e.name,
                    'price': e.price,
                    'quantity': e.quantity,
                  },
                )
                .toList(),
      };

      final resp = await api.dio.post(
        ApiConstants.initiatePaymentEndpoint,
        data: body,
        options: await api.getJsonOptions(),
      );

      final data = resp.data;
      String? url;
      String? pidx;
      if (data is Map) {
        final d = data['data'] ?? data;
        url = d['paymentUrl'] ?? d['payment_url'] ?? d['paymentURL'];
        pidx = d['pidx'] ?? d['PIDX'] ?? d['Pidx'];
      }
      if (url != null && pidx != null) {
        return {'paymentUrl': url, 'pidx': pidx};
      }
      if (showErrorOnFail) {
        PopupService.error('Failed to parse payment session from server');
      } else {
        debugPrint('Failed to parse payment session from server');
      }
    } catch (e) {
      if (showErrorOnFail) {
        PopupService.error('Failed to initiate payment: $e');
      } else {
        debugPrint('Failed to initiate payment: $e');
      }
    }
    return null;
  }

  /// Opens the payment URL in an external browser. For an in-app flow,
  /// navigate to a WebView screen to intercept success/failure URLs.
  Future<void> openPaymentUrl(String url, {String? pidx}) async {
    try {
      debugPrint('[MockKhalti] initiatePayment called (local mock)');
      // Prefer in-app WebView with URL interception
      await Get.toNamed(
        '/payment-webview',
        arguments: {'paymentUrl': url, 'pidx': pidx},
      );
    } catch (_) {
      // Fallback: external browser
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        PopupService.info('After completing payment, return to the app.');
      } else {
        PopupService.error('Cannot open payment page');
      }
    }
  }
}


