import 'package:dio/dio.dart';
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
    _api = api ?? (Get.isRegistered<ApiService>() ? Get.find<ApiService>() : ApiService());
  }

  Future<Response<dynamic>> initiateEsewa({
    required String cartId,
    required double totalPayableAmount,
  }) async {
    final form = FormData.fromMap({
      'cartId': cartId,
      'totalPayableAmount': totalPayableAmount,
    });
    return _api.dio.post(
      ApiConstants.initiateEsewaPaymentEndpoint,
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
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
    final form = FormData.fromMap({
      'cartId': cartId,
      'totalPayableAmount': totalPayableAmount,
    });
    return _api.dio.post(
      ApiConstants.initiateKhaltiPaymentEndpoint,
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
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
    final form = FormData.fromMap({
      'cartId': cartId,
      'totalPayableAmount': totalPayableAmount,
    });
    return _api.dio.post(
      ApiConstants.cashOnDeliveryEndpoint,
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
  }
}
