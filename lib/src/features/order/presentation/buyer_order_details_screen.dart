import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:krishi_link/src/core/constants/api_constants.dart';
import 'package:krishi_link/src/features/order/controllers/order_controller.dart';
import 'package:krishi_link/src/features/order/data/order_service.dart';
import 'package:krishi_link/src/features/order/model/order_model.dart';
import 'package:krishi_link/widgets/safe_network_image.dart';

class BuyerOrderDetailsScreen extends StatelessWidget {
  final OrderModel order;
  const BuyerOrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    debugPrint('[UI][BuyerOrderDetails] Showing order ${order.orderId}');
    debugPrint('[UI][BuyerOrderDetails] Payload: ${order.toString()}');

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          // Enhanced App Bar with gradient
          SliverAppBar(
            expandedHeight: Get.height * 0.33,
            pinned: true,
            elevation: 0,
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primary,
                      cs.primary.withValues(alpha: 0.8),
                      cs.primaryContainer,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.onPrimary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.receipt_long_rounded,
                            color: cs.onPrimary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Order #${_shortId(order.orderId)}',
                          style: tt.headlineSmall?.copyWith(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: cs.onPrimary.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatDateTime(order.createdAt),
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onPrimary.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildEnhancedStatusChip(order.orderStatus, cs),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Order Progress Timeline (if applicable)
          if (!_isTerminal(order.orderStatus))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: _buildOrderTimeline(order.orderStatus, cs, tt),
              ),
            ),

