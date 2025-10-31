import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/src/features/order/data/order_service.dart';
import 'package:krishi_link/src/features/order/model/order_model.dart';
import 'package:krishi_link/src/features/product/data/models/product_model.dart';

class FarmerOrderDetailsScreen extends StatefulWidget {
  final OrderModel order;

  const FarmerOrderDetailsScreen({super.key, required this.order});

  @override
  State<FarmerOrderDetailsScreen> createState() =>
      _FarmerOrderDetailsScreenState();
}

class _FarmerOrderDetailsScreenState extends State<FarmerOrderDetailsScreen> {
  late OrderModel currentOrder;
  bool isUpdating = false;
  bool isLoadingDetails = true;
  final AuthController authController = Get.find<AuthController>();
  final OrderService _orderService = OrderService();

  // Fetched data
  Product? product;
  Map<String, dynamic>? buyerDetails;

  @override
  void initState() {
    super.initState();
    currentOrder = widget.order;
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => isLoadingDetails = true);

    // Fetch product details
    if (currentOrder.productId.isNotEmpty) {
      try {
        debugPrint('🔍 Fetching product with ID: ${currentOrder.productId}');
        final productResponse = await _orderService.getProductById(
          currentOrder.productId,
        );
        debugPrint('📦 Product response: ${productResponse.data}');
        if (productResponse.data != null &&
            productResponse.data['success'] == true) {
          final productData = productResponse.data['data'];
          debugPrint('✅ Product data: $productData');
          setState(() {
            product = Product.fromJson(productData);
            debugPrint('🖼️ Product image URL: ${product!.image}');
            debugPrint('📦 Product name: ${product!.productName}');
            debugPrint('🏷️ Product category: ${product!.category}');
          });
        } else {
          debugPrint('❌ Product fetch failed: ${productResponse.data}');
        }
      } catch (e) {
        debugPrint('💥 Error loading product: $e');
      }
    }

    // Fetch buyer details
    if (currentOrder.buyerId != null && currentOrder.buyerId!.isNotEmpty) {
      try {
        final userResponse = await _orderService.getUserDetailsById(
          currentOrder.buyerId!,
        );
        if (userResponse.data != null && userResponse.data['success'] == true) {
          setState(() {
            buyerDetails = userResponse.data['data'] as Map<String, dynamic>?;
          });
        }
      } catch (e) {
        debugPrint('Error loading buyer details: $e');
      }
    }

    setState(() => isLoadingDetails = false);
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    if (!_canProgressTo(newStatus)) {
      PopupService.error(
        'Cannot skip to $newStatus. Please follow the order progression.',
      );
      return;
    }

