// lib/features/admin/screens/manage_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:krishi_link/core/constants/lottie_assets.dart';
import 'package:krishi_link/core/lottie/lottie_widget.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/core/widgets/app_widgets.dart';
import 'package:krishi_link/core/constants/app_spacing.dart';
import 'package:krishi_link/core/theme/app_theme.dart';
import 'package:krishi_link/core/widgets/ui.dart';
import 'package:krishi_link/features/admin/controllers/admin_order_controller.dart';
import 'package:krishi_link/features/admin/models/order_model.dart';

class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen>
    with SingleTickerProviderStateMixin {
  final AdminOrderController controller = Get.find<AdminOrderController>();
  final TextEditingController searchController = TextEditingController();
  String? selectedStatusFilter;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize animation for main content
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
      body: CustomScrollView(
        slivers: [
          // Modern SliverAppBar
          SliverAppBar(
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Manage Orders',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // background: Container(
              //   decoration: BoxDecoration(
              //     gradient: LinearGradient(
              //       colors: [
              //         colorScheme.primary,
              //         colorScheme.primary.withValues(alpha: 0.8),
              //       ],
              //       begin: Alignment.topLeft,
              //       end: Alignment.bottomRight,
              //     ),
              //   ),
              // ),
            ),
            expandedHeight: 150,
            backgroundColor: colorScheme.primary,
          ),
          // Main content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search and Filter
                      AppWidgets.card(
                        colorScheme: colorScheme,
                        title: 'Filter Orders',
                        icon: Icons.filter_list,
                        iconColor: colorScheme.primary,
                        child: Column(
                          children: [
                            AppWidgets.textField(
                              controller: searchController,
                              label: 'Search by Product or Farmer',
                              icon: Icons.search,
                              colorScheme: colorScheme,
                              onChanged:
                                  (value) => controller.searchOrders(value),
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
                                controller.filterOrdersByStatus(
                                  value == 'All' ? null : value,
                                );
                              },
                              label: 'Filter by Status',
                              icon: Icons.filter_alt,
                              colorScheme: colorScheme,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Orders Table
                      controller.orders.isEmpty
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
                                  'No orders found',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(color: colorScheme.onSurface),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                AppWidgets.button(
                                  text: 'Add New Order',
                                  icon: Icons.add,
                                  // onPressed: () => Get.toNamed('/add-order'),
                                  onPressed:
                                      () => PopupService.error('Coming soon'),
                                  colorScheme: colorScheme,
                                ),
                              ],
                            ),
                          )
                          : AppWidgets.card(
                            colorScheme: colorScheme,
                            title: 'Order List',
                            icon: Icons.local_offer,
                            iconColor: colorScheme.primary,
                            child: FadeInUp(
                              delay: const Duration(milliseconds: 200),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columns: [
                                    DataColumn(
                                      label: Text(
                                        'ID',
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Product ID',
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Status',
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Total',
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Actions',
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                  rows:
                                      controller.orders
                                          .asMap()
                                          .entries
                                          .map(
                                            (entry) => _buildOrderRow(
                                              entry.key,
                                              entry.value,
                                              controller,
                                              colorScheme,
                                            ),
                                          )
                                          .toList(),
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/add-order'),
        backgroundColor: colorScheme.primary,
        child: Icon(Icons.add, color: colorScheme.onPrimary),
      ),
    );
  }

  DataRow _buildOrderRow(
    int index,
    OrderModel order,
    AdminOrderController controller,
    ColorScheme colorScheme,
  ) {
    return DataRow(
      cells: [
        DataCell(
          Text(order.orderId, style: TextStyle(color: colorScheme.onSurface)),
        ),
        DataCell(
          Text(order.productId, style: TextStyle(color: colorScheme.onSurface)),
        ),
        DataCell(
          Text(
            order.orderStatus.capitalizeFirst ?? order.orderStatus,
            style: TextStyle(
              color: _getStatusColor(order.orderStatus, colorScheme),
            ),
          ),
        ),
        DataCell(
          Text(
            'NPR ${order.totalPrice.toStringAsFixed(2)}',
            style: TextStyle(color: colorScheme.onSurface),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppWidgets.dropdown(
                value: order.orderStatus,
                items: [
                  'Pending',
                  'Confirmed',
                  'Shipped',
                  'Delivered',
                  'Cancelled',
                ],
                onChanged: (value) {
                  if (value != null) {
                    controller.updateOrderStatus(
                      order.orderId,
                      value.toLowerCase(),
                    );
                  }
                },
                label: 'Status',
                colorScheme: colorScheme,
              ),
              const SizedBox(width: AppSpacing.sm),
              AppWidgets.secondaryButton(
                text: 'Delete',
                onPressed:
                    () => Get.defaultDialog(
                      title: 'Confirm Delete',
                      titleStyle: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      content: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          'Delete order #${order.orderId}?',
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                      ),
                      confirm: AppWidgets.button(
                        text: 'Confirm',
                        onPressed: () {
                          controller.deleteOrder(order.orderId);
                          Get.back();
                        },
                        colorScheme: colorScheme,
                      ),
                      cancel: AppWidgets.secondaryButton(
                        text: 'Cancel',
                        onPressed: () => Get.back(),
                        colorScheme: colorScheme,
                      ),
                      backgroundColor: colorScheme.surface,
                      radius: 16,
                    ),
                colorScheme: colorScheme,
              ),
            ],
          ),
        ),
      ],
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
