import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:krishi_link/core/utils/api_constants.dart';
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
      final str = res.data.toString();
      final preview = str.length > 1500 ? str.substring(0, 1500) + '…' : str;
      // ignore: avoid_print
      // Use debugPrint to split long strings safely
      // printing a header for clarity
      debugPrint('[Orders][getMyOrders] status: ${res.statusCode}');
      debugPrint('[Orders][getMyOrders] body (preview):');
      debugPrint(preview);
    } catch (_) {}
    return res;
  }

  Future<Response<dynamic>> getCustomerOrders() async {
    return _api.dio.get(
      ApiConstants.getCustomerOrdersEndpoint,
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
      debugPrint('[Orders][cancelOrder] orderId=$orderId status: ${res.statusCode}');
      debugPrint('[Orders][cancelOrder] body: ${res.data}');
    } catch (_) {}
    return res;
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
    return _api.dio.put(
      '${ApiConstants.confirmOrderItemEndpoint}/$orderItemId',
      options: Options(headers: {'accept': '*/*'}),
    );
  }

  Future<Response<dynamic>> shipOrderItem(String orderItemId) async {
    return _api.dio.put(
      '${ApiConstants.shipOrderItemEndpoint}/$orderItemId',
      options: Options(headers: {'accept': '*/*'}),
    );
  }

  Future<Response<dynamic>> deliverOrderItem(String orderItemId) async {
    return _api.dio.put(
      '${ApiConstants.deliverOrderItemEndpoint}/$orderItemId',
      options: Options(headers: {'accept': '*/*'}),
    );
  }

  Future<Response<dynamic>> markAsDelivery(String orderItemId) async {
    return _api.dio.put(
      '${ApiConstants.markAsDeliveryEndpoint}/$orderItemId',
      options: Options(headers: {'accept': '*/*'}),
    );
  }

  // --- Product details ---
  Future<Response<dynamic>> getProductById(String productId) async {
    try {
      final res = await _api.dio.get(
        '${ApiConstants.getProductByIdEndpoint}/$productId',
        options: Options(headers: {'accept': '*/*'}),
      );
      debugPrint('[Orders][getProductById] productId=$productId status: ${res.statusCode}');
      return res;
    } catch (e) {
      debugPrint('[Orders][getProductById] Error fetching product $productId: $e');
      rethrow;
    }
  }
}