    try {
      setState(() => isUpdating = true);

      switch (newStatus.toLowerCase()) {
        case 'confirmed':
          await _orderService.confirmOrder(currentOrder.orderItemId);
          break;
        case 'shipped':
          await _orderService.shipOrder(currentOrder.orderItemId);
          break;
        case 'delivered':
          await _orderService.deliverOrder(currentOrder.orderItemId);
          break;
        default:
          throw Exception('Invalid status');
      }

      setState(() {
        currentOrder = currentOrder.copyWith(
          orderStatus: newStatus.toLowerCase(),
        );
        isUpdating = false;
      });

      PopupService.success('Order status updated to $newStatus');
      Get.back(result: currentOrder);
    } catch (e) {
      setState(() => isUpdating = false);
      PopupService.error('Failed to update order status: ${e.toString()}');
    }
  }

  bool _canProgressTo(String newStatus) {
    final currentStatus = currentOrder.orderStatus.toLowerCase();
    final target = newStatus.toLowerCase();

    if (currentStatus == 'pending' && target == 'confirmed') return true;
    if (currentStatus == 'confirmed' && target == 'shipped') return true;
    if (currentStatus == 'shipped' && target == 'delivered') return true;

    return false;
  }

  String _getNextStatus() {
    switch (currentOrder.orderStatus.toLowerCase()) {
      case 'pending':
        return 'confirmed';
      case 'confirmed':
        return 'shipped';
      case 'shipped':
        return 'delivered';
      default:
        return '';
    }
  }

  bool _canUpdateStatus() {
    final currentStatus = currentOrder.orderStatus.toLowerCase();
    return currentStatus == 'pending' ||
        currentStatus == 'confirmed' ||
        currentStatus == 'shipped';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: Text('Order Details'.tr),
        elevation: 0,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body:
          isLoadingDetails
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
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
                              Icon(
                                Icons.receipt_long,
                                color: cs.onPrimary,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order #${_shortId(currentOrder.orderId)}',
                                      style: tt.titleLarge?.copyWith(
                                        color: cs.onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDateTime(currentOrder.createdAt),
                                      style: tt.bodyMedium?.copyWith(
                                        color: cs.onPrimary.withValues(
                                          alpha: 0.9,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildStatusChip(currentOrder.orderStatus, cs),
                        ],
                      ),
                    ),
                  ),

                  // Product Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.shopping_bag_outlined,
                                    color: cs.primary,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Product Details'.tr,
                                    style: tt.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Product Info with Image
                              if (product != null) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Product Image
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child:
                                          product!.image.isNotEmpty
                                              ? CachedNetworkImage(
                                                imageUrl: product!.image,
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                                placeholder:
                                                    (context, url) => Container(
                                                      width: 80,
                                                      height: 80,
                                                      color:
                                                          cs.surfaceContainerHighest,
                                                      child: const Center(
                                                        child:
                                                            CircularProgressIndicator(),
                                                      ),
                                                    ),
                                                errorWidget:
                                                    (
                                                      context,
                                                      url,
                                                      error,
                                                    ) => Container(
                                                      width: 80,
                                                      height: 80,
                                                      color:
                                                          cs.surfaceContainerHighest,
                                                      child: Icon(
                                                        Icons
                                                            .image_not_supported,
                                                        color: cs.onSurface
                                                            .withValues(
                                                              alpha: 0.4,
                                                            ),
                                                        size: 40,
                                                      ),
                                                    ),
                                              )
                                              : Container(
                                                width: 80,
                                                height: 80,
                                                decoration: BoxDecoration(
                                                  color:
                                                      cs.surfaceContainerHighest,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  Icons.shopping_bag_outlined,
                                                  color: cs.onSurface
                                                      .withValues(alpha: 0.4),
                                                  size: 40,
                                                ),
                                              ),
                                    ),
                                    const SizedBox(width: 16),

                                    // Product Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product!.productName,
                                            style: tt.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.category_outlined,
                                                size: 14,
                                                color: cs.primary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                product!.category,
                                                style: tt.bodySmall?.copyWith(
                                                  color: cs.primary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: cs.primaryContainer
                                                  .withValues(alpha: 0.3),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Rs. ${product!.rate.toStringAsFixed(2)}/${product!.unit}',
                                              style: tt.bodySmall?.copyWith(
                                                color: cs.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(height: 1),
                                const SizedBox(height: 16),
                              ],

                              // Order Details Grid
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDetailColumn(
                                      Icons.inventory_2_outlined,
                                      'Quantity'.tr,
                                      '${currentOrder.productQuantity} ${currentOrder.unit}',
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
                                      'Total Price'.tr,
                                      'Rs ${currentOrder.totalPrice.toStringAsFixed(2)}',
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
                                      Icons.credit_card,
                                      'Payment'.tr,
                                      currentOrder
                                              .paymentStatus
                                              .capitalizeFirst ??
                                          currentOrder.paymentStatus,
                                      cs,
                                      tt,
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

                  // Buyer Information Card
                  if (buyerDetails != null || currentOrder.buyerName != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      color: cs.primary,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Buyer Information'.tr,
                                      style: tt.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (buyerDetails?['fullName'] != null ||
                                    currentOrder.buyerName != null)
                                  _buildInfoRow(
                                    Icons.person,
                                    'Name'.tr,
                                    buyerDetails?['fullName'] ??
                                        currentOrder.buyerName ??
                                        'N/A',
                                    cs,
                                    tt,
                                  ),
                                if (buyerDetails?['phoneNumber'] != null ||
                                    currentOrder.buyerContact != null) ...[
                                  const SizedBox(height: 12),
                                  _buildInfoRow(
                                    Icons.phone,
                                    'Contact'.tr,
                                    buyerDetails?['phoneNumber'] ??
                                        currentOrder.buyerContact ??
                                        'N/A',
                                    cs,
                                    tt,
                                  ),
                                ],
                                if (buyerDetails?['email'] != null) ...[
                                  const SizedBox(height: 12),
                                  _buildInfoRow(
                                    Icons.email,
                                    'Email'.tr,
                                    buyerDetails!['email'],
                                    cs,
                                    tt,
                                  ),
                                ],
                                if (currentOrder.deliveryAddress != null) ...[
                                  const SizedBox(height: 12),
                                  _buildInfoRow(
                                    Icons.location_on,
                                    'Delivery Address'.tr,
                                    currentOrder.deliveryAddress!,
                                    cs,
                                    tt,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Order Timeline
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.timeline,
                                    color: cs.primary,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Order Progress'.tr,
                                    style: tt.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildTimeline(cs, tt),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Update Status Button
                  if (_canUpdateStatus())
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildActionButton(cs, tt),
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
        bgColor = cs.tertiaryContainer;
        textColor = cs.onTertiaryContainer;
        icon = Icons.check_circle;
        break;
      case 'shipped':
        bgColor = cs.secondaryContainer;
        textColor = cs.onSecondaryContainer;
        icon = Icons.local_shipping;
        break;
      case 'confirmed':
        bgColor = cs.primaryContainer;
        textColor = cs.onPrimaryContainer;
        icon = Icons.verified;
        break;
      case 'pending':
        bgColor = cs.surfaceContainerHighest;
        textColor = cs.onSurface;
        icon = Icons.pending;
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
          style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    ColorScheme cs,
    TextTheme tt,
  ) {
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

  Widget _buildTimeline(ColorScheme cs, TextTheme tt) {
    final statuses = ['pending', 'confirmed', 'shipped', 'delivered'];
    final currentIndex = statuses.indexOf(
      currentOrder.orderStatus.toLowerCase(),
    );

    return Column(
      children: List.generate(statuses.length, (i) {
        final isCompleted = i <= currentIndex;
        final isCurrent = i == currentIndex;
        final isLast = i == statuses.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isCompleted ? cs.primary : cs.surfaceContainerHighest,
                    border: Border.all(
                      color: isCompleted ? cs.primary : cs.outline,
                      width: 2,
                    ),
                  ),
                  child:
                      isCompleted
                          ? Icon(Icons.check, size: 18, color: cs.onPrimary)
                          : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color:
                        isCompleted
                            ? cs.primary
                            : cs.outline.withValues(alpha: 0.3),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statuses[i].toUpperCase(),
                      style: tt.titleSmall?.copyWith(
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                        color:
                            isCompleted
                                ? cs.onSurface
                                : cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    if (isCurrent)
                      Text(
                        'Current Status',
                        style: tt.bodySmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (!isLast) const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildActionButton(ColorScheme cs, TextTheme tt) {
    final nextStatus = _getNextStatus();
    String buttonText;

    switch (nextStatus) {
      case 'confirmed':
        buttonText = 'Confirm Order';
        break;
      case 'shipped':
        buttonText = 'Mark as Shipped';
        break;
      case 'delivered':
        buttonText = 'Mark as Delivered';
        break;
      default:
        buttonText = 'Update Status';
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isUpdating ? null : () => _updateOrderStatus(nextStatus),
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            isUpdating
                ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary),
                  ),
                )
                : Text(
                  buttonText,
                  style: tt.titleMedium?.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
      ),
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
