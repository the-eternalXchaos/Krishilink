import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:krishi_link/services/api_service.dart';
import 'package:path/path.dart';
import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/services/token_service.dart';
import 'package:krishi_link/features/admin/models/product_model.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:get/get.dart';

// EXTENDING TO USE THE TOKEN REFRESH LOGIC IN ApiService AND ALSO THE INTERCEPTORS
class UnifiedProductApiServices extends ApiService {
  // final dio.Dio _dio = dio.Dio(
  //   dio.BaseOptions(
  //     baseUrl: ApiConstants.baseUrl,
  //     connectTimeout: const Duration(seconds: 10),
  //     receiveTimeout: const Duration(seconds: 20),
  //   ),
  // );

  Future<dio.Options> _getOptions({bool isFormData = false}) async {
    if (isFormData) {
      return dio.Options(
        headers: {'accept': '*/*', 'Content-Type': 'multipart/form-data'},
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 20),
      );
    }
    return dio.Options(
      headers: {
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
    );
  }

  final AuthController _authController = Get.find<AuthController>();
  UnifiedProductApiServices(this._authController);

  // Future<dio.Options> _jsonOptions() async {
  //   final token = authController.currentUser.value?.token;
  //   if (token == null || token.isEmpty) {
  //     throw Exception('No authentication token found');
  //   }
  //   return dio.Options(
  //     headers: {
  //       'Authorization': 'Bearer $token',
  //       'Content-Type': 'application/json',
  //       'accept': 'application/json',
  //     },
  //   );
  // }

