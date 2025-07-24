import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:krishi_link/core/theme/app_theme.dart';
import 'package:krishi_link/features/admin/models/order_model.dart';
import 'package:krishi_link/features/farmer/controller/farmer_controller.dart';
import 'package:intl/intl.dart';

class FarmerOrdersScreen extends StatelessWidget {
  const FarmerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FarmerController controller = Get.find<FarmerController>();
    final theme = Theme.of(context);

    // // Mock orders (replace with API call in controller)
    // final orders = [
    //   {
    //     'id': '1',
    //     'product': 'Tomato',
    //     'quantity': 50,
    //     'unit': 'kg',
    //     'status': 'Pending',
    //     'timestamp': DateTime.now().subtract(const Duration(days: 1)),
    //   },
    //   {
    //     'id': '2',
    //     'product': 'Potato',
    //     'quantity': 100,
    //     'unit': 'kg',
    //     'status': 'Delivered',
    //     'timestamp': DateTime.now().subtract(const Duration(days: 3)),
    //   },
    // ];
    return Scaffold(
      appBar: AppBar(title: Text('my_orders'.tr)),
      body: Obx(
        () =>
            controller.orders.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_basket,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'no_orders_yet'.tr,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.orders.length,
                  itemBuilder: (context, index) {
                    final order = controller.orders[index];
                    return FadeInUp(
                      delay: Duration(milliseconds: 100 * index),
                      child: Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(
                              Icons.local_offer,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            'order_product_quantity'.trArgs([
                              order.productName,
                              order.productQuantity.toString(),
                              order.unit,
                            ]),
                            style: theme.textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            'status'.trArgs([order.orderStatus]),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  order.orderStatus.toLowerCase() == 'delivered'
                                      ? Colors.green
                                      : Colors.orange,
                            ),
                          ),
                          trailing: Text(
                            DateFormat(
                              'MMM dd',
                            ).format(order.createdAt ?? DateTime.now()),
                            style: theme.textTheme.bodySmall,
                          ),
                          onTap: () async {
                            final updatedOrder = await Get.toNamed(
                              '/order-details',
                              arguments: order,
                            );
                            if (updatedOrder != null) {
                              controller.orders[index] =
                                  updatedOrder as OrderModel;
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
