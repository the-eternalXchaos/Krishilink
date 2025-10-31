import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/features/auth/controller/cart_controller.dart';
import 'package:krishi_link/src/core/constants/api_constants.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String pidx;
  final bool clearCartOnSuccess;

  const PaymentWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.pidx,
    this.clearCartOnSuccess = true,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (url) => setState(() => _isLoading = true),
              onPageFinished: (url) => setState(() => _isLoading = false),
              onNavigationRequest: (req) {
                final url = req.url;
                if (url.startsWith(ApiConstants.paymentSuccessEndpoint)) {
                  _handleSuccess();
                  return NavigationDecision.prevent;
                }
                if (url.startsWith(ApiConstants.paymentFailureEndpoint)) {
                  _handleFailure();
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _handleSuccess() {
    try {
      if (widget.clearCartOnSuccess && Get.isRegistered<CartController>()) {
        Get.find<CartController>().clearCart();
      }
    } catch (_) {}
    PopupService.success('Payment successful!');
    Get.offAllNamed('/buyer-dashboard');
  }

  void _handleFailure() {
    PopupService.error('Payment failed or cancelled.');
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khalti Payment'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
