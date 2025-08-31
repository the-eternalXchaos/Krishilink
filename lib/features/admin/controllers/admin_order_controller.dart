// lib/features/admin/controller/admin_order_controller.dart
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:krishi_link/core/lottie/popup.dart';
import 'package:krishi_link/core/constants/api_constants.dart';
import 'package:krishi_link/features/admin/models/order_model.dart';
import 'package:krishi_link/services/token_service.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';

class AdminOrderController extends GetxController {
  final orders = <OrderModel>[].obs;
  final filteredOrders = <OrderModel>[].obs; // Store filtered orders
  final isLoading = false.obs;
  final totalOrders = 0.obs;
  final pendingOrders = 0.obs;
  final totalRevenue = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      isLoading(true);
      PopupService.lottieLoading();
      final token = await TokenService.getAccessToken();
      if (token == null) throw Exception('No authentication token');
      final response = await http.get(
        Uri.parse(ApiConstants.getMyOrdersEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final orderList =
            data.map((json) => OrderModel.fromJson(json)).toList();
        orders.assignAll(orderList);
        filteredOrders.assignAll(orderList); // Initialize filteredOrders
        totalOrders.value = orders.length;
        pendingOrders.value =
            orders
                .where((o) => o.orderStatus.toLowerCase() == 'pending')
                .length;
        totalRevenue.value = orders.fold(0.0, (sum, o) => sum + o.totalPrice);
      } else {
        throw Exception('Failed to fetch orders: ${response.statusCode}');
      }
    } catch (e) {
      PopupService.show(
        type: PopupType.error,
        title: 'Error',
        message: 'Failed to load orders: $e',
        autoDismiss: true,
      );
    } finally {
      isLoading(false);
      PopupService.close();
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      isLoading(true);
      PopupService.lottieLoading();
      final order = orders.firstWhere((o) => o.orderId == orderId);
      final endpoint = switch (status.toLowerCase()) {
        'confirmed' => ApiConstants.confirmOrderEndpoint,
        'shipped' => ApiConstants.shipOrderEndpoint,
        'delivered' => ApiConstants.deliverOrderEndpoint,
        'cancelled' => ApiConstants.cancelOrderEndpoint,
        _ => throw Exception('Invalid status'),
      };
      final response = await http.put(
        Uri.parse('$endpoint/$orderId'),
        headers: {
          'Authorization': 'Bearer ${await TokenService.getAccessToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final updatedOrder = order.copyWith(orderStatus: status);
        final index = orders.indexOf(order);
        orders[index] = updatedOrder;
        filteredOrders[index] = updatedOrder; // Update filtered list
        pendingOrders.value =
            orders
                .where((o) => o.orderStatus.toLowerCase() == 'pending')
                .length;
        PopupService.show(
          type: PopupType.success,
          title: 'Success',
          message: 'Order status updated to $status',
          autoDismiss: true,
        );
      } else {
        throw Exception('Failed to update order: ${response.statusCode}');
      }
    } catch (e) {
      PopupService.show(
        type: PopupType.error,
        title: 'Error',
        message: 'Failed to update order: $e',
        autoDismiss: true,
      );
    } finally {
      isLoading(false);
      PopupService.close();
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
                  order.productId.toLowerCase().contains(query.toLowerCase()) ||
                  order.orderId.toLowerCase().contains(query.toLowerCase()),
            )
            .toList(),
      );
    }
    totalOrders.value = filteredOrders.length;
    pendingOrders.value =
        filteredOrders
            .where((o) => o.orderStatus.toLowerCase() == 'pending')
            .length;
    totalRevenue.value = filteredOrders.fold(
      0.0,
      (sum, o) => sum + o.totalPrice,
    );
  }

  void filterOrdersByStatus(String? status) {
    if (status == null || status.toLowerCase() == 'all') {
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
    totalOrders.value = filteredOrders.length;
    pendingOrders.value =
        filteredOrders
            .where((o) => o.orderStatus.toLowerCase() == 'pending')
            .length;
    totalRevenue.value = filteredOrders.fold(
      0.0,
      (sum, o) => sum + o.totalPrice,
    );
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      isLoading(true);
      PopupService.lottieLoading();
      final response = await http.delete(
        Uri.parse('${ApiConstants.deleteOrderEndpoint}/$orderId'),
        headers: {
          'Authorization': 'Bearer ${await TokenService.getAccessToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        orders.removeWhere((order) => order.orderId == orderId);
        filteredOrders.removeWhere((order) => order.orderId == orderId);
        totalOrders.value = filteredOrders.length;
        pendingOrders.value =
            filteredOrders
                .where((o) => o.orderStatus.toLowerCase() == 'pending')
                .length;
        totalRevenue.value = filteredOrders.fold(
          0.0,
          (sum, o) => sum + o.totalPrice,
        );
        PopupService.show(
          type: PopupType.success,
          title: 'Success',
          message: 'Order deleted successfully',
          autoDismiss: true,
        );
      } else {
        throw Exception('Failed to delete order: ${response.statusCode}');
      }
    } catch (e) {
      PopupService.show(
        type: PopupType.error,
        title: 'Error',
        message: 'Failed to delete order: $e',
        autoDismiss: true,
      );
    } finally {
      isLoading(false);
      PopupService.close();
    }
  }
}
