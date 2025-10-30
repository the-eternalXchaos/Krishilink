import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/src/core/networking/api_service.dart';

/// Backend-integrated payment service for eSewa, Khalti, and COD via your API.
///
/// This does NOT change any gateway contracts; it simply calls your backend
/// endpoints exactly as documented:
/// - POST /api/Payment/initiatePaymentForEsewa (multipart: cartId, totalPayableAmount)
/// - GET  /api/Payment/esewaSuccess?data=...
/// - GET  /api/Payment/failure?data=...
/// - POST /api/Payment/initiatePaymentForKhalti (multipart: cartId, totalPayableAmount)
/// - GET  /api/Payment/khaltiResponse?... (pidx, status, ...)
/// - POST /api/Payment/cashOnDelivery (multipart: cartId, totalPayableAmount)
class BackendPaymentService {
  late final ApiService _api;
  BackendPaymentService({ApiService? api}) {
    _api =
        api ??
        (Get.isRegistered<ApiService>()
            ? Get.find<ApiService>()
            : ApiService());
  }

  Future<Response<dynamic>> initiateEsewa({
    required String cartId,
    required double totalPayableAmount,
  }) async {
    if (kDebugMode) {
      debugPrint('[Payment][eSewa] Initiating payment');
      debugPrint(
        '[Payment][eSewa] Endpoint: ${ApiConstants.initiateEsewaPaymentEndpoint}',
      );
      debugPrint(
        '[Payment][eSewa] Payload: {cartId: $cartId, totalPayableAmount: ${totalPayableAmount.toStringAsFixed(2)}}',
      );
    }
    final form = FormData.fromMap({
      'cartId': cartId,
      'totalPayableAmount': totalPayableAmount,
    });
    try {
      final res = await _api.dio.post(
        ApiConstants.initiateEsewaPaymentEndpoint,
        data: form,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {'accept': '*/*'},
        ),
      );
      if (kDebugMode) {
        debugPrint(
          '[Payment][eSewa] Status: ${res.statusCode?.toString() ?? 'null'}',
        );
        debugPrint('[Payment][eSewa] Response: ${res.data}');
      }
      return res;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[Payment][eSewa][ERROR] Type: ${e.type}');
        debugPrint('[Payment][eSewa][ERROR] Message: ${e.message ?? ''}');
        debugPrint(
          '[Payment][eSewa][ERROR] Status: ${e.response?.statusCode?.toString() ?? 'null'}',
        );
        debugPrint(
          '[Payment][eSewa][ERROR] Data: ${e.response?.data?.toString() ?? 'null'}',
        );
      }
      rethrow;
    }
  }

  Future<Response<dynamic>> esewaSuccess({required String data}) async {
    return _api.dio.get(
      ApiConstants.esewaSuccessEndpoint,
      queryParameters: {'data': data},
      options: Options(headers: {'accept': '*/*'}),
    );
  }

  Future<Response<dynamic>> esewaFailure({required String data}) async {
    return _api.dio.get(
      ApiConstants.esewaFailureEndpoint,
      queryParameters: {'data': data},
      options: Options(headers: {'accept': '*/*'}),
    );
  }

  Future<Response<dynamic>> initiateKhalti({
    required String cartId,
    required double totalPayableAmount,
  }) async {
    if (kDebugMode) {
      debugPrint('[Payment][Khalti] Initiating payment');
      debugPrint(
        '[Payment][Khalti] Endpoint: ${ApiConstants.initiateKhaltiPaymentEndpoint}',
      );
      debugPrint(
        '[Payment][Khalti] Payload: {cartId: $cartId, totalPayableAmount: ${totalPayableAmount.toStringAsFixed(2)}}',
      );
    }
    final form = FormData.fromMap({
      'cartId': cartId,
      'totalPayableAmount': totalPayableAmount,
    });
    try {
      final res = await _api.dio.post(
        ApiConstants.initiateKhaltiPaymentEndpoint,
        data: form,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {'accept': '*/*'},
        ),
      );
      if (kDebugMode) {
        debugPrint(
          '[Payment][Khalti] Status: ${res.statusCode?.toString() ?? 'null'}',
        );
        debugPrint('[Payment][Khalti] Response: ${res.data}');
      }
      return res;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[Payment][Khalti][ERROR] Type: ${e.type}');
        debugPrint('[Payment][Khalti][ERROR] Message: ${e.message ?? ''}');
        debugPrint(
          '[Payment][Khalti][ERROR] Status: ${e.response?.statusCode?.toString() ?? 'null'}',
        );
        debugPrint(
          '[Payment][Khalti][ERROR] Data: ${e.response?.data?.toString() ?? 'null'}',
        );
      }
      rethrow;
    }
  }

  Future<Response<dynamic>> khaltiResponse({
    required String pidx,
    required String status,
    String? transactionId,
    String? tidx,
    String? amount,
    String? totalAmount,
    String? mobile,
    String? purchaseOrderId,
    String? purchaseOrderName,
  }) async {
    final qp = <String, dynamic>{
      'pidx': pidx,
      'status': status,
      if (transactionId != null) 'transaction_id': transactionId,
      if (tidx != null) 'tidx': tidx,
      if (amount != null) 'amount': amount,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (mobile != null) 'mobile': mobile,
      if (purchaseOrderId != null) 'purchase_order_id': purchaseOrderId,
      if (purchaseOrderName != null) 'purchase_order_name': purchaseOrderName,
    };
    return _api.dio.get(
      ApiConstants.khaltiResponseEndpoint,
      queryParameters: qp,
      options: Options(headers: {'accept': '*/*'}),
    );
  }

  Future<Response<dynamic>> cashOnDelivery({
    required String cartId,
    required double totalPayableAmount,
  }) async {
    if (kDebugMode) {
      debugPrint('[Payment][COD] Initiating COD');
      debugPrint(
        '[Payment][COD] Endpoint: ${ApiConstants.cashOnDeliveryEndpoint}',
      );
      debugPrint(
        '[Payment][COD] Payload: {cartId: $cartId, totalPayableAmount: ${totalPayableAmount.toStringAsFixed(2)}}',
      );
    }
    final form = FormData.fromMap({
      'cartId': cartId,
      'totalPayableAmount': totalPayableAmount,
    });
    try {
      final res = await _api.dio.post(
        ApiConstants.cashOnDeliveryEndpoint,
        data: form,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {'accept': '*/*'},
        ),
      );
      if (kDebugMode) {
        debugPrint(
          '[Payment][COD] Status: ${res.statusCode?.toString() ?? 'null'}',
        );
        debugPrint('[Payment][COD] Response: ${res.data}');
      }
      return res;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[Payment][COD][ERROR] Type: ${e.type}');
        debugPrint('[Payment][COD][ERROR] Message: ${e.message ?? ''}');
        debugPrint(
          '[Payment][COD][ERROR] Status: ${e.response?.statusCode?.toString() ?? 'null'}',
        );
        debugPrint(
          '[Payment][COD][ERROR] Data: ${e.response?.data?.toString() ?? 'null'}',
        );
      }
      rethrow;
    }
  }
}
