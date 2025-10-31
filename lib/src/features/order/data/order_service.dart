import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:krishi_link/src/core/constants/api_constants.dart';
import 'package:krishi_link/src/core/networking/api_service.dart';

/// Thin wrapper around backend order endpoints.
class OrderService {
  late final ApiService _api;
  OrderService({ApiService? api}) {
    _api =
        api ??
        (Get.isRegistered<ApiService>()
            ? Get.find<ApiService>()
            : ApiService());
  }

  // --- List endpoints ---
  Future<Response<dynamic>> getMyOrders() async {
    final res = await _api.dio.get(
      ApiConstants.getMyOrdersEndpoint,
      options: Options(headers: {'accept': '*/*'}),
    );
    // Debug: log response shape (truncate to avoid huge logs)
    try {
      debugPrint('[Orders][getMyOrders] status: ${res.statusCode}');

      // Log first order item to see the structure
      if (res.data != null && res.data is Map) {
        final data = res.data as Map<String, dynamic>;
        if (data['data'] != null && data['data'] is List) {
          final orders = data['data'] as List;
          if (orders.isNotEmpty) {
            debugPrint('[Orders][getMyOrders] First order structure:');
            debugPrint('  orderId: ${orders[0]['orderId']}');
            debugPrint('  orderItemId: ${orders[0]['orderItemId']}');
            debugPrint('  id: ${orders[0]['id']}');
            debugPrint('  All keys: ${orders[0].keys.toList()}');
          }
        }
      }

      final str = res.data.toString();
      final preview = str.length > 1500 ? '${str.substring(0, 1500)}…' : str;
      debugPrint('[Orders][getMyOrders] body (preview):');
      debugPrint(preview);
    } catch (e) {
      debugPrint('[Orders][getMyOrders] Debug error: $e');
    }
    return res;
  }

  Future<Response<dynamic>> getCustomerOrders() async {
    return _api.dio.get(
      ApiConstants.getCustomerOrdersEndpoint,
      options: Options(headers: {'accept': '*/*'}),
    );
  }

  Future<Response<dynamic>> getBuyerOrders() async {
    return _api.dio.get(
      ApiConstants.getBuyerOrdersEndpoint,
      options: Options(headers: {'accept': '*/*'}),
    );
  }

  // --- Order-level ---
  Future<Response<dynamic>> cancelOrder(String orderId) async {
    final res = await _api.dio.put(
      '${ApiConstants.cancelOrderEndpoint}/$orderId',
      options: Options(headers: {'accept': '*/*'}),
    );
    try {
      debugPrint(
        '[Orders][cancelOrder] orderId=$orderId status: ${res.statusCode}',
      );
      debugPrint('[Orders][cancelOrder] body: ${res.data}');
    } catch (_) {}
    return res;
  }

  Future<Response<dynamic>> confirmOrder(String orderItemId) async {
    try {
      debugPrint(
        '[Orders][confirmOrder] 🔄 Confirming orderItemId: $orderItemId',
      );
      debugPrint(
        '[Orders][confirmOrder] 🌐 Endpoint: ${ApiConstants.confirmOrderItemEndpoint}/$orderItemId',
      );

      final res = await _api.dio.put(
        '${ApiConstants.confirmOrderItemEndpoint}/$orderItemId',
        options: Options(headers: {'accept': '*/*'}),
      );

      debugPrint('[Orders][confirmOrder] ✅ Success! Status: ${res.statusCode}');
      debugPrint('[Orders][confirmOrder] 📦 Response: ${res.data}');
      return res;
    } catch (e) {
      debugPrint('[Orders][confirmOrder] ❌ Error: $e');
      rethrow;
    }
  }

  Future<Response<dynamic>> shipOrder(String orderItemId) async {
    try {
      debugPrint('[Orders][shipOrder] 🚚 Shipping orderItemId: $orderItemId');
      debugPrint(
        '[Orders][shipOrder] 🌐 Endpoint: ${ApiConstants.shipOrderItemEndpoint}/$orderItemId',
      );

      final res = await _api.dio.put(
        '${ApiConstants.shipOrderItemEndpoint}/$orderItemId',
        options: Options(headers: {'accept': '*/*'}),
      );

      debugPrint('[Orders][shipOrder] ✅ Success! Status: ${res.statusCode}');
      debugPrint('[Orders][shipOrder] 📦 Response: ${res.data}');
      return res;
    } catch (e) {
      debugPrint('[Orders][shipOrder] ❌ Error: $e');
      rethrow;
    }
  }

