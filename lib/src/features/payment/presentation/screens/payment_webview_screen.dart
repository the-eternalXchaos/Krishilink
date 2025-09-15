import 'package:flutter/material.dart';

class PaymentWebViewScreen extends StatelessWidget {
  final String url;
  const PaymentWebViewScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Center(child: Text('Open web view for: $url')),
    );
  }
}
