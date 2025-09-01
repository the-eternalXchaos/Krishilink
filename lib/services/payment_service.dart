import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/features/admin/models/cart_item.dart';

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
  static const String _khaltiPublicKey = 'test_public_key_1234567890';
  static const String _khaltiSecretKey = 'test_secret_key_1234567890';
  static const String _khaltiBaseUrl = 'https://a.khalti.com/api/v2';

  final Dio _dio = Dio();
  MockKhalti? _khalti;

  @override
  void onInit() {
    super.onInit();
    _initializeKhalti();
  }

  void _initializeKhalti() {
    try {
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

  Future<String?> initiatePayment({
    required List<CartItem> items,
    required double amount,
    required String customerName,
    required String customerPhone,
    String? customerEmail,
  }) async {
    try {
      // Generate mock pidx
      final pidx = await _generatePidx(
        amount: amount,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        items: items,
      );

      if (pidx != null) {
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
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // Generate mock pidx
      final random = Random();
      final pidx =
          'pidx_${random.nextInt(999999)}_${DateTime.now().millisecondsSinceEpoch}';

      return pidx;
    } catch (e) {
      PopupService.error('Failed to generate payment ID: $e');
    }
    return null;
  }

  void _handlePaymentResult(MockPaymentResult paymentResult) {
    try {
      final payload = paymentResult.payload;
      if (payload != null) {
        // Store payment record
        _storePaymentRecord(payload);

        PopupService.success(
          'Payment successful! Transaction ID: ${payload.transactionId}',
        );

        // Navigate back to home or order confirmation
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
      if (_khalti != null) {
        await _khalti!.verify();
      }
    } catch (e) {
      PopupService.error('Payment verification failed: $e');
    }
  }

  Future<void> _storePaymentRecord(MockPaymentPayload payload) async {
    try {
      // Store payment record in local storage or database
      final paymentRecord = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'transactionId': payload.transactionId,
        'pidx': payload.pidx,
        'totalAmount': payload.totalAmount,
        'status': payload.status,
        'timestamp': DateTime.now().toIso8601String(),
        'fee': payload.fee,
        'refunded': payload.refunded,
        'purchaseOrderId': payload.purchaseOrderId,
        'purchaseOrderName': payload.purchaseOrderName,
        'items': [], // TODO: Store actual items
        'customerName': 'Customer', // TODO: Get from auth
        'customerPhone': '9800000000', // TODO: Get from form
        'customerEmail': 'customer@example.com', // TODO: Get from auth
        'deliveryAddress': 'Kathmandu, Nepal', // TODO: Get from form
        'latitude': 27.7172, // TODO: Get from location picker
        'longitude': 85.3240, // TODO: Get from location picker
      };

      // You can store this in SharedPreferences, Hive, or your database
      // For now, we'll just log it
      print('Payment Record: ${jsonEncode(paymentRecord)}');
    } catch (e) {
      print('Failed to store payment record: $e');
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
}