  Future<Response<dynamic>> deliverOrder(String orderItemId) async {
    try {
      debugPrint(
        '[Orders][deliverOrder] 📦 Delivering orderItemId: $orderItemId',
      );
      debugPrint(
        '[Orders][deliverOrder] 🌐 Endpoint: ${ApiConstants.deliverOrderItemEndpoint}/$orderItemId',
      );

      final res = await _api.dio.put(
        '${ApiConstants.deliverOrderItemEndpoint}/$orderItemId',
        options: Options(headers: {'accept': '*/*'}),
      );

      debugPrint('[Orders][deliverOrder] ✅ Success! Status: ${res.statusCode}');
      debugPrint('[Orders][deliverOrder] 📦 Response: ${res.data}');
      return res;
    } catch (e) {
      debugPrint('[Orders][deliverOrder] ❌ Error: $e');
      rethrow;
    }
  }

  // --- Item-level ---
  Future<Response<dynamic>> cancelOrderItem({
    required String orderId,
    required String orderItemId,
  }) async {
    return _api.dio.put(
      '${ApiConstants.cancelOrderItemEndpoint}/$orderId/$orderItemId',
      options: Options(headers: {'accept': '*/*'}),
    );
  }

  Future<Response<dynamic>> confirmOrderItem(String orderItemId) async {
    final url = '${ApiConstants.confirmOrderItemEndpoint}/$orderItemId';
    debugPrint('[OrderService] confirmOrderItem - URL: $url');
    debugPrint('[OrderService] confirmOrderItem - orderItemId: $orderItemId');
    return _api.dio.put(url, options: Options(headers: {'accept': '*/*'}));
  }

  Future<Response<dynamic>> shipOrderItem(String orderItemId) async {
    final url = '${ApiConstants.shipOrderItemEndpoint}/$orderItemId';
    debugPrint('[OrderService] shipOrderItem - URL: $url');
    debugPrint('[OrderService] shipOrderItem - orderItemId: $orderItemId');
    return _api.dio.put(url, options: Options(headers: {'accept': '*/*'}));
  }

  Future<Response<dynamic>> deliverOrderItem(String orderItemId) async {
    final url = '${ApiConstants.deliverOrderItemEndpoint}/$orderItemId';
    debugPrint('[OrderService] deliverOrderItem - URL: $url');
    debugPrint('[OrderService] deliverOrderItem - orderItemId: $orderItemId');
    return _api.dio.put(url, options: Options(headers: {'accept': '*/*'}));
  }

  Future<Response<dynamic>> markAsDelivery(String orderItemId) async {
    final url = '${ApiConstants.markAsDeliveryEndpoint}/$orderItemId';
    debugPrint('[OrderService] markAsDelivery - URL: $url');
    debugPrint('[OrderService] markAsDelivery - orderItemId: $orderItemId');
    return _api.dio.put(url, options: Options(headers: {'accept': '*/*'}));
  }

  // --- Product details ---
  Future<Response<dynamic>> getProductById(String productId) async {
    try {
      final res = await _api.dio.get(
        '${ApiConstants.getProductByIdEndpoint}/$productId',
        options: Options(headers: {'accept': '*/*'}),
      );
      debugPrint(
        '[Orders][getProductById] productId=$productId status: ${res.statusCode}',
      );
      return res;
    } catch (e) {
      debugPrint(
        '[Orders][getProductById] Error fetching product $productId: $e',
      );
      rethrow;
    }
  }

  // --- User details ---
  Future<Response<dynamic>> getUserDetailsById(String userId) async {
    try {
      final res = await _api.dio.get(
        ApiConstants.getUserDetailsByIdEndpoint,
        queryParameters: {'userId': userId},
        options: Options(headers: {'accept': '*/*'}),
      );
      debugPrint(
        '[Orders][getUserDetailsById] userId=$userId status: ${res.statusCode}',
      );
      return res;
    } catch (e) {
      debugPrint(
        '[Orders][getUserDetailsById] Error fetching user $userId: $e',
      );
      rethrow;
    }
  }
}
