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
        orders.assignAll(
          data.map((json) => OrderModel.fromJson(json)).toList(),
        );
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
      final endpoint = switch (status) {
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
        orders[orders.indexOf(order)] = order.copyWith(orderStatus: status);
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
}
