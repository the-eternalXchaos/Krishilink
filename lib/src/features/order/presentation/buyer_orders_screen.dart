import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/src/features/order/data/order_service.dart';
import 'package:krishi_link/src/features/order/model/order_model.dart';
import 'package:krishi_link/src/features/product/data/models/product_model.dart';
import 'package:krishi_link/src/features/product/presentation/controllers/product_controller.dart';
import 'package:krishi_link/widgets/safe_network_image.dart';

class BuyerOrdersScreen extends StatefulWidget {
  const BuyerOrdersScreen({super.key});

  @override
  State<BuyerOrdersScreen> createState() => _BuyerOrdersScreenState();
}

class _BuyerOrdersScreenState extends State<BuyerOrdersScreen> {
  final OrderService _orderService = Get.put(OrderService());
  bool _loading = true;
  String? _error;
  List<OrderModel> _orders = const [];
  // Cache product names by productId to avoid repeated network calls
  final Map<String, String> _productNames = {};
  final Set<String> _fetchingProductIds = {};
  // Cache product images by productId
  final Map<String, String> _productImages = {};

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _orderService.getMyOrders();
      debugPrint('[UI][BuyerOrders] Fetched orders: status=${res.statusCode}');
      debugPrint(
        '[UI][BuyerOrders] Raw body (preview): ${res.data.toString().length > 1500 ? '${res.data.toString().substring(0, 1500)}…' : res.data.toString()}',
      );
      final data = res.data;
      List list;
      if (data is List) {
        list = data;
      } else if (data is Map) {
        // Try common wrappers: { success, data: [...] } or { orders: [...] }
        final inner = data['data'] ?? data['orders'] ?? data['result'] ?? [];
        list = inner is List ? inner : [];
      } else if (data is String) {
        try {
          final parsed = jsonDecode(data);
          if (parsed is List) {
            list = parsed;
          } else if (parsed is Map && parsed['data'] is List) {
            list = parsed['data'] as List;
          } else {
            list = const [];
          }
        } catch (_) {
          list = const [];
        }
      } else {
        list = const [];
      }

      // Parse buyer orders with orderItems array
      final orders = <OrderModel>[];
      for (final item in list.whereType<Map>()) {
        final orderMap = item.cast<String, dynamic>();
        final orderId = orderMap['orderId']?.toString() ?? '';
        final buyerId = orderMap['buyerId']?.toString();
        final orderDate =
            orderMap['orderDate'] != null
                ? DateTime.tryParse(orderMap['orderDate'].toString())
                : null;
        final updatedAt =
            orderMap['updatedAt'] != null
                ? DateTime.tryParse(orderMap['updatedAt'].toString())
                : null;

        // Get order items array
        final orderItems = orderMap['orderItems'];
        if (orderItems is List && orderItems.isNotEmpty) {
          // Create an OrderModel for each order item
          for (final orderItem in orderItems) {
            if (orderItem is Map) {
              final itemMap = orderItem.cast<String, dynamic>();

              // Flatten the structure to match OrderModel
              final flatOrder = {
                'orderId': orderId,
                'orderItemId': itemMap['orderItemId'],
                'productId': itemMap['productId'],
                'productName': '', // Will be fetched separately
                'productQuantity': itemMap['quantity'] ?? 0,
                'unit': 'kg',
                'totalPrice': (itemMap['totalPrice'] ?? 0).toDouble(),
                'orderStatus':
                    itemMap['itemStatus']?.toString().toLowerCase() ??
                    'pending',
                'paymentStatus': itemMap['paymentStatus'] ?? 'COD',
                'refundStatus': itemMap['refundStatus'],
                'buyerId': buyerId,
                'buyerName': null,
                'buyerContact': null,
                'deliveryAddress': null,
                'latitude': null,
                'longitude': null,
                'createdAt': orderDate?.toIso8601String(),
                'deliveredAt': updatedAt?.toIso8601String(),
                'deliveryConfirmedByBuyer':
                    itemMap['deliveryConfirmedByBuyer'] ?? false,
              };

              try {
                orders.add(OrderModel.fromJson(flatOrder));
              } catch (e) {
                debugPrint('[UI][BuyerOrders] Error parsing order item: $e');
              }
            }
          }
        }
      }

      // Sort to show latest orders first (by createdAt, fallback to deliveredAt)
      DateTime _key(OrderModel o) =>
          o.createdAt ?? o.deliveredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      orders.sort((a, b) => _key(b).compareTo(_key(a)));

      setState(() {
        _orders = orders;
        _loading = false;
      });