          // Order Summary Card with enhanced design
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [cs.surface, cs.surfaceContainerLow],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.info_outline_rounded,
                                color: cs.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Order Summary'.tr,
                              style: tt.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildEnhancedInfoRow(
                          Icons.calendar_today_rounded,
                          'Ordered'.tr,
                          _formatDateTime(order.createdAt),
                          cs,
                          tt,
                        ),
                        const SizedBox(height: 16),
                        _buildEnhancedInfoRow(
                          Icons.update_rounded,
                          'Last Updated'.tr,
                          _formatDateTime(order.deliveredAt ?? order.createdAt),
                          cs,
                          tt,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: cs.primary.withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Amount'.tr,
                                    style: tt.bodyLarge?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rs ${order.totalPrice.toStringAsFixed(2)}',
                                    style: tt.headlineMedium?.copyWith(
                                      color: cs.primary,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.payments_rounded,
                                  color: cs.onPrimary,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Item Section Header with enhanced styling
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.shopping_bag_rounded,
                      color: cs.onSecondaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Order Item'.tr,
                    style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: cs.tertiaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '1 item',
                      style: tt.labelMedium?.copyWith(
                        color: cs.onTertiaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Enhanced Item Tile
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _EnhancedItemTile(item: order, index: 1),
              ]),
            ),
          ),

          // Enhanced Cancel Button
          if (!_isTerminal(order.orderStatus))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _EnhancedCancelOrderButton(orderId: order.orderId),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildOrderTimeline(String status, ColorScheme cs, TextTheme tt) {
    final steps = ['Processing', 'Shipped', 'Delivered'];
    final currentIndex = steps.indexWhere(
      (s) => s.toLowerCase() == status.toLowerCase(),
    );
    final activeIndex = currentIndex >= 0 ? currentIndex : 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Progress'.tr,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: List.generate(
                steps.length,
                (index) => Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color:
                                    index <= activeIndex
                                        ? cs.primary
                                        : cs.surfaceContainerHighest,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      index <= activeIndex
                                          ? cs.primary
                                          : cs.outline,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                index <= activeIndex
                                    ? Icons.check_rounded
                                    : Icons.circle,
                                color:
                                    index <= activeIndex
                                        ? cs.onPrimary
                                        : cs.onSurfaceVariant,
                                size: index <= activeIndex ? 20 : 8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              steps[index],
                              style: tt.bodySmall?.copyWith(
                                fontWeight:
                                    index <= activeIndex
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                color:
                                    index <= activeIndex
                                        ? cs.primary
                                        : cs.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      if (index < steps.length - 1)
                        Expanded(
                          child: Container(
                            height: 2,
                            margin: const EdgeInsets.only(bottom: 32),
                            color:
                                index < activeIndex
                                    ? cs.primary
                                    : cs.outlineVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedStatusChip(String status, ColorScheme cs) {
    final statusLower = status.toLowerCase();
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (statusLower) {
      case 'delivered':
      case 'completed':
        bgColor = cs.tertiaryContainer;
        textColor = cs.onTertiaryContainer;
        icon = Icons.check_circle_rounded;
        break;
      case 'processing':
        bgColor = cs.primaryContainer;
        textColor = cs.onPrimaryContainer;
        icon = Icons.autorenew_rounded;
        break;
      case 'shipped':
        bgColor = cs.secondaryContainer;
        textColor = cs.onSecondaryContainer;
        icon = Icons.local_shipping_rounded;
        break;
      case 'cancelled':
        bgColor = cs.errorContainer;
        textColor = cs.onErrorContainer;
        icon = Icons.cancel_rounded;
        break;
      default:
        bgColor = cs.surfaceContainerHighest;
        textColor = cs.onSurface;
        icon = Icons.info_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: textColor),
          const SizedBox(width: 8),
          Text(
            status.capitalizeFirst ?? status,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedInfoRow(
    IconData icon,
    String label,
    String value,
    ColorScheme cs,
    TextTheme tt,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: cs.onPrimaryContainer),
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
                  style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
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

bool _isTerminal(String status) {
  final s = status.toLowerCase();
  return s == 'delivered' ||
      s == 'cancelled' ||
      s == 'returned' ||
      s == 'completed';
}

class _EnhancedCancelOrderButton extends StatefulWidget {
  final String orderId;
  const _EnhancedCancelOrderButton({required this.orderId});

  @override
  State<_EnhancedCancelOrderButton> createState() =>
      _EnhancedCancelOrderButtonState();
}

class _EnhancedCancelOrderButtonState
    extends State<_EnhancedCancelOrderButton> {
  bool _loading = false;
  final _controller = Get.put(OrderController());

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.error.withValues(alpha: 0.3), width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _loading ? null : _confirmAndCancel,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_loading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: cs.error,
                    ),
                  )
                else
                  Icon(Icons.cancel_rounded, color: cs.error, size: 22),
                const SizedBox(width: 12),
                Text(
                  'Cancel Order'.tr,
                  style: TextStyle(
                    color: cs.error,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndCancel() async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Get.theme.colorScheme.error,
            ),
            const SizedBox(width: 12),
            Text('Cancel Order?'.tr),
          ],
        ),
        content: Text('Do you really want to cancel this order?'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('No'.tr),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Get.theme.colorScheme.error,
              foregroundColor: Get.theme.colorScheme.onError,
            ),
            child: Text('Yes, Cancel'.tr),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _loading = true);
    try {
      debugPrint('[UI][BuyerOrderDetails] Cancelling order ${widget.orderId}');
      final ok = await _controller.cancelOrder(widget.orderId);
      if (ok) {
        Get.back(result: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _EnhancedItemTile extends StatefulWidget {
  final OrderModel item;
  final int index;
  const _EnhancedItemTile({required this.item, required this.index});

  @override
  State<_EnhancedItemTile> createState() => _EnhancedItemTileState();
}

class _EnhancedItemTileState extends State<_EnhancedItemTile>
    with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  final OrderController _controller = Get.put(OrderController());
  Map<String, dynamic>? _productData;
  bool _isLoadingProduct = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  double _computeRate() {
    final qty = widget.item.productQuantity;
    if (qty == 0) return widget.item.totalPrice;
    return widget.item.totalPrice / qty;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _fetchProductDetails();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchProductDetails() async {
    if (_isLoadingProduct) return;
    setState(() => _isLoadingProduct = true);

    try {
      final response = await _orderService.getProductById(
        widget.item.productId,
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
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
    final data = _productData;
    if (data == null) return null;

    final imageUrl = data['imageUrl']?.toString();
    final imagePath = data['imagePath']?.toString();
    final imageCode = data['imageCode']?.toString();
    final image = data['image']?.toString();

    if (imageUrl != null && imageUrl.isNotEmpty) return imageUrl;

    if (imagePath != null && imagePath.isNotEmpty) {
      if (imagePath.startsWith('http')) return imagePath;
      return imagePath;
    }

    final code =
        (imageCode?.isNotEmpty == true)
            ? imageCode!
            : ((image != null && !image.startsWith('http')) ? image : '');
    if (code.isNotEmpty) {
      return '${ApiConstants.getProductImageEndpoint}/$code';
    }

    if (image != null && image.startsWith('http')) return image;

    return null;
  }

  String? get _productCategory {
    return _productData?['category'];
  }

  Widget _buildEnhancedNumberBadge(ColorScheme cs, TextTheme tt) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primaryContainer, cs.primary.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '${widget.index}',
          style: tt.headlineSmall?.copyWith(
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

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cs.surface, cs.surfaceContainerLow],
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_productImage != null && _productImage!.isNotEmpty)
                        Hero(
                          tag: 'product-${widget.item.productId}',
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: cs.shadow.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                width: 72,
                                height: 72,
                                child: SafeNetworkImage(
                                  imageUrl: _productImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        _buildEnhancedNumberBadge(cs, tt),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isLoadingProduct ? 'Loading...' : _productName,
                              style: tt.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            if (_productCategory != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.secondaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.category_rounded,
                                      size: 14,
                                      color: cs.onSecondaryContainer,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _productCategory!,
                                      style: tt.bodySmall?.copyWith(
                                        color: cs.onSecondaryContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildEnhancedDetailColumn(
                            Icons.inventory_2_rounded,
                            'Quantity'.tr,
                            '${widget.item.productQuantity % 1 == 0 ? widget.item.productQuantity.toInt() : widget.item.productQuantity}',
                            cs,
                            tt,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          color: cs.outlineVariant,
                        ),
                        Expanded(
                          child: _buildEnhancedDetailColumn(
                            Icons.attach_money_rounded,
                            'Rate'.tr,
                            'Rs ${(_computeRate()).toStringAsFixed(2)}',
                            cs,
                            tt,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          color: cs.outlineVariant,
                        ),
                        Expanded(
                          child: _buildEnhancedDetailColumn(
                            Icons.receipt_rounded,
                            'Total'.tr,
                            'Rs ${widget.item.totalPrice.toStringAsFixed(2)}',
                            cs,
                            tt,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Enhanced Status Badges
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildEnhancedStatusBadge(
                        widget.item.orderStatus,
                        cs,
                        icon: Icons.info_rounded,
                      ),
                      _buildEnhancedStatusBadge(
                        widget.item.paymentStatus,
                        cs,
                        isPayment: true,
                        icon:
                            widget.item.paymentStatus.toLowerCase() == 'paid'
                                ? Icons.check_circle_rounded
                                : Icons.pending_rounded,
                      ),
                      if (widget.item.refundStatus != null &&
                          widget.item.refundStatus!.toLowerCase() != 'none')
                        _buildEnhancedStatusBadge(
                          widget.item.refundStatus!,
                          cs,
                          isRefund: true,
                          icon: Icons.replay_rounded,
                        ),
                      if (widget.item.deliveryConfirmedByBuyer)
                        _buildEnhancedStatusBadge(
                          'Delivered',
                          cs,
                          isDelivered: true,
                          icon: Icons.local_shipping_rounded,
                        ),
                    ],
                  ),

                  // Enhanced Mark as Delivered Button
                  if (_shouldShowMarkAsDeliveredButton())
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              cs.primary,
                              cs.primary.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isLoadingProduct ? null : _markAsDelivered,
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: cs.onPrimary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Mark as Delivered'.tr,
                                    style: TextStyle(
                                      color: cs.onPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
    );
  }

  bool _shouldShowMarkAsDeliveredButton() {
    return _controller.canMarkAsDelivered(widget.item);
  }

  Future<void> _markAsDelivered() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Get.theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                color: Get.theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('Confirm Delivery'.tr)),
          ],
        ),
        content: Text(
          'Have you received this item? Once confirmed, you acknowledge that the product has been delivered to you.'
              .tr,
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text('Cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Get.theme.colorScheme.primary,
              foregroundColor: Get.theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Confirm'.tr),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isLoadingProduct = true);
      debugPrint(
        '[ItemTile] Marking item ${widget.item.orderItemId} as delivered',
      );

      final ok = await _controller.markAsDelivered(widget.item.orderItemId);
      if (ok) {
        Get.snackbar(
          'Success'.tr,
          'Item marked as delivered successfully'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.primaryContainer,
          colorText: Get.theme.colorScheme.onPrimaryContainer,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          icon: Icon(
            Icons.check_circle_rounded,
            color: Get.theme.colorScheme.primary,
          ),
        );
        setState(() {});
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingProduct = false);
      }
    }
  }

  Widget _buildEnhancedDetailColumn(
    IconData icon,
    String label,
    String value,
    ColorScheme cs,
    TextTheme tt,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: cs.primary),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: tt.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: tt.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEnhancedStatusBadge(
    String status,
    ColorScheme cs, {
    bool isPayment = false,
    bool isRefund = false,
    bool isDelivered = false,
    IconData? icon,
  }) {
    Color bgColor;
    Color textColor;
    IconData badgeIcon;

    if (isPayment) {
      final isPaid = status.toLowerCase() == 'paid';
      bgColor = isPaid ? cs.tertiaryContainer : cs.secondaryContainer;
      textColor = isPaid ? cs.onTertiaryContainer : cs.onSecondaryContainer;
      badgeIcon =
          icon ?? (isPaid ? Icons.check_circle_rounded : Icons.pending_rounded);
    } else if (isRefund) {
      bgColor = cs.errorContainer;
      textColor = cs.onErrorContainer;
      badgeIcon = icon ?? Icons.replay_rounded;
    } else if (isDelivered) {
      bgColor = cs.tertiaryContainer;
      textColor = cs.onTertiaryContainer;
      badgeIcon = icon ?? Icons.local_shipping_rounded;
    } else {
      bgColor = cs.primaryContainer;
      textColor = cs.onPrimaryContainer;
      badgeIcon = icon ?? Icons.circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            status.capitalizeFirst ?? status,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
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
