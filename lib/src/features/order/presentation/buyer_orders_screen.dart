import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/src/features/order/data/order_service.dart';
import 'package:krishi_link/src/features/order/model/buyer_order_models.dart';

class BuyerOrdersScreen extends StatefulWidget {
  const BuyerOrdersScreen({super.key});

  @override
  State<BuyerOrdersScreen> createState() => _BuyerOrdersScreenState();
}

class _BuyerOrdersScreenState extends State<BuyerOrdersScreen> {
  final OrderService _orderService = Get.put(OrderService());
  bool _loading = true;
  String? _error;
  List<BuyerOrder> _orders = const [];

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
    debugPrint('[UI][BuyerOrders] Raw body (preview): ' +
      (res.data.toString().length > 1500
        ? res.data.toString().substring(0, 1500) + '…'
        : res.data.toString()));
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
    final orders = list
      .whereType<Map>()
      .map((e) => BuyerOrder.fromJson(e.cast<String, dynamic>()))
      .toList();
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
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
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: _buildBody(context),
      ),
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
        return _OrderTile(order: o, onOpen: () async {
          // Log the order payload and navigate to details
          debugPrint('[UI][BuyerOrders] Opening order ${o.orderId}');
          debugPrint('[UI][BuyerOrders] Order payload: ' + o.toString());
          final result = await Get.toNamed('/buyer-order-details', arguments: o);
          if (result == true) {
            // e.g., after cancel, refresh
            _fetch();
          }
        });
      },
    );
  }
}

class _OrderTile extends StatelessWidget {
  final BuyerOrder order;
  final Future<void> Function() onOpen;
  const _OrderTile({required this.order, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
  onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.shopping_bag, color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order ${_shortId(order.orderId)}',
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _Chip(label: order.overallStatus.capitalizeFirst ?? order.overallStatus),
                        const SizedBox(width: 8),
                        _Chip(label: 'Rs ${order.totalAmount.toStringAsFixed(2)}'),
                        const SizedBox(width: 8),
                        _Chip(label: '${order.items.length} item${order.items.length == 1 ? '' : 's'}'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(order.orderDate) ?? '',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  String? _formatDate(DateTime? dt) {
    if (dt == null) return null;
    // Simple yyyy-MM-dd HH:mm display
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  String _shortId(String id) {
    if (id.length <= 8) return id;
    return '${id.substring(0, 4)}…${id.substring(id.length - 4)}';
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
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
