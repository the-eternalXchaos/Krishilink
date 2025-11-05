import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/features/auth/controller/cart_controller.dart';
import 'package:krishi_link/src/core/constants/api_constants.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  }) : assert(
         url != null || htmlContent != null,
         'Either url or htmlContent must be provided',
       );

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  // Track last URL to aid debugging and potential conditional flows
  String _lastUrl = '';
  bool _handledResult = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (url) {
                _lastUrl = url;
                setState(() => _isLoading = true);
                if (kDebugMode) debugPrint('[WebView][START] $url');
              },
              onPageFinished: (url) {
                _lastUrl = url;
                setState(() => _isLoading = false);
                if (kDebugMode) debugPrint('[WebView][FINISH] $url');
                // Allow backend success/failure endpoints to load, then handle
                if (!_handledResult &&
                    widget.successUrls.any((s) => url.startsWith(s))) {
                  _handledResult = true;
                  Future.delayed(
                    const Duration(milliseconds: 300),
                    _handleSuccess,
                  );
                } else if (!_handledResult &&
                    widget.failureUrls.any((f) => url.startsWith(f))) {
                  _handledResult = true;
                  Future.delayed(
                    const Duration(milliseconds: 300),
                    _handleFailure,
                  );
                }
              },
              onWebResourceError: (error) {
                if (kDebugMode) {
                  debugPrint(
                    '[WebView][ERROR] ${error.errorCode} ${error.description}',
                  );
                }
                if (!_handledResult) {
                  setState(() {
                    _isLoading = false;
                    _errorMessage = error.description;
                  });

                  if (error.errorType ==
                      WebResourceErrorType.failedSslHandshake) {
                    PopupService.error(
                      'Secure connection to the payment gateway failed. Please verify the SSL certificate or try again later.',
                    );
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) Navigator.of(context).maybePop();
                    });
                  }
                }
              },
              onNavigationRequest: (req) {
                // Always allow navigation so backend can receive callbacks
                _lastUrl = req.url;
                if (kDebugMode) debugPrint('[WebView][NAV] ${req.url}');
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
        title: Text('Payment${_lastUrl.isNotEmpty ? '' : ''}'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (_errorMessage != null)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
          if (kDebugMode)
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Opacity(
                opacity: 0.85,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'URL: ${_lastUrl.isEmpty ? '...' : _lastUrl}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
