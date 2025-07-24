// // lib/features/admin/screens/manage_orders_screen.dart
// // ignore_for_file: curly_braces_in_flow_control_structures

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:krishi_link/features/admin/controller/admin_order_controller.dart';
// import 'package:krishi_link/features/admin/models/order_model.dart';

// class ManageOrdersScreen extends StatelessWidget {
//   const ManageOrdersScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final AdminOrderController controller = Get.find<AdminOrderController>();

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Manage Orders'),
//         backgroundColor: Colors.green.shade900,
//       ),
//       body: Obx(
//         () =>
//             controller.isLoading.value
//                 ? const Center(child: CircularProgressIndicator())
//                 : RefreshIndicator(
//                   onRefresh: controller.fetchOrders,
//                   child: SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: SingleChildScrollView(
//                       child: DataTable(
//                         columns: const [
//                           DataColumn(label: Text('ID')),
//                           DataColumn(label: Text('Product ID')),
//                           DataColumn(label: Text('Status')),
//                           DataColumn(label: Text('Total')),
//                           DataColumn(label: Text('Actions')),
//                         ],
//                         rows:
//                             controller.orders
//                                 .map(
//                                   (order) => _buildOrderRow(
//                                     order as OrderModel,
//                                     controller,
//                                   ),
//                                 )
//                                 .toList(),
//                       ),
//                     ),
//                   ),
//                 ),
//       ),
//     );
//   }

//   DataRow _buildOrderRow(OrderModel order, AdminOrderController controller) {
//     return DataRow(
//       cells: [
//         DataCell(Text(order.orderId)),
//         DataCell(Text(order.productId)),
//         DataCell(Text(order.orderStatus.capitalizeFirst ?? order.orderStatus)),
//         DataCell(Text('NPR ${order.totalPrice.toStringAsFixed(2)}')),
//         DataCell(
//           DropdownButton<String>(
//             value: order.orderStatus,
//             items:
//                 ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled']
//                     .map(
//                       (s) => DropdownMenuItem(
//                         value: s,
//                         child: Text(s.capitalizeFirst!),
//                       ),
//                     )
//                     .toList(),
//             onChanged: (value) {
//               if (value != null)
//                 controller.updateOrderStatus(order.orderId, value);
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }

// lib/features/admin/screens/manage_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/constants/lottie_assets.dart';
import 'package:krishi_link/core/lottie/lottie_widget.dart';
import 'package:krishi_link/features/admin/controllers/admin_order_controller.dart';
import 'package:krishi_link/features/admin/models/order_model.dart';
import 'package:krishi_link/services/popup_service.dart';

class ManageOrdersScreen extends StatelessWidget {
  const ManageOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminOrderController controller = Get.find<AdminOrderController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Orders'),
        backgroundColor: Colors.green.shade900,
      ),
      body: Obx(
        () =>
            controller.isLoading.value
                ? Center(child: LottieWidget(path: LottieAssets.loading))
                : RefreshIndicator(
                  onRefresh: () async => await controller.fetchOrders(),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Product ID')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Total')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows:
                            controller.orders
                                .map(
                                  (order) => _buildOrderRow(order, controller),
                                )
                                .toList(),
                      ),
                    ),
                  ),
                ),
      ),
    );
  }

  DataRow _buildOrderRow(OrderModel order, AdminOrderController controller) {
    return DataRow(
      cells: [
        DataCell(Text(order.orderId)),
        DataCell(Text(order.productId)),
        DataCell(Text(order.orderStatus.capitalizeFirst ?? order.orderStatus)),
        DataCell(Text('NPR ${order.totalPrice.toStringAsFixed(2)}')),
        DataCell(
          DropdownButton<String>(
            value: order.orderStatus,
            items:
                ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled']
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.capitalizeFirst!),
                      ),
                    )
                    .toList(),
            onChanged: (value) {
              if (value != null) {
                controller.updateOrderStatus(order.orderId, value);
              }
            },
          ),
        ),
      ],
    );
  }
}
