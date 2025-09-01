import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:krishi_link/models/payment_history.dart';
import 'package:krishi_link/features/buyer/screens/payment_details_screen.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final List<PaymentHistory> paymentHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    setState(() {
      isLoading = true;
    });

    try {
      // TODO: Load payment history from local storage or database
      // For now, we'll create some mock data
      await Future.delayed(const Duration(seconds: 1));

      final mockHistory = [
        PaymentHistory(
          id: '1',
          transactionId: 'TXN123456',
          pidx: 'pidx_123456_1234567890',
          totalAmount: 1250.0,
          status: 'Completed',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          fee: 10.0,
          refunded: false,
          purchaseOrderId: 'PO123456',
          purchaseOrderName: 'Krishi Link Order',
          items: [],
          customerName: 'John Doe',
          customerPhone: '9800000000',
          customerEmail: 'john@example.com',
          deliveryAddress: 'Kathmandu, Nepal',
          latitude: 27.7172,
          longitude: 85.3240,
        ),
        PaymentHistory(
          id: '2',
          transactionId: 'TXN789012',
          pidx: 'pidx_789012_1234567890',
          totalAmount: 850.0,
          status: 'Completed',
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
          fee: 10.0,
          refunded: false,
          purchaseOrderId: 'PO789012',
          purchaseOrderName: 'Krishi Link Order',
          items: [],
          customerName: 'John Doe',
          customerPhone: '9800000000',
          customerEmail: 'john@example.com',
          deliveryAddress: 'Lalitpur, Nepal',
          latitude: 27.6667,
          longitude: 85.3333,
        ),
      ];

      setState(() {
        paymentHistory.clear();
        paymentHistory.addAll(mockHistory);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Show error message
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('payment_history'.tr),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPaymentHistory,
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : paymentHistory.isEmpty
              ? _buildEmptyState(colorScheme, textTheme)
              : _buildPaymentList(colorScheme, textTheme),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment_outlined, size: 80, color: colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'no_payment_history'.tr,
            style: textTheme.titleLarge?.copyWith(color: colorScheme.outline),
          ),
          const SizedBox(height: 8),
          Text(
            'your_payment_history_will_appear_here'.tr,
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentList(ColorScheme colorScheme, TextTheme textTheme) {
    return RefreshIndicator(
      onRefresh: _loadPaymentHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: paymentHistory.length,
        itemBuilder: (context, index) {
          final payment = paymentHistory[index];
          return _buildPaymentCard(payment, colorScheme, textTheme);
        },
      ),
    );
  }

  Widget _buildPaymentCard(
    PaymentHistory payment,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy - HH:mm');
    final isCompleted = payment.status.toLowerCase() == 'completed';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Get.to(() => PaymentDetailsScreen(payment: payment)),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transaction ID: ${payment.transactionId}',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(payment.timestamp),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isCompleted
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCompleted ? Colors.green : Colors.orange,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      payment.status,
                      style: textTheme.bodySmall?.copyWith(
                        color: isCompleted ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                        Text(
                          'Rs ${payment.totalAmount.toStringAsFixed(2)}',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Items',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                        Text(
                          '${payment.items.length} items',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                payment.deliveryAddress,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
