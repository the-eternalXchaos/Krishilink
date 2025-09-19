// lib/features/farmer/screens/farmer_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:krishi_link/src/core/constants/app_spacing.dart';
import 'package:krishi_link/src/core/constants/lottie_assets.dart';
import 'package:krishi_link/core/lottie/lottie_widget.dart';
import 'package:krishi_link/core/theme/app_theme.dart';
import 'package:krishi_link/core/widgets/app_widgets.dart';
import 'package:krishi_link/features/admin/models/order_model.dart';
import 'package:krishi_link/features/farmer/controller/farmer_controller.dart';

class FarmerOrdersScreen extends StatefulWidget {
  const FarmerOrdersScreen({super.key});

  @override
  State<FarmerOrdersScreen> createState() => _FarmerOrdersScreenState();
}

class _FarmerOrdersScreenState extends State<FarmerOrdersScreen>
    with SingleTickerProviderStateMixin {
  final FarmerController controller = Get.find<FarmerController>();
  final TextEditingController searchController = TextEditingController();
  String? selectedStatusFilter;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('my_orders'.tr),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Obx(
        () => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: AppWidgets.card(
                  colorScheme: colorScheme,
                  title: 'filter_orders'.tr,
                  icon: Icons.filter_list,
                  iconColor: colorScheme.primary,
                  child: Column(
                    children: [
                      AppWidgets.textField(
                        controller: searchController,
                        label: 'search_by_product_or_order_id'.tr,
                        icon: Icons.search,
                        colorScheme: colorScheme,
                        onChanged: (value) => controller.searchOrders(value),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppWidgets.dropdown(
                        value: selectedStatusFilter,
                        items: [
                          'All',
                          'Pending',
                          'Confirmed',
                          'Shipped',
                          'Delivered',
                          'Cancelled',
                        ],
                        onChanged: (value) {
                          setState(() => selectedStatusFilter = value);
                          controller.filterOrdersByStatus(value);
                        },
                        label: 'filter_by_status'.tr,
                        icon: Icons.filter_alt,
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child:
                  controller.filteredOrders.isEmpty
                      ? AppWidgets.card(
                        colorScheme: colorScheme,
                        title: 'No Orders',
                        icon: Icons.shopping_basket,
                        iconColor: colorScheme.primary,
                        child: Column(
                          children: [
                            Icon(
                              Icons.shopping_basket,
                              size: 80,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.4,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'no_orders_yet'.tr,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: colorScheme.onSurface),
                            ),
                          ],
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh: controller.fetchOrders,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          itemCount: controller.filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = controller.filteredOrders[index];
                            return FadeInUp(
                              delay: Duration(milliseconds: 100 * index),
                              child: AppWidgets.card(
                                colorScheme: colorScheme,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        colorScheme.primaryContainer,
                                    child: Icon(
                                      Icons.local_offer,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  title: Text(
                                    'order_product_quantity'.trArgs([
                                      order.productName,
                                      order.productQuantity.toString(),
                                      order.unit,
                                    ]),
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  subtitle: Text(
                                    'status'.trArgs([order.orderStatus]),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(
                                      color: _getStatusColor(
                                        order.orderStatus,
                                        colorScheme,
                                      ),
                                    ),
                                  ),
                                  trailing: Text(
                                    DateFormat(
                                      'MMM dd',
                                    ).format(order.createdAt ?? DateTime.now()),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  onTap: () async {
                                    final updatedOrder = await Get.toNamed(
                                      '/order-details',
                                      arguments: order,
                                    );
                                    if (updatedOrder != null) {
                                      controller.filteredOrders[index] =
                                          updatedOrder as OrderModel;
                                      controller.orders.assignAll(
                                        controller.filteredOrders,
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status, ColorScheme colorScheme) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'shipped':
        return Colors.blue;
      case 'confirmed':
        return Colors.teal;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return colorScheme.error;
      default:
        return colorScheme.onSurface;
    }
  }
}