      // Kick off product name fetches for all unique productIds
      final uniqueIds = _orders.map((e) => e.productId).toSet();
      for (final pid in uniqueIds) {
        _ensureProductName(pid);
        _ensureProductImage(pid);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _ensureProductImage(String productId) async {
    if (productId.isEmpty) return;
    if (_productImages.containsKey(productId)) return;
    if (_fetchingProductIds.contains(productId)) return;
    _fetchingProductIds.add(productId);
    try {
      // Try product from ProductController cache first
      if (Get.isRegistered<ProductController>()) {
        final pc = Get.find<ProductController>();
        Product? cached;
        for (final p in pc.products) {
          if (p.id == productId) {
            cached = p;
            break;
          }
        }
        if (cached != null && cached.image.isNotEmpty) {
          setState(() => _productImages[productId] = cached!.image);
          return;
        }
      }

      // Fallback: fetch single product via existing endpoint
      final res = await _orderService.getProductById(productId);
      if (res.statusCode == 200 && res.data is Map) {
        final data = res.data as Map;
        final inner =
            (data['data'] as Map<String, dynamic>?) ??
            data.cast<String, dynamic>();
        final product = Product.fromJson(inner);
        if (product.image.isNotEmpty) {
          setState(() => _productImages[productId] = product.image);
        }
      }
    } catch (_) {
      // ignore
    } finally {
      _fetchingProductIds.remove(productId);
    }
  }

  Future<void> _ensureProductName(String productId) async {
    if (productId.isEmpty) return;
    if (_productNames.containsKey(productId)) return;
    if (_fetchingProductIds.contains(productId)) return;
    _fetchingProductIds.add(productId);
    try {
      final res = await _orderService.getProductById(productId);
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data;
        String? name;
        if (data is Map<String, dynamic>) {
          final inner = (data['data'] as Map<String, dynamic>?) ?? data;
          name = (inner['productName'] ?? inner['name'])?.toString();
        }
        name ??= 'Product #${_shortId(productId)}';

        // Cache and update any matching orders with empty productName
        setState(() {
          _productNames[productId] = name!;
          _orders =
              _orders
                  .map(
                    (o) =>
                        o.productId == productId && (o.productName.isEmpty)
                            ? o.copyWith(productName: name)
                            : o,
                  )
                  .toList();
        });
      }
    } catch (e) {
      // Cache a fallback to avoid retry loops
      setState(() {
        _productNames[productId] = 'Product #${_shortId(productId)}';
      });
    } finally {
      _fetchingProductIds.remove(productId);
    }
  }

  String _shortId(String id) {
    if (id.length <= 8) return id;
    return '${id.substring(0, 4)}…${id.substring(id.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('My Orders'.tr),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: RefreshIndicator(onRefresh: _fetch, child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _fetch);
    }
    if (_orders.isEmpty) {
      return _EmptyView(onReload: _fetch);
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: _orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final o = _orders[index];
        // Resolve display name (cache > model > short id)
        final cachedName = _productNames[o.productId];
        if (cachedName == null) {
          // Ensure fetch started for this product
          _ensureProductName(o.productId);
        }
        final displayName =
            cachedName?.isNotEmpty == true
                ? cachedName!
                : (o.productName.isNotEmpty
                    ? o.productName
                    : 'Product #${_shortId(o.productId)}');

        // Resolve image URL and kick off fetch if missing
        final imageUrl = _productImages[o.productId];
        if (imageUrl == null) {
          _ensureProductImage(o.productId);
        }

        return _OrderTile(
          order: o,
          displayProductName: displayName,
          imageUrl: imageUrl,
          onOpen: () async {
            // Log the order payload and navigate to details
            debugPrint('[UI][BuyerOrders] Opening order ${o.orderId}');
            debugPrint('[UI][BuyerOrders] Order payload: $o');
            final result = await Get.toNamed(
              '/buyer-order-details',
              arguments: o,
            );
            if (result == true) {
              // e.g., after cancel, refresh
              _fetch();
            }
          },
        );
      },
    );
  }
}

class _OrderTile extends StatelessWidget {
  final OrderModel order;
  final String displayProductName;
  final String? imageUrl;
  final Future<void> Function() onOpen;
  const _OrderTile({
    required this.order,
    required this.displayProductName,
    required this.imageUrl,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Check if buyer confirmed delivery
    final hasDeliveredItems = order.deliveryConfirmedByBuyer;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child:
                          imageUrl != null && imageUrl!.isNotEmpty
                              ? SafeNetworkImage(
                                imageUrl: imageUrl!,
                                fit: BoxFit.cover,
                              )
                              : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      cs.primaryContainer,
                                      cs.primary.withValues(alpha: 0.5),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Icon(
                                  Icons.shopping_bag_outlined,
                                  color: cs.primary,
                                  size: 28,
                                ),
                              ),
                    ),
                  ),
                  if (hasDeliveredItems)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Order #${_shortId(order.orderId)}',
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _StatusBadge(status: order.orderStatus),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Give product name its own larger row (wrap up to 2 lines)
                    Text(
                      displayProductName,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Put date (left) and price (right) on the same row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _formatDate(order.createdAt) ?? '',
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.payments_outlined,
                              size: 14,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Rs ${order.totalPrice.toStringAsFixed(2)}',
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: cs.primary, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  String? _formatDate(DateTime? dt) {
    if (dt == null) return null;
    // Simple yyyy-MM-dd HH:mm display
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  String _shortId(String id) {
    if (id.length <= 8) return id;
    return '${id.substring(0, 4)}…${id.substring(id.length - 4)}';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        bgColor = Colors.green.withValues(alpha: 0.15);
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        break;
      case 'shipped':
        bgColor = Colors.blue.withValues(alpha: 0.15);
        textColor = Colors.blue.shade700;
        icon = Icons.local_shipping;
        break;
      case 'confirmed':
      case 'processing':
        bgColor = Colors.orange.withValues(alpha: 0.15);
        textColor = Colors.orange.shade700;
        icon = Icons.autorenew;
        break;
      case 'cancelled':
        bgColor = Colors.red.withValues(alpha: 0.15);
        textColor = Colors.red.shade700;
        icon = Icons.cancel;
        break;
      default:
        bgColor = cs.surfaceContainerHighest;
        textColor = cs.onSurface;
        icon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
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
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onReload;
  const _EmptyView({required this.onReload});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(Icons.receipt_long, size: 64, color: cs.onSurfaceVariant),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'No orders yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Your orders will show up here.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton.icon(
            onPressed: onReload,
            icon: const Icon(Icons.refresh),
            label: const Text('Reload'),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(Icons.error_outline, size: 64, color: cs.error),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ),
      ],
    );
  }
}