  Future<dio.Options> _formOptions() async {
    final token = await TokenService.getAccessToken();
    return dio.Options(
      headers: {
        'Authorization': 'Bearer $token',
        'accept': '*/*',
        'Content-Type': 'multipart/form-data',
      },
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 20),
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
      final opts = await _getOptions();
      final response = await _dio.get(
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
      throw Exception('Failed to fetch products: $e');
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
      '🔄 [API] addProduct called with productName: $productName, email: $emailOrPhone',
    );
    try {
      final opts = await _formOptions();
      debugPrint('🔄 [API] Endpoint: ${ApiConstants.addProductEndpoint}');
      debugPrint('🔄 [API] Headers: ${opts.headers}');

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

      debugPrint('🔄 [API] FormData fields: ${formData.fields}');
      debugPrint('🔄 [API] FormData file: ${image.path}');

      final response = await _dio.post(
        ApiConstants.addProductEndpoint,
        data: formData,
        queryParameters: {'EmailorPhone': emailOrPhone},
        options: opts,
        cancelToken: cancelToken,
      );

      debugPrint('🔄 [API] Response status: ${response.statusCode}');
      debugPrint('🔄 [API] Response data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        debugPrint('✅ [API] Product added successfully');
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
      debugPrint('❌ [API] Error adding product: $e');
      if (e is dio.DioException) {
        debugPrint('❌ [API] Dio error type: ${e.type}');
        debugPrint('❌ [API] Dio error message: ${e.message}');
        debugPrint('❌ [API] Dio error response: ${e.response?.data}');
      }
      throw Exception('Failed to add product: $e');
    }
  }
  // Future<Product> addProduct({
  //   required String productName,
  //   required File image,
  //   required double rate,
  //   required double availableQuantity,
  //   required String category,
  //   required String emailOrPhone,
  //   String unit = 'kg',
  //   String description = '',
  //   required double latitude,
  //   required double longitude,
  //   dio.CancelToken? cancelToken,
  // }) async {
  //   try {
  //     debugPrint('✅ API call initiated');

  //     debugPrint('🔄 [API] addProduct called');
  //     final opts = await _formOptions();
  //     debugPrint('🔄 [API] Endpoint: ${ApiConstants.addProductEndpoint}');
  //     debugPrint('🔄 [API] EmailOrPhone: $emailOrPhone');

  //     final formData = dio.FormData.fromMap({
  //       'ProductName': productName.trim(),
  //       'Image': await dio.MultipartFile.fromFile(
  //         image.path,
  //         filename: basename(image.path),
  //         contentType: MediaType(
  //           'image',
  //           extension(image.path).replaceFirst('.', ''),
  //         ),
  //       ),
  //       'Rate': rate.toString(),
  //       'Unit': unit.trim(),
  //       'AvailableQuantity': availableQuantity.toString(),
  //       'Category': category.trim(),
  //       'Latitude': latitude.toString(),
  //       'Longitude': longitude.toString(),
  //       'Description': description.trim(),
  //     });

  //     debugPrint('🔄 [API] FormData fields: ${formData.fields}');
  //     debugPrint('🔄 [API] FormData file: ${image.path}');

  //     final response = await _dio.post(
  //       ApiConstants.addProductEndpoint,
  //       data: formData,
  //       queryParameters: {'EmailorPhone': emailOrPhone},
  //       options: opts,
  //       cancelToken: cancelToken,
  //     );

  //     debugPrint('🔄 [API] Status: ${response.statusCode}');
  //     debugPrint('🔄 [API] Response: ${response.data}');

  //     if (response.statusCode == 200 && response.data['success'] == true) {
  //       debugPrint('✅ [API] Product added successfully');

  //       // Build a local Product object (since API returns only a message)
  //       return Product(
  //         id: DateTime.now().millisecondsSinceEpoch.toString(),
  //         productName: productName,
  //         rate: rate,
  //         availableQuantity: availableQuantity,
  //         category: category,
  //         unit: unit,
  //         description: description.isNotEmpty ? description : 'No description',
  //         latitude: latitude,
  //         longitude: longitude,
  //         image:
  //             '${ApiConstants.getProductImageEndpoint}/${basename(image.path)}',
  //         soldedQuantity: 0.0,
  //         farmerId: authController.currentUser.value?.id ?? '',
  //         farmerName: authController.currentUser.value?.fullName ?? '',
  //         farmerPhone: emailOrPhone,
  //         isActive: true,
  //         createdAt: DateTime.now(),
  //       );
  //     }

  //     throw Exception(
  //       'Failed to add product: ${response.data['message'] ?? 'Unknown error'}',
  //     );
  //   } catch (e) {
  //     debugPrint('❌ [API] Error: $e');
  //     if (e is dio.DioException) {
  //       debugPrint('❌ Dio Error: ${e.message}, Response: ${e.response?.data}');
  //       throw Exception('Network/Server error: ${e.message}');
  //     }
  //     throw Exception('Failed to add product: $e');
  //   }
  // }

  // Future<Product> updateProduct(
  //   String productId,
  //   Product product, {
  //   File? imageFile,
  //   dio.CancelToken? cancelToken,
  // }) async {
  //   try {
  //     debugPrint(
  //       '🔄 [UnifiedProductApiServices] updateProduct called for product: $productId',
  //     );
  //     debugPrint(
  //       '🔄 [UnifiedProductApiServices] API endpoint: ${ApiConstants.updateProductEndpoint}/$productId',
  //     );

  //     if (product.productName.isEmpty) {
  //       throw Exception('Product name is required');
  //     }
  //     if (product.rate <= 0) {
  //       throw Exception('Product rate must be greater than 0');
  //     }
  //     if (product.availableQuantity <= 0) {
  //       throw Exception('Available quantity must be greater than 0');
  //     }
  //     if (product.category.isEmpty) {
  //       throw Exception('Product category is required');
  //     }

  //     final opts = await _formOptions();
  //     final formData = dio.FormData.fromMap({
  //       'ProductName': product.productName.trim(),
  //       'Rate': product.rate.toString(),
  //       'AvailableQuantity': product.availableQuantity.toString(),
  //       'Category': product.category.trim(),
  //       'Unit': product.unit.trim(),
  //       'Description': (product.description).trim(),
  //       'Latitude': product.latitude.toString(),
  //       'Longitude': product.longitude.toString(),
  //       if (imageFile != null)
  //         'Image': await dio.MultipartFile.fromFile(
  //           imageFile.path,
  //           filename: basename(imageFile.path),
  //           contentType: MediaType(
  //             'image',
  //             extension(imageFile.path).replaceFirst('.', ''),
  //           ),
  //         ),
  //     });

  //     debugPrint(
  //       '🔄 [UnifiedProductApiServices] Image handling: ${imageFile != null ? 'New image provided' : 'Keeping existing image'}',
  //     );
  //     debugPrint('🔄 [UnifiedProductApiServices] Form data prepared:');
  //     for (final field in formData.fields) {
  //       debugPrint('  - ${field.key}: ${field.value}');
  //     }

  //     final response = await _dio.put(
  //       '${ApiConstants.updateProductEndpoint}/$productId',
  //       data: formData,
  //       queryParameters: {'EmailorPhone': product.farmerPhone},
  //       options: opts,
  //       cancelToken: cancelToken,
  //     );

  //     debugPrint(
  //       '🔄 [UnifiedProductApiServices] API response status: ${response.statusCode}',
  //     );
  //     debugPrint(
  //       '🔄 [UnifiedProductApiServices] API response data: ${response.data}',
  //     );

  //     if (response.statusCode == 200) {
  //       final responseData = response.data;
  //       if (responseData['success'] == true) {
  //         debugPrint('✅ [UnifiedProductApiServices] API call successful');
  //         return product.copyWith(
  //           image:
  //               imageFile != null
  //                   ? '${ApiConstants.getProductImageEndpoint}/$productId?t=${DateTime.now().millisecondsSinceEpoch}'
  //                   : product.image,
  //         );
  //       }
  //       throw Exception(
  //         'Failed to update product: ${responseData['message'] ?? 'Unknown error'}',
  //       );
  //     }
  //     throw Exception(
  //       'Failed to update product: ${response.statusCode} - ${response.data['message'] ?? response.data['title'] ?? 'Unknown error'}',
  //     );
  //   } catch (e) {
  //     debugPrint('❌ [UnifiedProductApiServices] updateProduct error: $e');
  //     if (e is dio.DioException) {
  //       debugPrint('❌ [UnifiedProductApiServices] Dio error type: ${e.type}');
  //       debugPrint(
  //         '❌ [UnifiedProductApiServices] Dio error message: ${e.message}',
  //       );
  //       debugPrint(
  //         '❌ [UnifiedProductApiServices] Dio error response: ${e.response?.data}',
  //       );
  //       debugPrint(
  //         '❌ [UnifiedProductApiServices] Dio error status code: ${e.response?.statusCode}',
  //       );
  //       debugPrint(
  //         '❌ [UnifiedProductApiServices] Dio error headers: ${e.response?.headers}',
  //       );
  //       switch (e.type) {
  //         case dio.DioExceptionType.connectionTimeout:
  //           throw Exception(
  //             'Connection timeout. Please check your internet connection.',
  //           );
  //         case dio.DioExceptionType.sendTimeout:
  //           throw Exception('Request timeout. Please try again.');
  //         case dio.DioExceptionType.receiveTimeout:
  //           throw Exception('Response timeout. Please try again.');
  //         case dio.DioExceptionType.badResponse:
  //           throw Exception('Server error: ${e.response?.statusCode}');
  //         case dio.DioExceptionType.cancel:
  //           throw Exception('Request was cancelled.');
  //         case dio.DioExceptionType.connectionError:
  //           throw Exception(
  //             'No internet connection. Please check your network.',
  //           );
  //         default:
  //           throw Exception('Network error: ${e.message}');
  //       }
  //     }
  //     throw Exception('Failed to update product: $e');
  //   }
  // }

  Future<Product> updateProduct(
    String productId,
    Product product, {
    File? imageFile,
    dio.CancelToken? cancelToken,
  }) async {
    try {
      debugPrint('🔄 [API] updateProduct called for ID: $productId');
      final opts = await _formOptions();

      final formData = dio.FormData.fromMap({
        'ProductName': product.productName,
        'Rate': product.rate.toString(),
        'AvailableQuantity': product.availableQuantity.toString(),
        'Category': product.category,
        'Unit': product.unit,
        'Description': product.description,
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

      final response = await _dio.put(
        '${ApiConstants.updateProductEndpoint}/$productId',
        data: formData,
        queryParameters: {'EmailorPhone': product.farmerPhone},
        options: opts,
        cancelToken: cancelToken,
      );

      debugPrint('🔄 [API] Response status: ${response.statusCode}');
      debugPrint('🔄 [API] Response data: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data['success'] == true) {
          debugPrint('✅ [API] Product updated successfully');
          return product.copyWith(
            image:
                imageFile != null
                    ? '${ApiConstants.getProductImageEndpoint}/${basename(imageFile.path)}'
                    : product.image,
          );
        }
        throw Exception(response.data['message'] ?? 'Failed to update product');
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [API] Update product error: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(
    String productId, {
    dio.CancelToken? cancelToken,
  }) async {
    try {
      debugPrint('🔄 [UnifiedProductApiServices] deleteProduct called');
      debugPrint('🔄 [UnifiedProductApiServices] Product ID: $productId');
      debugPrint(
        '🔄 [UnifiedProductApiServices] API endpoint: ${ApiConstants.deleteProductEndpoint}/$productId',
      );

      final opts = await _jsonOptions();
      final response = await _dio.delete(
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

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] != true) {
          throw Exception(
            'Failed to delete product: ${responseData['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('Failed to delete product: ${response.statusCode}');
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
        debugPrint(
          '❌ [UnifiedProductApiServices] Dio error status code: ${e.response?.statusCode}',
        );
        debugPrint(
          '❌ [UnifiedProductApiServices] Dio error headers: ${e.response?.headers}',
        );
        if (e.response?.data != null && e.response!.data is Map) {
          final errorData = e.response!.data as Map;
          throw Exception(
            'Failed to delete product: ${errorData['message'] ?? e.message ?? 'Network error'}',
          );
        }
        throw Exception(
          'Failed to delete product: ${e.message ?? 'Network error'}',
        );
      }
      throw Exception('Failed to delete product: $e');
    }
  }

  Future<void> updateProductActiveStatus(
    String productId,
    bool isActive,
  ) async {
    try {
      debugPrint(
        '🔄 [UnifiedProductApiServices] updateProductActiveStatus called',
      );
      debugPrint(
        '🔄 [UnifiedProductApiServices] Product ID: $productId, isActive: $isActive',
      );
      debugPrint(
        '🔄 [UnifiedProductApiServices] API endpoint: ${ApiConstants.updateProductStatusEndpoint}/$productId',
      );

      final opts = await _jsonOptions();
      final response = await _dio.put(
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

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to update product status: ${response.statusCode}',
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
        throw Exception(
          'Failed to update product status: ${e.response?.data['message'] ?? 'Network error'}',
        );
      }
      throw Exception('Failed to update product status: $e');
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
      final opts = await _jsonOptions();
      dio.Response response;
      if (isEmail(input)) {
        debugPrint(
          '🔄 [UnifiedProductApiServices] Fetching user details by email: $input',
        );
        response = await _dio.get(
          '${ApiConstants.getUserDetailsByEmail}?email=$input',
          options: opts,
        );
      } else {
        debugPrint(
          '🔄 [UnifiedProductApiServices] Fetching user details by phone: $input',
        );
        response = await _dio.get(
          '${ApiConstants.getUserDetailsByPhoneNumber}/$input',
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
      throw Exception('Failed to fetch user details: $e');
    }
  }
}
