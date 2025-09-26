// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:animate_do/animate_do.dart';
// import 'package:intl/intl.dart';
// import 'package:krishi_link/features/farmer/controller/farmer_controller.dart';
// import 'package:krishilinkapp/core/theme/app_theme.dart';
// import 'package:krishilinkapp/features/farmer/models.dart';
// import 'package:krishiilinkapp/features/farmer/controller/farmer_controller.dart';

// class OrderDetailsScreen extends StatelessWidget {
//   final OrderModel order;

//   const OrderDetailsScreen({super.key, required this.order});

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final controller = Get.find<FarmerController>();
//     final createdAt = order.createdAt ?? DateTime.now();

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Order Details'.tr, style: theme.textTheme.titleLarge),
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
//           onPressed: () => Get.back(),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             FadeInDown(
//               child: Text(
//                 'Order #${order.orderId}'.tr,
//                 style: theme.textTheme.headlineMedium,
//               ),
//             ),
//             const SizedBox(height: 16),
//             FadeInUp(
//               child: Card(
//                 elevation: 3,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Order Information'.tr,
//                         style: theme.textTheme.titleLarge,
//                       ),
//                       const SizedBox(height: 12),
//                       _buildDetailRow(
//                         context,
//                         icon: Icons.local_offer,
//                         label: 'Product'.tr,
//                         value:
//                             '${order.productName} (${order.productQuantity} ${order.unit})'
//                                 .tr,
//                       ),
//                       _buildDetailRow(
//                         context,
//                         icon: Icons.tag,
//                         label: 'Total Price'.tr,
//                         value: 'NPR ${order.totalPrice.toStringAsFixed(2)}'.tr,
//                       ),
//                       _buildDetailRow(
//                         context,
//                         icon: Icons.tag,
//                         label: 'Status'.tr,
//                         value: 'Status: ${order.orderStatus}'.tr,
//                         valueColor:
//                             order.orderStatus.toLowerCase() == 'delivered'
//                                 ? Colors.green
//                                 : Colors.orange,
//                       ),
//                       _buildDetailRow(
//                         context,
//                         icon: Icons.payment,
//                         label: 'Payment Status'.tr,
//                         value: order.paymentStatus.tr,
//                         valueColor:
//                             order.paymentStatus.toLowerCase() == 'completed'
//                                 ? Colors.green
//                                 : Colors.orange,
//                       ),
//                       if (order.refundStatus != null)
//                         _buildDetailRow(
//                           context,
//                           icon: Icons.money_off,
//                           label: 'Refund Status'.tr,
//                           value: order.refundStatus!.tr,
//                         ),
//                       _buildDetailRow(
//                         context,
//                         icon: Icons.calendar_today,
//                         label: 'Order Date'.tr,
//                         value: DateFormat(
//                           'MMM dd, yyyy, hh:mm a',
//                         ).format(createdAt),
//                       ),
//                       if (order.buyerName != null)
//                         _buildDetailRow(
//                           context,
//                           icon: Icons.person,
//                           label: 'Buyer'.tr,
//                           value: order.buyerName!.tr,
//                         ),
//                       if (order.buyerContact != null)
//                         _buildDetailRow(
//                           context,
//                           icon: Icons.phone,
//                           label: 'Buyer Contact'.tr,
//                           value: order.buyerContact!.tr,
//                         ),
//                       if (order.deliveryAddress != null)
//                         _buildDetailRow(
//                           context,
//                           icon: Icons.location_on,
//                           label: 'Delivery Address'.tr,
//                           value: order.deliveryAddress!.tr,
//                         ),
//                       if (order.deliveredAt != null)
//                         _buildDetailRow(
//                           context,
//                           icon: Icons.check_circle,
//                           label: 'Delivered On'.tr,
//                           value: DateFormat(
//                             'MMM dd, yyyy, hh:mm a',
//                           ).format(order.deliveredAt!),
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             FadeInUp(
//               delay: const Duration(milliseconds: 100),
//               child: Card(
//                 elevation: 3,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('Actions'.tr, style: theme.textTheme.titleLarge),
//                       const SizedBox(height: 12),
//                       if (order.orderStatus.toLowerCase() == 'pending' ||
//                           order.orderStatus.toLowerCase() == 'shipped')
//                         SizedBox(
//                           width: double.infinity,
//                           child: ElevatedButton(
//                             onPressed: () async {
//                               try {
//                                 await controller.updateOrderStatus(
//                                   orderId: order.orderId,
//                                   status: 'delivered',
//                                 );
//                                 Get.snackbar(
//                                   'Success'.tr,
//                                   'Order marked as delivered'.tr,
//                                 );
//                                 Get.back(
//                                   result: controller.orders.firstWhere(
//                                     (o) => o.orderId == order.orderId,
//                                   ),
//                                 );
//                               } catch (e) {
//                                 Get.snackbar(
//                                   'Error'.tr,
//                                   'Failed to update order: $e'.tr,
//                                 );
//                               }
//                             },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: theme.colorScheme.primary,
//                               foregroundColor: theme.colorScheme.onPrimary,
//                               padding: const EdgeInsets.symmetric(vertical: 16),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                             child: Text(
//                               'Mark as Delivered'.tr,
//                               style: theme.textTheme.labelLarge,
//                             ),
//                           ),
//                         ),
//                       if (order.orderStatus.toLowerCase() == 'delivered')
//                         Text(
//                           'Order has been delivered'.tr,
//                           style: theme.textTheme.bodyLarge?.copyWith(
//                             color: Colors.green,
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailRow(
//     BuildContext context, {
//     required IconData icon,
//     required String label,
//     required String value,
//     Color? valueColor,
//   }) {
//     final theme = Theme.of(context);
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         children: [
//           Icon(icon, size: 20, color: theme.colorScheme.primary),
//           const SizedBox(width: 12),
//           Text(
//             '$label:',
//             style: theme.textTheme.bodyMedium?.copyWith(
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               value,
//               style: theme.textTheme.bodyMedium?.copyWith(
//                 color: valueColor ?? theme.colorScheme.onSurface,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:krishi_link/core/theme/app_theme.dart';
import 'package:krishi_link/src/features/order/model/order_model.dart';

class OrderDetailsScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('order_number'.trArgs([order.orderId]))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${'product'.tr}: ${order.productName}',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('${'quantity'.tr}: ${order.productQuantity} ${order.unit}'),
            Text('${'total_price'.tr}: NPR ${order.totalPrice.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            Text(
              '${'order_status'.tr}: ${order.orderStatus.tr}',
              style: theme.textTheme.bodyLarge,
            ),
            Text('${'payment_status'.tr}: ${order.paymentStatus.tr}'),
            if (order.refundStatus != null)
              Text('${'refund_status'.tr}: ${order.refundStatus!.tr}'),
            const SizedBox(height: 16),
            Text('${'buyer'.tr}: ${order.buyerName ?? 'not_available'.tr}'),
            Text('${'contact'.tr}: ${order.buyerContact ?? 'not_available'.tr}'),
            Text('${'delivery_address'.tr}: ${order.deliveryAddress ?? 'not_available'.tr}'),
            const SizedBox(height: 16),
            Text(
              '${'ordered_at'.tr}: ${order.createdAt != null ? DateFormat('MMM dd, yyyy').format(order.createdAt!) : 'not_available'.tr}',
            ),
            if (order.deliveredAt != null)
              Text(
                '${'delivered_at'.tr}: ${DateFormat('MMM dd, yyyy').format(order.deliveredAt!)}',
              ),
          ],
        ),
      ),
    );
  }
}
