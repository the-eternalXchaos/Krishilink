import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/src/features/order/data/order_service.dart';
import 'package:krishi_link/src/features/order/model/order_model.dart';

/// Shared Order Controller for both Farmer and Buyer
/// Manages order state, data fetching, and updates
class OrderController extends GetxController {
  final OrderService _orderService;
  final AuthController _authController;

  OrderController({OrderService? orderService, AuthController? authController})
    : _orderService =
          orderService ??
          (Get.isRegistered<OrderService>()
              ? Get.find<OrderService>()
              : Get.put(OrderService())),
      _authController =
          authController ??
          (Get.isRegistered<AuthController>()
              ? Get.find<AuthController>()
              : Get.put(AuthController(), permanent: true));

  // ==================== STATE ====================
  final RxList<OrderModel> orders = <OrderModel>[].obs;
  final RxList<OrderModel> filteredOrders = <OrderModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // User role
  String get userRole => _authController.userData?.role.toLowerCase() ?? '';
  bool get isFarmer => userRole == 'farmer';
  bool get isBuyer => userRole == 'buyer';

  // ==================== LIFECYCLE ====================
  @override
  void onInit() {
    super.onInit();
    fetchOrders();
  }

  // ==================== DATA FETCHING ====================

  /// Fetch orders based on user role
  Future<void> fetchOrders() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response =
          isFarmer
              ? await _orderService
                  .getCustomerOrders() // Farmer orders
              : await _orderService.getBuyerOrders(); // Buyer orders

      if (response.data == null || response.data['data'] == null) {
        throw Exception('Invalid response format');
      }

      final data = response.data['data'] as List;
      final fetchedOrders = <OrderModel>[];

      // Parse orders based on structure
      for (var orderData in data) {
        if (isFarmer) {
          // Farmer: Orders with nested orderItems
          fetchedOrders.addAll(_parseFarmerOrder(orderData));
        } else {
          // Buyer: Orders with nested orderItems
          fetchedOrders.addAll(_parseBuyerOrder(orderData));
        }
      }

      // Sort by date descending (latest first)
      fetchedOrders.sort((a, b) {
        final aDate = a.createdAt;
        final bDate = b.createdAt;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      orders.assignAll(fetchedOrders);
      filteredOrders.assignAll(fetchedOrders);

      debugPrint(
        '[OrderController] Fetched ${fetchedOrders.length} orders for $userRole',
      );
    } catch (e) {
      errorMessage.value = 'Failed to fetch orders: ${e.toString()}';
      debugPrint('[OrderController] Error fetching orders: $e');
      // Avoid intrusive popups on list pages; let UI render an inline error instead
    } finally {
      isLoading.value = false;
    }
  }

  /// Parse farmer order (from getCustomerOrders API)
  List<OrderModel> _parseFarmerOrder(Map<String, dynamic> orderData) {
    final orderItems = orderData['orderItems'] as List? ?? [];
    final fetchedOrders = <OrderModel>[];

    for (var item in orderItems) {
      // Map "Processing" to "Pending" for UI compatibility
      String itemStatus = item['itemStatus']?.toString() ?? 'pending';
      if (itemStatus.toLowerCase() == 'processing') {
        itemStatus = 'pending';
      }

      // Extract deliveryConfirmedByBuyer
      final deliveryConfirmedByBuyer =
          (item['deliveryConfirmedByBuyer'] ?? false) == true;

      String paymentStatus = item['paymentStatus']?.toString() ?? 'pending';
      if (paymentStatus.toLowerCase() == 'processing') {
        paymentStatus = 'pending';
      }

      // Get product name
      String productName = item['productName']?.toString() ?? '';
      final productId = item['productId']?.toString() ?? '';

      // Fetch product name if empty (you may want to cache this)
      if (productName.isEmpty && productId.isNotEmpty) {
        productName = 'Product #${productId.substring(0, 8)}';
      } else if (productName.isEmpty) {
        productName = 'Unknown Product';
      }

      fetchedOrders.add(
        OrderModel(
          orderId: orderData['orderId']?.toString() ?? '',
          orderItemId: item['orderItemId']?.toString() ?? '',
          productId: productId,
          productName: productName,
          productQuantity: (item['quantity'] ?? 0).toDouble(),
          unit: item['unit']?.toString() ?? 'kg',
          totalPrice: (item['totalPrice'] ?? 0.0).toDouble(),
          orderStatus: itemStatus.toLowerCase(),
          paymentStatus: paymentStatus.toLowerCase(),
          deliveryConfirmedByBuyer: deliveryConfirmedByBuyer,
          buyerId: orderData['buyerId']?.toString(),
          buyerName: orderData['buyerName']?.toString(),
          buyerContact: orderData['buyerContact']?.toString(),
          deliveryAddress: orderData['deliveryAddress']?.toString(),
          latitude:
              orderData['latitude'] != null
                  ? (orderData['latitude'] as num).toDouble()
                  : null,
          longitude:
              orderData['longitude'] != null
                  ? (orderData['longitude'] as num).toDouble()
                  : null,
          createdAt:
              orderData['orderDate'] != null
                  ? DateTime.tryParse(orderData['orderDate'].toString())
                  : null,
        ),
      );
    }

    return fetchedOrders;
  }

