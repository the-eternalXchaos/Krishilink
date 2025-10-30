import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/features/auth/controller/cart_controller.dart';

/// Flexible payment webview that supports either loading a URL
/// or an HTML form that auto-submits (e.g., eSewa form POST).
class PaymentWebViewScreen extends StatefulWidget {
  final String? url;
  final String? htmlContent;
  final List<String> successUrls;
  final List<String> failureUrls;
  final bool clearCartOnSuccess;

  const PaymentWebViewScreen({
    super.key,
    this.url,
    this.htmlContent,
    this.successUrls = const [
      ApiConstants.paymentSuccessEndpoint,
      ApiConstants.esewaSuccessEndpoint,
    ],
    this.failureUrls = const [
      ApiConstants.paymentFailureEndpoint,
      ApiConstants.esewaFailureEndpoint,
    ],
    this.clearCartOnSuccess = true,
  }) : assert(url != null || htmlContent != null,
            'Either url or htmlContent must be provided');

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => setState(() => _isLoading = true),
          onPageFinished: (url) => setState(() => _isLoading = false),
          onNavigationRequest: (req) {
            final url = req.url;
            if (widget.successUrls.any((s) => url.startsWith(s))) {
              _handleSuccess();
              return NavigationDecision.prevent;
            }
            if (widget.failureUrls.any((f) => url.startsWith(f))) {
              _handleFailure();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    if (widget.htmlContent != null) {
      _controller.loadHtmlString(widget.htmlContent!);
    } else if (widget.url != null) {
      _controller.loadRequest(Uri.parse(widget.url!));
    }
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
        title: const Text('Payment'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
