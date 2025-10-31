// lib/features/farmer/screens/farmer_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:krishi_link/core/widgets/app_widgets.dart';
import 'package:krishi_link/src/core/constants/app_spacing.dart';
import 'package:krishi_link/src/features/order/controllers/order_controller.dart';
import 'package:krishi_link/src/features/order/model/order_model.dart';

class FarmerOrdersScreen extends StatefulWidget {
  const FarmerOrdersScreen({super.key});

  @override
  State<FarmerOrdersScreen> createState() => _FarmerOrdersScreenState();
}

class _FarmerOrdersScreenState extends State<FarmerOrdersScreen> {
  final OrderController controller =
      Get.isRegistered<OrderController>()
          ? Get.find<OrderController>()
          : Get.put(OrderController());
  final TextEditingController searchController = TextEditingController();
  String? selectedStatusFilter;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          'my_orders'.tr,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Obx(
        () => Column(
          children: [
            // Enhanced filter section with gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.05),
                    colorScheme.surfaceContainerLowest,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Column(
                  children: [
                    // Search field with enhanced styling
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: AppWidgets.textField(
                        controller: searchController,
                        label: 'search_by_product_or_order_id'.tr,
                        icon: Icons.search,
                        colorScheme: colorScheme,
                        onChanged: (value) => controller.searchOrders(value),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Status filter with chip-like design
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: AppWidgets.dropdown(
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
                    ),
                  ],
                ),
              ),
            ),

            // Orders summary banner
            if (controller.filteredOrders.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 20,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${controller.filteredOrders.length} ${controller.filteredOrders.length == 1 ? 'order' : 'orders'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child:
                  controller.filteredOrders.isEmpty
                      ? _buildEmptyState(context, colorScheme)
                      : RefreshIndicator(
                        onRefresh: controller.fetchOrders,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          itemCount: controller.filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = controller.filteredOrders[index];
                            return _buildOrderCard(
                              context,
                              order,
                              index,
                              colorScheme,
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

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_basket_outlined,
              size: 80,
              color: colorScheme.primary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'no_orders_yet'.tr,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your orders will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    OrderModel order,
    int index,
    ColorScheme colorScheme,
  ) {
    final String statusLower = order.orderStatus.toLowerCase();
    final bool isDelivered = statusLower == 'delivered';
    final bool isShipped = statusLower == 'shipped';
    final bool isConfirmedStatus = statusLower == 'confirmed';
    final bool shouldShowBadge =
        isDelivered ||
        isShipped ||
        isConfirmedStatus ||
        order.deliveryConfirmedByBuyer;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final updatedOrder = await Get.toNamed(
              '/order-details',
              arguments: order,
            );
            if (updatedOrder != null) {
              controller.filteredOrders[index] = updatedOrder as OrderModel;
              controller.orders.assignAll(controller.filteredOrders);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with product icon and date
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.local_offer,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.productName,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${order.productQuantity} ${order.unit}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DateFormat(
                        'MMM dd',
                      ).format(order.createdAt ?? DateTime.now()),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.md),
                // Status and delivery confirmation row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusChip(
                        order.orderStatus,
                        colorScheme,
                        context,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (shouldShowBadge)
                      _buildDeliveryBadge(
                        confirmed: order.deliveryConfirmedByBuyer,
                        statusLower: statusLower,
                        colorScheme: colorScheme,
                        context: context,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(
    String status,
    ColorScheme colorScheme,
    BuildContext context,
  ) {
    final statusColor = _getStatusColor(status, colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            status.capitalizeFirst ?? status,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryBadge({
    required bool confirmed,
    required String statusLower,
    required ColorScheme colorScheme,
    required BuildContext context,
  }) {
    // Determine visual style by priority: buyer-confirmed (green) > delivered awaiting buyer (grey) > confirmed/shipped (blue)
    late final Color iconColor;
    late final Color bgColor;
    late final Color borderColor;
    late final String label;
    late final String tooltip;

    if (confirmed) {
      iconColor = Colors.green;
      bgColor = Colors.green.withValues(alpha: 0.15);
      borderColor = Colors.green.withValues(alpha: 0.3);
      label = 'Confirmed';
      tooltip = 'Delivery confirmed by buyer';
    } else if (statusLower == 'delivered') {
      iconColor = colorScheme.onSurfaceVariant; // grey
      bgColor = colorScheme.surfaceContainerHighest;
      borderColor = colorScheme.outline.withValues(alpha: 0.3);
      label = 'Delivered';
      tooltip = 'Delivered, awaiting buyer confirmation';
    } else if (statusLower == 'confirmed' || statusLower == 'shipped') {
      iconColor = Colors.blue;
      bgColor = Colors.blue.withValues(alpha: 0.15);
      borderColor = Colors.blue.withValues(alpha: 0.3);
      label = (statusLower == 'shipped' ? 'Shipped' : 'Confirmed');
      tooltip = statusLower == 'shipped' ? 'Order shipped' : 'Order confirmed';
    } else {
      // Fallback (should rarely happen due to caller condition)
      iconColor = colorScheme.onSurfaceVariant;
      bgColor = colorScheme.surfaceContainerHighest;
      borderColor = colorScheme.outline.withValues(alpha: 0.3);
      label = statusLower.capitalizeFirst ?? statusLower;
      tooltip = label;
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 18, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: iconColor,
                fontWeight: FontWeight.w600,
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
        return Colors.green.shade700;
      case 'shipped':
        return Colors.blue.shade700;
      case 'confirmed':
        return Colors.teal.shade700;
      case 'pending':
        return Colors.orange.shade700;
      case 'cancelled':
        return colorScheme.error;
      default:
        return colorScheme.onSurface;
    }
  }
}