  /// Parse buyer order (from getBuyerOrders API)
  List<OrderModel> _parseBuyerOrder(Map<String, dynamic> orderData) {
    final orderItems = orderData['orderItems'] as List? ?? [];
    final fetchedOrders = <OrderModel>[];

    for (var item in orderItems) {
      // Map "Processing" to "Pending"
      String itemStatus = item['itemStatus']?.toString() ?? 'pending';
      if (itemStatus.toLowerCase() == 'processing') {
        itemStatus = 'pending';
      }

      final deliveryConfirmedByBuyer =
          (item['deliveryConfirmedByBuyer'] ?? false) == true;

      String paymentStatus = item['paymentStatus']?.toString() ?? 'pending';
      if (paymentStatus.toLowerCase() == 'processing') {
        paymentStatus = 'pending';
      }

      String productName = item['productName']?.toString() ?? '';
      final productId = item['productId']?.toString() ?? '';

      if (productName.isEmpty && productId.isNotEmpty) {
        productName = 'Product #${productId.substring(0, 8)}';
      } else if (productName.isEmpty) {
        productName = 'Unknown Product';
      }

      fetchedOrders.add(
        OrderModel(
          orderId: orderData['orderId']?.toString() ?? '',
          orderItemId: item['orderItemId']?.toString() ?? '',
          productId: productId,
          productName: productName,
          productQuantity: (item['quantity'] ?? 0).toDouble(),
          unit: item['unit']?.toString() ?? 'kg',
          totalPrice: (item['totalPrice'] ?? 0.0).toDouble(),
          orderStatus: itemStatus.toLowerCase(),
          paymentStatus: paymentStatus.toLowerCase(),
          deliveryConfirmedByBuyer: deliveryConfirmedByBuyer,
          refundStatus: item['refundStatus']?.toString(),
          // Buyer doesn't see farmer info, but we include for consistency
          buyerId: _authController.userData?.id,
          deliveryAddress: orderData['deliveryAddress']?.toString(),
          latitude:
              orderData['latitude'] != null
                  ? (orderData['latitude'] as num).toDouble()
                  : null,
          longitude:
              orderData['longitude'] != null
                  ? (orderData['longitude'] as num).toDouble()
                  : null,
          createdAt:
              orderData['orderDate'] != null
                  ? DateTime.tryParse(orderData['orderDate'].toString())
                  : null,
        ),
      );
    }

    return fetchedOrders;
  }

  // ==================== FILTERING & SEARCHING ====================

  void filterOrdersByStatus(String? status) {
    if (status == null || status == 'All') {
      filteredOrders.assignAll(orders);
    } else {
      filteredOrders.assignAll(
        orders
            .where(
              (order) =>
                  order.orderStatus.toLowerCase() == status.toLowerCase(),
            )
            .toList(),
      );
    }
  }

  void searchOrders(String query) {
    if (query.isEmpty) {
      filteredOrders.assignAll(orders);
    } else {
      filteredOrders.assignAll(
        orders
            .where(
              (order) =>
                  order.productName.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  order.orderId.toLowerCase().contains(query.toLowerCase()),
            )
            .toList(),
      );
    }
  }

  // ==================== ORDER UPDATES ====================

