import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/src/features/order/model/buyer_order_models.dart';
import 'package:krishi_link/src/features/order/data/order_service.dart';
import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:intl/intl.dart';

class BuyerOrderDetailsScreen extends StatelessWidget {
  final BuyerOrder order;
  const BuyerOrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    // Log the incoming order once per build
    debugPrint('[UI][BuyerOrderDetails] Showing order ${order.orderId}');
    debugPrint('[UI][BuyerOrderDetails] Payload: ${order.toString()}');
    
    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: Text('Order Details'.tr),
        elevation: 0,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: CustomScrollView(
        slivers: [
          // Hero Header with gradient
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primary,
                    cs.primary.withValues(alpha: 0.85),
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long, color: cs.onPrimary, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #${_shortId(order.orderId)}',
                              style: tt.titleLarge?.copyWith(
                                color: cs.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDateTime(order.orderDate),
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onPrimary.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStatusChip(order.overallStatus, cs),
                ],
              ),
            ),
          ),
          
          // Order Summary Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: cs.primary, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Order Summary'.tr,
                            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        Icons.calendar_today_outlined,
                        'Ordered'.tr,
                        _formatDateTime(order.orderDate),
                        cs,
                        tt,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.update_outlined,
                        'Last Updated'.tr,
                        _formatDateTime(order.updatedAt),
                        cs,
                        tt,
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount'.tr,
                            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Rs ${order.totalAmount.toStringAsFixed(2)}',
                            style: tt.titleLarge?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Items Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.shopping_bag_outlined, color: cs.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Items (${order.items.length})'.tr,
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // Items List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _ItemTile(item: order.items[index], index: index + 1),
                childCount: order.items.length,
              ),
            ),
          ),

          // Cancel Button
          if (!_isTerminal(order.overallStatus))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _CancelOrderButton(orderId: order.orderId),
              ),
            ),
          
          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, ColorScheme cs) {
    final statusLower = status.toLowerCase();
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (statusLower) {
      case 'delivered':
      case 'completed':
        bgColor = cs.tertiaryContainer;
        textColor = cs.onTertiaryContainer;
        icon = Icons.check_circle;
        break;
      case 'processing':
        bgColor = cs.primaryContainer;
        textColor = cs.onPrimaryContainer;
        icon = Icons.autorenew;
        break;
      case 'shipped':
        bgColor = cs.secondaryContainer;
        textColor = cs.onSecondaryContainer;
        icon = Icons.local_shipping;
        break;
      case 'cancelled':
        bgColor = cs.errorContainer;
        textColor = cs.onErrorContainer;
        icon = Icons.cancel;
        break;
      default:
        bgColor = cs.surfaceContainerHighest;
        textColor = cs.onSurface;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Text(
            status.capitalizeFirst ?? status,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, ColorScheme cs, TextTheme tt) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: cs.onPrimaryContainer),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'N/A';
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dt);
  }

  String _shortId(String id) {
    if (id.length <= 8) return id.toUpperCase();
    return '${id.substring(0, 4).toUpperCase()}…${id.substring(id.length - 4).toUpperCase()}';
  }
}

bool _isTerminal(String status) {
  final s = status.toLowerCase();
  return s == 'delivered' || s == 'cancelled' || s == 'returned' || s == 'completed';
}

class _CancelOrderButton extends StatefulWidget {
  final String orderId;
  const _CancelOrderButton({required this.orderId});

  @override
  State<_CancelOrderButton> createState() => _CancelOrderButtonState();
}

