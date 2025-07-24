import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:krishi_link/core/constants/api_constants.dart';
import 'package:krishi_link/features/admin/models/notification_model.dart';
import 'package:krishi_link/features/admin/models/order_model.dart';
import 'package:krishi_link/features/admin/models/product_model.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/farmer/models/crop_model.dart';
import 'package:krishi_link/features/farmer/models/tutorial_model.dart';
import 'package:krishi_link/features/farmer/models/weather_model.dart';
import 'package:path/path.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;

class FarmerApiServices {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<String?> _token() async {
    final authController = Get.find<AuthController>();
    return authController.currentUser.value?.token;
  }

  Future<Options> _formOptions() async {
    final token = await _token();
    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'multipart/form-data',
        'accept': 'text/plain',
      },
    );
  }

  Future<Options> _jsonOptions() async {
    final token = await _token();
    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
    );
  }

  Future<Weather> fetchWeather(String location) async {
    try {
      final response = await _dio.get(
        ApiConstants.getWeatherEndpoint,
        queryParameters: {
          'q': location,
          'appid': ApiConstants.weatherApiKey,
          'units': 'metric', // For Celsius
        },
      );
      if (response.statusCode == 200) {
        return Weather.fromJson(response.data);
      }
      throw Exception('Failed to fetch weather: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching weather: $e');
      }
      if (e is DioException) {
        print('Dio error details: ${e.response?.data}');
        throw Exception(
          'Failed to fetch weather: ${e.response?.data['message'] ?? e.message ?? 'Network error'}',
        );
      }
      rethrow;
    }
  }

  // Future<Product> addProduct({
  //   required String productName,
  //   required File image,
  //   required String rate,
  //   required String availableQuantity,
  //   required String category,
  //   required String emailOrPhone,
  //   String? description,
  //   String unit = 'kg',
  //   double latitude = 0,
  //   double longitude = 0,
  // }) async {
  //   try {
  //     final opts = await _formOptions();
  //     final formData = FormData.fromMap({
  //       'ProductName': productName,
  //       'Rate': rate,
  //       'AvailableQuantity': availableQuantity,
  //       'Category': category,
  //       'Unit': unit,
  //       'Description': description ?? '',
  //       'Latitude': latitude,
  //       'Longitude': longitude,
  //       'Image': await MultipartFile.fromFile(
  //         image.path,
  //         filename: basename(image.path),
  //         contentType: MediaType(
  //           'image',
  //           extension(image.path).replaceFirst('.', ''),
  //         ),
  //       ),
  //     });
  //     print('Sending addProduct request:');
  //     print('FormData fields:  [200m${formData.fields} [0m');
  //     print('Image: ${formData.files}');
  //     print('Query: EmailorPhone=$emailOrPhone');
  //     final response = await _dio.post(
  //       ApiConstants.addProductEndpoint,
  //       data: formData,
  //       queryParameters: {'EmailorPhone': emailOrPhone},
  //       options: opts,
  //     );
  //     if (response.statusCode == 200) {
  //       final responseData = response.data;
  //       if (responseData['success'] == true) {
  //         return Product.fromJson(responseData['data']);
  //       }
  //       throw Exception(
  //         'Failed to add product: ${responseData['message'] ?? 'Unknown error'}',
  //       );
  //     }
  //     throw Exception(
  //       'Failed to add product: ${response.statusCode} - ${response.data['message'] ?? response.data['title'] ?? 'Unknown error'}',
  //     );
  //   } catch (e) {
  //     print('Error adding product: $e');
  //     if (e is DioException) {
  //       print('Dio error details: ${e.response?.data}');
  //       throw Exception(
  //         'Failed to add product: ${e.response?.data['message'] ?? e.message ?? 'Network error'}',
  //       );
  //     }
  //     rethrow;
  //   }
  // }

  // Future<Product> updateProduct(
  //   String productId,
  //   Product product, {
  //   File? imageFile,
  // }) async {
  //   try {
  //     final opts = await _formOptions();
  //     // Increase timeout for this request
  //     final customOpts = opts.copyWith(
  //       receiveTimeout: const Duration(seconds: 30),
  //     );
  //     final formData = FormData.fromMap({
  //       'ProductName': product.productName,
  //       'Rate': product.rate.toString(),
  //       'AvailableQuantity': product.availableQuantity.toString(),
  //       'Category': product.category,
  //       // 'Location': product.location, // Do NOT send location string
  //       'Unit': product.unit,
  //       'Description': product.description,
  //       'Latitude': product.latitude,
  //       'Longitude': product.longitude,
  //       if (imageFile != null)
  //         'Image': await MultipartFile.fromFile(
  //           imageFile.path,
  //           filename: basename(imageFile.path),
  //           contentType: MediaType(
  //             'image',
  //             extension(imageFile.path).replaceFirst('.', ''),
  //           ),
  //         ),
  //     });

  //     print('Sending updateProduct request:');
  //     print('FormData fields: ${formData.fields}');
  //     print('Image: ${formData.files}');

  //     final response = await _dio.put(
  //       '${ApiConstants.updateProductEndpoint}/$productId',
  //       data: formData,
  //       options: customOpts,
  //     );

  //     if (response.statusCode == 200) {
  //       final responseData = response.data;
  //       if (responseData['success'] == true) {
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
  //     print('Error updating product: $e');
  //     if (e is DioException) {
  //       print('Dio error details: ${e.response?.data}');
  //       throw Exception(
  //         'Failed to update product: ${e.response?.data['message'] ?? e.message ?? 'Network error'}',
  //       );
  //     }
  //     rethrow;
  //   }
  // }

  // Future<void> deleteProduct(String productId) async {
  //   try {
  //     final opts = await _jsonOptions();
  //     final response = await _dio.delete(
  //       '${ApiConstants.deleteProductEndpoint}/$productId',
  //       options: opts,
  //     );
  //     if (response.statusCode != 200) {
  //       throw Exception('Failed to delete product: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     print('Error deleting product: $e');
  //     if (e is DioException) {
  //       print('Dio error details: ${e.response?.data}');
  //       throw Exception(
  //         'Failed to delete product: ${e.response?.data['message'] ?? e.message ?? 'Network error'}',
  //       );
  //     }
  //     rethrow;
  //   }
  // }

  // Future<void> updateProductActiveStatus(
  //   String productId,
  //   bool isActive,
  // ) async {
  //   try {
  //     final opts = await _jsonOptions();
  //     print('Updating product $productId to isActive: $isActive');
  //     final response = await _dio.put(
  //       '${ApiConstants.updateProductStatusEndpoint}/$productId',
  //       data: {'isActive': isActive},
  //       options: opts,
  //     );
  //     if (response.statusCode != 200) {
  //       throw Exception(
  //         'Failed to update product status: ${response.statusCode}',
  //       );
  //     }
  //   } catch (e) {
  //     print('Error updating product status: $e');
  //     if (e is DioException) {
  //       print('Dio error details: ${e.response?.data}');
  //       throw Exception(
  //         'Failed to update product status: ${e.response?.data['message'] ?? e.message ?? 'Network error'}',
  //       );
  //     }
  //     rethrow;
  //   }
  // }

  // Future<List<Product>> fetchProducts({
  //   String? searchQuery,
  //   List<String>? selectedCategories,
  //   List<String>? selectedLocations,
  //   int page = 1,
  //   int pageSize = 15,

  //   ///TODO: change to 20 it is for loading more products
  // }) async {
  //   try {
  //     final opts = await _jsonOptions();
  //     debugPrint('Fetching products with headers:  [200m${opts.headers} [0m');
  //     final response = await _dio.get(
  //       ApiConstants.getMyProductsEndpoint,
  //       queryParameters: {
  //         if (searchQuery != null) 'searchQuery': searchQuery,
  //         if (selectedCategories != null && selectedCategories.isNotEmpty)
  //           'categories': selectedCategories.join(','),
  //         if (selectedLocations != null && selectedLocations.isNotEmpty)
  //           'locations': selectedLocations.join(','),
  //         'page': page,
  //         'pageSize': pageSize,
  //       },
  //       options: opts,
  //     );
  //     print('Response status: ${response.statusCode}, data: ${response.data}');
  //     if (response.statusCode == 200) {
  //       final data = response.data['data'] ?? response.data;
  //       if (data is List) {
  //         return data.map((e) => Product.fromJson(e)).toList();
  //       }
  //       return [];
  //     } else if (response.statusCode == 404) {
  //       return [];
  //     }
  //     throw Exception('Failed to fetch products: ${response.statusCode}');
  //   } catch (e) {
  //     print('Error fetching products: $e');
  //     if (e is DioException) {
  //       print('Dio error details: ${e.response?.data}');
  //       throw Exception(
  //         'Failed to fetch products: ${e.response?.data['message'] ?? e.message ?? 'Network error'}',
  //       );
  //     }
  //     rethrow;
  //   }
  // }

  Future<List<TutorialModel>> fetchTutorials() async {
    try {
      final opts = await _jsonOptions();
      final response = await _dio.get(
        ApiConstants.getTutorialsEndpoint,
        options: opts,
      );
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        if (data is List) {
          return data.map((e) => TutorialModel.fromJson(e)).toList();
        }
        return [];
      }
      throw Exception('Failed to fetch tutorials: ${response.statusCode}');
    } catch (e) {
      print('Error fetching tutorials: $e');
      if (e is DioException) {
        print('Dio error details: ${e.response?.data}');
        throw Exception(
          'Failed to fetch tutorials: ${e.response?.data['message'] ?? e.message ?? 'Network error'}',
        );
      }
      rethrow;
    }
  }

  Future<List<CropModel>> fetchCrops() async {
    try {
      final opts = await _jsonOptions();
      final response = await _dio.get(
        ApiConstants.getCropsEndpoint,
        options: opts,
      );
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        if (data is List) {
          return data.map((e) => CropModel.fromJson(e)).toList();
        }
        return [];
      }
      throw Exception('Failed to fetch crops: ${response.statusCode}');
    } catch (e) {
      print('Error fetching crops: $e');
      if (e is DioException) {
        print('Dio error details: ${e.response?.data}');
        throw Exception(
          'Failed to fetch crops: ${e.response?.data['message'] ?? e.message ?? 'Network error'}',
        );
      }
      rethrow;
    }
  }

  Future<CropModel> addCrop({
    required String cropName,
    required String area,
    required String plantingDate,
    required String location,
    required String emailOrPhone,
    String? description,
  }) async {
    try {
      final opts = await _formOptions();
      final formData = FormData.fromMap({
        'CropName': cropName,
        'Area': area,
        'PlantingDate': plantingDate,
        'Location': location,
        'EmailorPhone': emailOrPhone,
        'Description': description ?? '',
      });

      final response = await _dio.post(
        ApiConstants.addCropEndpoint,
        data: formData,
        options: opts,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          final cropId =
              responseData['data']?.toString() ??
              DateTime.now().millisecondsSinceEpoch.toString();
          return CropModel(
            id: cropId,
            name: cropName,
            plantedAt:
                plantingDate.isNotEmpty
                    ? DateTime.parse(plantingDate)
                    : DateTime.now(),
            // note: note,
            description: description ?? 'No description',
            // Add other required fields based on CropModel
          );
        }
        throw Exception(
          'Failed to add crop: ${responseData['message'] ?? 'Unknown error'}',
        );
      }
      throw Exception('Failed to add crop: ${response.statusCode}');
    } catch (e) {
      print('Error adding crop: $e');
      if (e is DioException) {
        print('Dio error details: ${e.response?.data}');
        throw Exception(
          'Failed to add crop: ${e.response?.data['message'] ?? e.message ?? 'Network error'}',
        );
      }
      rethrow;
    }
  }

  Future<CropModel> updateCrop(String cropId, CropModel crop) async {
    try {
      final opts = await _formOptions();
      final formData = FormData.fromMap({
        'CropName': crop.name,
        // 'Area': crop.area,
        'PlantingDate': crop.plantedAt?.toIso8601String(),
        // 'Location': crop.location,
        'Description': crop.description ?? 'No description added',
      });

      final response = await _dio.put(
        '${ApiConstants.updateCropEndpoint}/$cropId',
        data: formData,
        options: opts,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          return crop;
        }
        throw Exception(
          'Failed to update crop: ${responseData['message'] ?? 'Unknown error'}',
        );
      }
      throw Exception('Failed to update crop: ${response.statusCode}');
    } catch (e) {
      print('Error updating crop: $e');
      if (e is DioException) {
        print('Dio error details: ${e.response?.data}');
        throw Exception(
          'Failed to update crop: ${e.response?.data['message'] ?? e.message ?? 'Network error'}',
        );
      }
      rethrow;
    }
  }

  Future<void> deleteCrop(String cropId) async {
    try {
      final opts = await _jsonOptions();
      final response = await _dio.delete(
        '${ApiConstants.deleteCropEndpoint}/$cropId',
        options: opts,
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to delete crop: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting crop: $e');
      if (e is DioException) {
        print('Dio error details: ${e.response?.data}');
        throw Exception(
          'Failed to delete crop: ${e.response?.data['message'] ?? e.message ?? 'Network error'}',
        );
      }
      rethrow;
    }
  }

  Future<List<OrderModel>> fetchOrders() async {
    try {
      final opts = await _jsonOptions();
      final response = await _dio.get(
        ApiConstants.getOrdersEndpoint,
        options: opts,
      );
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        if (data is List) {
          return data.map((e) => OrderModel.fromJson(e)).toList();
        }
        return [];
      }
      throw Exception('Failed to fetch orders: ${response.statusCode}');
    } catch (e) {
      print('Error fetching orders: $e');
      if (e is DioException) {
        print('Dio error details: ${e.response?.data}');
        throw Exception(
          'Failed to fetch orders: ${e.response?.data['message'] ?? e.message ?? 'Network error'}',
        );
      }
      rethrow;
    }
  }

  //TODO notification working stuffs
  Future<List<NotificationModel>> fetchNotifications() async {
    try {
      final opts = await _jsonOptions();
      final response = await _dio.get(
        ApiConstants.getNotificationsEndpoint,
        options: opts,
      );
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        if (data is List) {
          return data.map((e) => NotificationModel.fromJson(e)).toList();
        }
        return [];
      }
      throw Exception('Failed to fetch notifications: ${response.statusCode}');
    } catch (e) {
      print('Error fetching notifications: $e');
      if (e is DioException) {
        print('Dio error details: ${e.response?.data}');
        throw Exception(
          'Failed to fetch notifications: ${e.response?.data['message'] ?? e.message ?? 'Network error'}',
        );
      }
      rethrow;
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final opts = await _jsonOptions();
      final response = await _dio.put(
        '${ApiConstants.markNotificationAsReadEndpoint}/$notificationId',
        options: opts,
      );
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to mark notification as read: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error marking notification as read: $e');
      if (e is DioException) {
        print('Dio error details: ${e.response?.data}');
        throw Exception(
          'Failed to mark notification as read: ${e.response?.data['message'] ?? e.message ?? 'Network error'}',
        );
      }
      rethrow;
    }
  }
}
