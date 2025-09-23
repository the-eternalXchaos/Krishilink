import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:krishi_link/src/features/payment/models/payment_history.dart';

class PaymentDetailsScreen extends StatelessWidget {
  final PaymentHistory payment;

  const PaymentDetailsScreen({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dateFormat = DateFormat('MMM dd, yyyy - HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text('payment_details'.tr),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment Status Card
            _buildStatusCard(colorScheme, textTheme),
            const SizedBox(height: 20),

            // Transaction Details
            _buildTransactionDetails(colorScheme, textTheme, dateFormat),
            const SizedBox(height: 20),

            // Customer Information
            _buildCustomerInfo(colorScheme, textTheme),
            const SizedBox(height: 20),

            // Items List
            _buildItemsList(colorScheme, textTheme),
            const SizedBox(height: 20),

            // Delivery Location
            _buildDeliveryLocation(colorScheme, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(ColorScheme colorScheme, TextTheme textTheme) {
    final isCompleted = payment.status.toLowerCase() == 'completed';

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.pending,
              size: 60,
              color: isCompleted ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 12),
            Text(
              payment.status,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isCompleted ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rs ${payment.totalAmount.toStringAsFixed(2)}',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionDetails(
    ColorScheme colorScheme,
    TextTheme textTheme,
    DateFormat dateFormat,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'transaction_details'.tr,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Transaction ID',
              payment.transactionId,
              colorScheme,
              textTheme,
            ),
            _buildDetailRow('PIDX', payment.pidx, colorScheme, textTheme),
            _buildDetailRow(
              'Purchase Order ID',
              payment.purchaseOrderId ?? 'N/A',
              colorScheme,
              textTheme,
            ),
            _buildDetailRow(
              'Date & Time',
              dateFormat.format(payment.timestamp),
              colorScheme,
              textTheme,
            ),
            _buildDetailRow(
              'Fee',
              'Rs ${payment.fee.toStringAsFixed(2)}',
              colorScheme,
              textTheme,
            ),
            _buildDetailRow(
              'Refunded',
              payment.refunded ? 'Yes' : 'No',
              colorScheme,
              textTheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo(ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'customer_information'.tr,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Name',
              payment.customerName,
              colorScheme,
              textTheme,
            ),
            _buildDetailRow(
              'Phone',
              payment.customerPhone,
              colorScheme,
              textTheme,
            ),
            if (payment.customerEmail != null)
              _buildDetailRow(
                'Email',
                payment.customerEmail!,
                colorScheme,
                textTheme,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'items'.tr,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (payment.items.isEmpty)
              Text(
                'No items available',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outline,
                ),
              )
            else
              ...payment.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Quantity: ${item.quantity}',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Rs ${(double.parse(item.price) * item.quantity).toStringAsFixed(2)}',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryLocation(ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'delivery_location'.tr,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Address',
              payment.deliveryAddress,
              colorScheme,
              textTheme,
            ),
            _buildDetailRow(
              'Latitude',
              payment.latitude.toStringAsFixed(6),
              colorScheme,
              textTheme,
            ),
            _buildDetailRow(
              'Longitude',
              payment.longitude.toStringAsFixed(6),
              colorScheme,
              textTheme,
            ),
            const SizedBox(height: 12),
            if (payment.latitude != 0 && payment.longitude != 0)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(payment.latitude, payment.longitude),
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('delivery_location'),
                        position: LatLng(payment.latitude, payment.longitude),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueOrange,
                        ),
                        infoWindow: InfoWindow(
                          title: 'Delivery Location',
                          snippet: payment.deliveryAddress,
                        ),
                      ),
                    },
                    mapType: MapType.normal,
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    compassEnabled: true,
                    mapToolbarEnabled: false,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.outline,
              ),
            ),
          ),
          Expanded(child: Text(value, style: textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
