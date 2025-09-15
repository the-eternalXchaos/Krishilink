import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/controllers/direct_payment_controller.dart';

/// Simple test widget for direct Khalti payments
class DirectPaymentTestWidget extends StatelessWidget {
  const DirectPaymentTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DirectPaymentController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Direct Khalti Payment Test'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test Khalti Payment (No Backend Required)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Test Connection Button
            ElevatedButton.icon(
              onPressed: () async {
                final isConnected = await controller.testKhaltiConnection();
                Get.snackbar(
                  'Connection Test',
                  isConnected
                      ? 'Khalti API is reachable!'
                      : 'Failed to connect to Khalti API',
                  backgroundColor: isConnected ? Colors.green : Colors.red,
                  colorText: Colors.white,
                );
              },
              icon: const Icon(Icons.network_check),
              label: const Text('Test Khalti Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // Sample Payment Button
            Obx(
              () => ElevatedButton.icon(
                onPressed:
                    controller.isProcessingPayment.value
                        ? null
                        : () => controller.testPayment(),
                icon:
                    controller.isProcessingPayment.value
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.payment),
                label: Text(
                  controller.isProcessingPayment.value
                      ? 'Processing...'
                      : 'Test Payment (Rs. 1500)',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Custom Payment Button
            ElevatedButton.icon(
              onPressed: () => _showCustomPaymentDialog(controller),
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Custom Payment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // Payment History Button
            ElevatedButton.icon(
              onPressed: () async {
                final history = await controller.getPaymentHistory();
                _showPaymentHistory(history);
              },
              icon: const Icon(Icons.history),
              label: const Text('View Payment History'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            // Last Transaction ID
            Obx(
              () =>
                  controller.lastTransactionId.value.isNotEmpty
                      ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          border: Border.all(color: Colors.green),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Last Transaction:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(controller.lastTransactionId.value),
                          ],
                        ),
                      )
                      : const SizedBox.shrink(),
            ),

            const SizedBox(height: 20),

            // Instructions
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Instructions:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '1. Test connection first to ensure Khalti API is reachable',
                      ),
                      Text(
                        '2. Use "Test Payment" for a quick test with sample items',
                      ),
                      Text('3. Use "Custom Payment" to enter your own details'),
                      Text(
                        '4. This works without your backend - perfect for testing!',
                      ),
                      Text(
                        '5. All payments are in TEST mode - no real money charged',
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Test Khalti Credentials:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('• Test Number: 9800000000'),
                      Text('• OTP: 123456'),
                      Text('• MPIN: 1111'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomPaymentDialog(DirectPaymentController controller) {
    final nameController = TextEditingController(text: 'John Doe');
    final phoneController = TextEditingController(text: '9800000000');
    final emailController = TextEditingController(text: 'john@example.com');
    final amountController = TextEditingController(text: '500');

    Get.dialog(
      AlertDialog(
        title: const Text('Custom Payment'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Customer Name'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (Optional)',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount (Rs.)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0.0;
              if (amount > 0) {
                Get.back();
                controller.processDirectPayment(
                  cartItems: controller.createSampleCartItems(),
                  totalAmount: amount,
                  customerName: nameController.text,
                  customerPhone: phoneController.text,
                  customerEmail:
                      emailController.text.isEmpty
                          ? null
                          : emailController.text,
                );
              }
            },
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
  }

  void _showPaymentHistory(List<Map<String, dynamic>> history) {
    Get.dialog(
      AlertDialog(
        title: const Text('Payment History'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child:
              history.isEmpty
                  ? const Center(child: Text('No payment history found'))
                  : ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final payment = history[index];
                      return Card(
                        child: ListTile(
                          title: Text(
                            'Transaction: ${payment['transactionId'] ?? 'N/A'}',
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Amount: Rs. ${payment['totalAmount'] ?? 'N/A'}',
                              ),
                              Text('Status: ${payment['status'] ?? 'N/A'}'),
                              Text('Date: ${payment['timestamp'] ?? 'N/A'}'),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }
}
