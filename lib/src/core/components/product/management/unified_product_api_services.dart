import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:krishi_link/src/core/networking/api_service.dart';
import 'package:krishi_link/src/features/auth/data/token_service.dart';
import 'package:path/path.dart';
import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/features/admin/models/product_model.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:get/get.dart';

class UnifiedProductApiServices extends ApiService {
  final AuthController _authController = Get.find<AuthController>();

  UnifiedProductApiServices() : super(); // Initialize parent ApiService

  // Unified method for getting headers (JSON or form-data)
  Future<dio.Options> _getOptions({bool isFormData = false}) async {
    final headers = await TokenService.getAuthHeaders();
    return dio.Options(
      headers: {
        ...headers,
        'accept': isFormData ? '*/*' : 'application/json',
        'Content-Type': isFormData ? 'multipart/form-data' : 'application/json',
      },
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60), // Increased for reliability
    );
  }

  Future<List<Product>> fetchProducts({
    required String endpoint,
    String? searchQuery,
    List<String>? selectedCategories,
    List<String>? selectedLocations,
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      debugPrint(
        '🔄 [UnifiedProductApiServices] fetchProducts called with endpoint: $endpoint',
      );
      final opts = await _getOptions();
      final response = await dio.Dio().get(
        endpoint,
        queryParameters: {
          if (searchQuery != null) 'searchQuery': searchQuery,
          if (selectedCategories != null && selectedCategories.isNotEmpty)
            'categories': selectedCategories.join(','),
          if (selectedLocations != null && selectedLocations.isNotEmpty)
            'locations': selectedLocations.join(','),
          if (status != null && status != 'all') 'status': status,
          'page': page,
          'pageSize': pageSize,
        },
        options: opts,
      );

      debugPrint(
        '🔄 [UnifiedProductApiServices] Raw fetchProducts response: ${response.data}',
      );

      if (response.statusCode == 200) {
        dynamic data = response.data;
        if (data is Map) {
          data = data['data'] ?? data['products'] ?? data['items'] ?? data;
          if (data is List) {
            return data.map((e) => Product.fromJson(e)).toList();
          }
        } else if (data is List) {
          return data.map((e) => Product.fromJson(e)).toList();
        }
        return [];
      } else if (response.statusCode == 404) {
        return [];
      }
      throw Exception('Failed to fetch products: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [UnifiedProductApiServices] Error fetching products: $e');
      rethrow; // Let ApiService interceptors handle 401 errors
    }
  }

  Future<Product> addProduct({
    required String productName,
    required File image,
    required double rate,
    required double availableQuantity,
    required String category,
    required String emailOrPhone,
    String unit = 'kg',
    String description = '',
    required double latitude,
    required double longitude,
    dio.CancelToken? cancelToken,
  }) async {
    debugPrint(
      '🔄 [UnifiedProductApiServices] addProduct called with productName: $productName, email: $emailOrPhone',
    );
    try {
      final opts = await _getOptions(isFormData: true);
      debugPrint(
        '🔄 [UnifiedProductApiServices] Endpoint: ${ApiConstants.addProductEndpoint}',
      );
      debugPrint('🔄 [UnifiedProductApiServices] Headers: ${opts.headers}');

      final formData = dio.FormData.fromMap({
        'ProductName': productName.trim(),
        'Image': await dio.MultipartFile.fromFile(
          image.path,
          filename: basename(image.path),
          contentType: MediaType(
            'image',
            extension(image.path).replaceFirst('.', ''),
          ),
        ),
        'Rate': rate.toString(),
        'Unit': unit.trim(),
        'AvailableQuantity': availableQuantity.toString(),
        'Category': category.trim(),
        'Latitude': latitude.toString(),
        'Longitude': longitude.toString(),
        'Description': description.trim(),
      });

      debugPrint(
        '🔄 [UnifiedProductApiServices] FormData fields: ${formData.fields}',
      );
      debugPrint('🔄 [UnifiedProductApiServices] FormData file: ${image.path}');

      final response = await dio.Dio().post(
        ApiConstants.addProductEndpoint,
        data: formData,
        queryParameters: {'EmailorPhone': emailOrPhone},
        options: opts,
        cancelToken: cancelToken,
      );

      debugPrint(
        '🔄 [UnifiedProductApiServices] Response status: ${response.statusCode}',
      );
      debugPrint(
        '🔄 [UnifiedProductApiServices] Response data: ${response.data}',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        debugPrint('✅ [UnifiedProductApiServices] Product added successfully');
        return Product(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          productName: productName,
          rate: rate,
          availableQuantity: availableQuantity,
          category: category,
          unit: unit,
          description: description.isNotEmpty ? description : 'No description',
          latitude: latitude,
          longitude: longitude,
          image:
              '${ApiConstants.getProductImageEndpoint}/${basename(image.path)}',
          soldedQuantity: 0.0,
          farmerId: _authController.currentUser.value?.id ?? '',
          farmerName: _authController.currentUser.value?.fullName ?? '',
          farmerPhone: emailOrPhone,
          isActive: true,
          createdAt: DateTime.now(),
        );
      }

      throw Exception(
        'Failed to add product: ${response.data['message'] ?? 'Unknown error'}',
      );
    } catch (e) {
      debugPrint('❌ [UnifiedProductApiServices] Error adding product: $e');
      if (e is dio.DioException) {
        debugPrint('❌ [UnifiedProductApiServices] Dio error type: ${e.type}');
        debugPrint(
          '❌ [UnifiedProductApiServices] Dio error message: ${e.message}',
        );
        debugPrint(
          '❌ [UnifiedProductApiServices] Dio error response: ${e.response?.data}',
        );
      }
      rethrow; // Let ApiService interceptors handle 401 errors
    }
  }

  Future<Product> updateProduct(
    String productId,
    Product product, {
    File? imageFile,
    dio.CancelToken? cancelToken,
  }) async {
    try {
      debugPrint(
        '🔄 [UnifiedProductApiServices] updateProduct called for ID: $productId',
      );
      final opts = await _getOptions(isFormData: true);

      if (product.productName.isEmpty) {
        throw Exception('Product name is required');
      }
      if (product.rate <= 0) {
        throw Exception('Product rate must be greater than 0');
      }
      if (product.availableQuantity <= 0) {
        throw Exception('Available quantity must be greater than 0');
      }
      if (product.category.isEmpty) {
        throw Exception('Product category is required');
      }

      final formData = dio.FormData.fromMap({
        'ProductName': product.productName.trim(),
        'Rate': product.rate.toString(),
        'AvailableQuantity': product.availableQuantity.toString(),
        'Category': product.category.trim(),
        'Unit': product.unit.trim(),
        'Description': product.description.trim(),
        'Latitude': product.latitude.toString(),
        'Longitude': product.longitude.toString(),
        if (imageFile != null)
          'Image': await dio.MultipartFile.fromFile(
            imageFile.path,
            filename: basename(imageFile.path),
            contentType: MediaType(
              'image',
              extension(imageFile.path).replaceFirst('.', ''),
            ),
          ),
      });

      debugPrint(
        '🔄 [UnifiedProductApiServices] Form data prepared: ${formData.fields}',
      );
      if (imageFile != null) {
        debugPrint('🔄 [UnifiedProductApiServices] Image: ${imageFile.path}');
      }

      final response = await dio.Dio().put(
        '${ApiConstants.updateProductEndpoint}/$productId',
        data: formData,
        queryParameters: {'EmailorPhone': product.farmerPhone},
        options: opts,
        cancelToken: cancelToken,
      );

      debugPrint(
        '🔄 [UnifiedProductApiServices] Response status: ${response.statusCode}',
      );
      debugPrint(
        '🔄 [UnifiedProductApiServices] Response data: ${response.data}',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        debugPrint(
          '✅ [UnifiedProductApiServices] Product updated successfully',
        );
        return product.copyWith(
          image:
              imageFile != null
                  ? '${ApiConstants.getProductImageEndpoint}/${basename(imageFile.path)}'
                  : response.data['data']?['image'] ?? product.image,
        );
      }
      throw Exception(response.data['message'] ?? 'Failed to update product');
    } catch (e) {
      debugPrint('❌ [UnifiedProductApiServices] Update product error: $e');
      if (e is dio.DioException) {
        debugPrint('❌ [UnifiedProductApiServices] Dio error type: ${e.type}');
        debugPrint(
          '❌ [UnifiedProductApiServices] Dio error message: ${e.message}',
        );
        debugPrint(
          '❌ [UnifiedProductApiServices] Dio error response: ${e.response?.data}',
        );
      }
      rethrow; // Let ApiService interceptors handle 401 errors
    }
  }

  Future<void> deleteProduct(
    String productId, {
    dio.CancelToken? cancelToken,
  }) async {
    try {
      debugPrint(
        '🔄 [UnifiedProductApiServices] deleteProduct called for ID: $productId',
      );
      debugPrint(
        '🔄 [UnifiedProductApiServices] Delete endpoint: ${ApiConstants.deleteProductEndpoint}/$productId',
      );
      final opts = await _getOptions();
      debugPrint('🔄 [UnifiedProductApiServices] Headers: ${opts.headers}');
      final response = await dio.Dio().delete(
        '${ApiConstants.deleteProductEndpoint}/$productId',
        options: opts,
        cancelToken: cancelToken,
      );

      debugPrint(
        '🔄 [UnifiedProductApiServices] Delete API response status: ${response.statusCode}',
      );
      debugPrint(
        '🔄 [UnifiedProductApiServices] Delete API response data: ${response.data}',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        debugPrint(
          '✅ [UnifiedProductApiServices] Product deleted successfully',
        );
      } else {
        throw Exception(
          'Failed to delete product: ${response.data['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      debugPrint('❌ [UnifiedProductApiServices] Delete product error: $e');
      if (e is dio.DioException) {
        debugPrint('❌ [UnifiedProductApiServices] Dio error type: ${e.type}');
        debugPrint(
          '❌ [UnifiedProductApiServices] Dio error message: ${e.message}',
        );
        debugPrint(
          '❌ [UnifiedProductApiServices] Dio error response: ${e.response?.data}',
        );
      }
      rethrow; // Let ApiService interceptors handle 401 errors
    }
  }

  Future<void> updateProductActiveStatus(
    String productId,
    bool isActive,
  ) async {
    try {
      debugPrint(
        '🔄 [UnifiedProductApiServices] updateProductActiveStatus called for ID: $productId, isActive: $isActive',
      );
      final opts = await _getOptions();
      final response = await dio.Dio().put(
        '${ApiConstants.updateProductStatusEndpoint}/$productId',
        data: {'isActive': isActive},
        options: opts,
      );

      debugPrint(
        '🔄 [UnifiedProductApiServices] API response status: ${response.statusCode}',
      );
      debugPrint(
        '🔄 [UnifiedProductApiServices] API response data: ${response.data}',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        debugPrint(
          '✅ [UnifiedProductApiServices] Product status updated successfully',
        );
      } else {
        throw Exception(
          'Failed to update product status: ${response.data['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      debugPrint(
        '❌ [UnifiedProductApiServices] updateProductActiveStatus error: $e',
      );
      if (e is dio.DioException) {
        debugPrint('❌ [UnifiedProductApiServices] Dio error type: ${e.type}');
        debugPrint(
          '❌ [UnifiedProductApiServices] Dio error message: ${e.message}',
        );
        debugPrint(
          '❌ [UnifiedProductApiServices] Dio error response: ${e.response?.data}',
        );
      }
      rethrow; // Let ApiService interceptors handle 401 errors
    }
  }

  bool isEmail(String input) => RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(input);

  Future<Map<String, dynamic>?> fetchUserDetailsByEmailOrPhone(
    String input,
  ) async {
    try {
      debugPrint(
        '🔄 [UnifiedProductApiServices] fetchUserDetailsByEmailOrPhone called with input: $input',
      );
      final opts = await _getOptions();
      dio.Response response;
      if (isEmail(input)) {
        debugPrint(
          '🔄 [UnifiedProductApiServices] Fetching user details by email: $input',
        );
        response = await dio.Dio().get(
          '${ApiConstants.getUserDetailsByEmailEndpoint}?email=$input',
          options: opts,
        );
      } else {
        debugPrint(
          '🔄 [UnifiedProductApiServices] Fetching user details by phone: $input',
        );
        response = await dio.Dio().get(
          '${ApiConstants.getUserDetailsByPhoneNumberEndpoint}/$input',
          options: opts,
        );
      }
      debugPrint(
        '🔄 [UnifiedProductApiServices] API response status: ${response.statusCode}',
      );
      debugPrint(
        '🔄 [UnifiedProductApiServices] API response data: ${response.data}',
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data'];
      }
      debugPrint(
        '❌ [UnifiedProductApiServices] No user data found or invalid response',
      );
      return null;
    } catch (e) {
      debugPrint(
        '❌ [UnifiedProductApiServices] Error fetching user details: $e',
      );
      rethrow; // Let ApiService interceptors handle 401 errors
    }
  }
}