class _CancelOrderButtonState extends State<_CancelOrderButton> {
  bool _loading = false;
  final _service = Get.put(OrderService());

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _loading ? null : _confirmAndCancel,
            icon: _loading
                ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: cs.error))
                : Icon(Icons.cancel, color: cs.error),
            label: Text('Cancel order'.tr, style: TextStyle(color: cs.error)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: cs.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAndCancel() async {
    final ok = await Get.dialog<bool>(AlertDialog(
      title: Text('Cancel order?'.tr),
      content: Text('Do you really want to cancel this order?'.tr),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: Text('No'.tr)),
        TextButton(onPressed: () => Get.back(result: true), child: Text('Yes'.tr)),
      ],
    ));
    if (ok != true) return;

    setState(() => _loading = true);
    try {
      debugPrint('[UI][BuyerOrderDetails] Cancelling order ${widget.orderId}');
      final res = await _service.cancelOrder(widget.orderId);
      debugPrint('[UI][BuyerOrderDetails] Cancel response: ${res.statusCode}');
      debugPrint('[UI][BuyerOrderDetails] Body: ${res.data}');
      if ((res.statusCode ?? 500) >= 200 && (res.statusCode ?? 500) < 300) {
        Get.snackbar('Success'.tr, 'Order cancelled'.tr);
        Get.back(result: true);
      } else {
        Get.snackbar('Error'.tr, 'Failed to cancel order'.tr);
      }
    } catch (e) {
      Get.snackbar('Error'.tr, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _ItemTile extends StatefulWidget {
  final BuyerOrderItem item;
  final int index;
  const _ItemTile({required this.item, required this.index});

  @override
  State<_ItemTile> createState() => _ItemTileState();
}

class _ItemTileState extends State<_ItemTile> {
  final OrderService _orderService = OrderService();
  Map<String, dynamic>? _productData;
  bool _isLoadingProduct = false;

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    if (_isLoadingProduct) return;
    setState(() => _isLoadingProduct = true);
    
    try {
      final response = await _orderService.getProductById(widget.item.productId);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        // Handle nested data structure
        if (data is Map<String, dynamic>) {
          setState(() {
            _productData = (data['data'] as Map<String, dynamic>?) ?? data;
            _isLoadingProduct = false;
          });
        }
      }
    } catch (e) {
      debugPrint('[ItemTile] Error fetching product: $e');
      setState(() => _isLoadingProduct = false);
    }
  }

  String get _productName {
    return _productData?['productName'] ?? 
           _productData?['name'] ?? 
           'Product #${_shortId(widget.item.productId)}';
  }

  String? get _productImage {
    final img = _productData?['image'];
    if (img != null && img.toString().isNotEmpty) {
      final imageCode = img.toString();
      // If it's already a full URL, return it; otherwise construct the URL
      if (imageCode.startsWith('http')) {
        return imageCode;
      }
      return '${ApiConstants.getProductImageEndpoint}/$imageCode';
    }
    return null;
  }

  String? get _productCategory {
    return _productData?['category'];
  }

  Widget _buildNumberBadge(ColorScheme cs, TextTheme tt) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          '${widget.index}',
          style: tt.titleLarge?.copyWith(
            color: cs.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {}, // Future: navigate to product details
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item header with index and status
              Row(
                children: [
                  // Product image or numbered badge
                  if (_productImage != null && _productImage!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        _productImage!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildNumberBadge(cs, tt),
                      ),
                    )
                  else
                    _buildNumberBadge(cs, tt),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isLoadingProduct ? 'Loading...' : _productName,
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (_productCategory != null)
                          Row(
                            children: [
                              Icon(Icons.category_outlined, size: 14, color: cs.primary),
                              const SizedBox(width: 4),
                              Text(
                                _productCategory!,
                                style: tt.bodySmall?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(widget.item.itemStatus, cs, isItemStatus: true),
                ],
              ),
              
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Item details grid
              Row(
                children: [
                  Expanded(
                    child: _buildDetailColumn(
                      Icons.inventory_2_outlined,
                      'Quantity'.tr,
                      '${widget.item.quantity}',
                      cs,
                      tt,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: cs.outlineVariant,
                  ),
                  Expanded(
                    child: _buildDetailColumn(
                      Icons.attach_money_outlined,
                      'Rate'.tr,
                      'Rs ${widget.item.rate.toStringAsFixed(2)}',
                      cs,
                      tt,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: cs.outlineVariant,
                  ),
                  Expanded(
                    child: _buildDetailColumn(
                      Icons.receipt_outlined,
                      'Total'.tr,
                      'Rs ${widget.item.totalPrice.toStringAsFixed(2)}',
                      cs,
                      tt,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Payment and refund status
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatusBadge(widget.item.paymentStatus, cs, isPayment: true),
                  if (widget.item.refundStatus != 'None')
                    _buildStatusBadge(widget.item.refundStatus, cs, isRefund: true),
                  if (widget.item.deliveryConfirmedByBuyer)
                    _buildStatusBadge('Delivered', cs, isDelivered: true),
                ],
              ),

              // Mark as Delivered button (only show if shipped and not yet confirmed)
              if (_shouldShowMarkAsDeliveredButton())
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoadingProduct ? null : _markAsDelivered,
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text('Mark as Delivered'.tr),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primaryContainer,
                        foregroundColor: cs.onPrimaryContainer,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _shouldShowMarkAsDeliveredButton() {
    // Show button if: item is shipped AND buyer hasn't confirmed delivery yet
    final status = widget.item.itemStatus.toLowerCase();
    return (status == 'shipped' || status == 'shipped') && 
           !widget.item.deliveryConfirmedByBuyer;
  }

  Future<void> _markAsDelivered() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Confirm Delivery'.tr),
        content: Text(
          'Have you received this item? Once confirmed, you acknowledge that the product has been delivered to you.'.tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: Text('Confirm'.tr),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isLoadingProduct = true);
      debugPrint('[ItemTile] Marking item ${widget.item.orderItemId} as delivered');
      
      final response = await _orderService.markAsDelivery(widget.item.orderItemId);
      
      debugPrint('[ItemTile] markAsDelivery response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        Get.snackbar(
          'Success'.tr,
          'Item marked as delivered successfully'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.primaryContainer,
          colorText: Get.theme.colorScheme.onPrimaryContainer,
          duration: const Duration(seconds: 3),
        );
        
        // Refresh the page to show updated status
        Get.back(); // Go back
        await Future.delayed(const Duration(milliseconds: 300));
        // User should manually refresh or we trigger a full page reload
        debugPrint('[ItemTile] Item marked as delivered, please refresh');
      } else {
        throw Exception('Failed to mark as delivered: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ItemTile] Error marking as delivered: $e');
      Get.snackbar(
        'Error'.tr,
        'Failed to mark as delivered. Please try again.'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
        colorText: Get.theme.colorScheme.onErrorContainer,
        duration: const Duration(seconds: 3),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingProduct = false);
      }
    }
  }

  Widget _buildDetailColumn(
    IconData icon,
    String label,
    String value,
    ColorScheme cs,
    TextTheme tt,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: cs.primary),
        const SizedBox(height: 4),
        Text(
          label,
          style: tt.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: tt.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatusBadge(
    String status,
    ColorScheme cs, {
    bool isItemStatus = false,
    bool isPayment = false,
    bool isRefund = false,
    bool isDelivered = false,
  }) {
    Color bgColor;
    Color textColor;
    IconData? icon;

    if (isPayment) {
      final isPaid = status.toLowerCase() == 'paid';
      bgColor = isPaid ? cs.tertiaryContainer : cs.secondaryContainer;
      textColor = isPaid ? cs.onTertiaryContainer : cs.onSecondaryContainer;
      icon = isPaid ? Icons.check_circle : Icons.pending;
    } else if (isRefund) {
      bgColor = cs.errorContainer;
      textColor = cs.onErrorContainer;
      icon = Icons.replay;
    } else if (isDelivered) {
      bgColor = cs.tertiaryContainer;
      textColor = cs.onTertiaryContainer;
      icon = Icons.local_shipping_outlined;
    } else {
      // Item status
      bgColor = cs.primaryContainer;
      textColor = cs.onPrimaryContainer;
      icon = Icons.circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.capitalizeFirst ?? status,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _shortId(String id) {
    if (id.length <= 8) return id.toUpperCase();
    return '${id.substring(0, 4).toUpperCase()}…${id.substring(id.length - 4).toUpperCase()}';
  }
}