  /// Update order status (for farmers)
  Future<bool> updateOrderStatus({
    required String orderItemId,
    required String newStatus,
  }) async {
    try {
      switch (newStatus.toLowerCase()) {
        case 'confirmed':
          await _orderService.confirmOrderItem(orderItemId);
          break;
        case 'shipped':
          await _orderService.shipOrderItem(orderItemId);
          break;
        case 'delivered':
          await _orderService.deliverOrderItem(orderItemId);
          break;
        default:
          throw Exception('Invalid status: $newStatus');
      }

      // Update local state
      final index = orders.indexWhere((o) => o.orderItemId == orderItemId);
      if (index != -1) {
        orders[index] = orders[index].copyWith(
          orderStatus: newStatus.toLowerCase(),
        );
        orders.refresh();
        _refreshFilteredOrders();
      }

      PopupService.success('Order updated to $newStatus');
      return true;
    } catch (e) {
      debugPrint('[OrderController] Error updating order status: $e');
      PopupService.error('Failed to update order: ${e.toString()}');
      return false;
    }
  }

  /// Mark order item as delivered (for buyers)
  Future<bool> markAsDelivered(String orderItemId) async {
    try {
      await _orderService.markAsDelivery(orderItemId);

      // Update local state
      final index = orders.indexWhere((o) => o.orderItemId == orderItemId);
      if (index != -1) {
        orders[index] = orders[index].copyWith(deliveryConfirmedByBuyer: true);
        orders.refresh();
        _refreshFilteredOrders();
      }

      PopupService.success('Order marked as delivered');
      return true;
    } catch (e) {
      debugPrint('[OrderController] Error marking as delivered: $e');
      PopupService.error('Failed to mark as delivered: ${e.toString()}');
      return false;
    }
  }

  /// Cancel entire order
  Future<bool> cancelOrder(String orderId) async {
    try {
      await _orderService.cancelOrder(orderId);

      // Update local state - mark all items of this order as cancelled
      for (var i = 0; i < orders.length; i++) {
        if (orders[i].orderId == orderId) {
          orders[i] = orders[i].copyWith(orderStatus: 'cancelled');
        }
      }
      orders.refresh();
      _refreshFilteredOrders();

      PopupService.success('Order cancelled');
      return true;
    } catch (e) {
      debugPrint('[OrderController] Error cancelling order: $e');
      PopupService.error('Failed to cancel order: ${e.toString()}');
      return false;
    }
  }

  /// Cancel specific order item
  Future<bool> cancelOrderItem({
    required String orderId,
    required String orderItemId,
  }) async {
    try {
      await _orderService.cancelOrderItem(
        orderId: orderId,
        orderItemId: orderItemId,
      );

      // Update local state
      final index = orders.indexWhere((o) => o.orderItemId == orderItemId);
      if (index != -1) {
        orders[index] = orders[index].copyWith(orderStatus: 'cancelled');
        orders.refresh();
        _refreshFilteredOrders();
      }

      PopupService.success('Order item cancelled');
      return true;
    } catch (e) {
      debugPrint('[OrderController] Error cancelling order item: $e');
      PopupService.error('Failed to cancel item: ${e.toString()}');
      return false;
    }
  }

  // ==================== HELPERS ====================

  void _refreshFilteredOrders() {
    // Maintain current filter
    if (filteredOrders.length != orders.length) {
      // A filter is active, reapply it
      final currentFilter = _getCurrentFilter();
      if (currentFilter != null) {
        filterOrdersByStatus(currentFilter);
      }
    } else {
      filteredOrders.assignAll(orders);
    }
  }

  String? _getCurrentFilter() {
    if (filteredOrders.isEmpty || orders.isEmpty) return null;
    if (filteredOrders.length == orders.length) return null;

    // Detect which status is filtered
    final firstStatus = filteredOrders.first.orderStatus;
    final allSameStatus = filteredOrders.every(
      (o) => o.orderStatus == firstStatus,
    );
    return allSameStatus ? firstStatus : null;
  }

  /// Get order by ID
  OrderModel? getOrderById(String orderId, String orderItemId) {
    try {
      return orders.firstWhere(
        (o) => o.orderId == orderId && o.orderItemId == orderItemId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if order can be cancelled
  bool canCancelOrder(OrderModel order) {
    final status = order.orderStatus.toLowerCase();
    return status == 'pending' ||
        status == 'confirmed' ||
        status == 'processing';
  }

  /// Check if farmer can update status
  bool canUpdateStatus(OrderModel order) {
    if (!isFarmer) return false;
    final status = order.orderStatus.toLowerCase();
    return status == 'pending' || status == 'confirmed' || status == 'shipped';
  }

  /// Check if buyer can mark as delivered
  bool canMarkAsDelivered(OrderModel order) {
    if (!isBuyer) return false;
    return order.orderStatus.toLowerCase() == 'delivered' &&
        !order.deliveryConfirmedByBuyer;
  }
}
