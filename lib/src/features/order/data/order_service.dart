import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/src/core/networking/api_service.dart';

/// Thin wrapper around backend order endpoints.
class OrderService {
  late final ApiService _api;
  OrderService({ApiService? api}) {
    _api = api ?? (Get.isRegistered<ApiService>() ? Get.find<ApiService>() : ApiService());
  }

  // --- List endpoints ---
  Future<Response<dynamic>> getMyOrders() async {
    return _api.dio.get(
      ApiConstants.getMyOrdersEndpoint,
      options: Options(headers: {'accept': '*/*'}),
    );
  }

  Future<Response<dynamic>> getCustomerOrders() async {
    return _api.dio.get(
      ApiConstants.getCustomerOrdersEndpoint,
      options: Options(headers: {'accept': '*/*'}),
    );
  }

  // --- Order-level ---
  Future<Response<dynamic>> cancelOrder(String orderId) async {
    return _api.dio.put(
      '${ApiConstants.cancelOrderEndpoint}/$orderId',
      options: Options(headers: {'accept': '*/*'}),
    );
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
}
