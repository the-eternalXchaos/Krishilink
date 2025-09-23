// // import 'dart:convert';
// // import 'dart:io';
// // import 'package:get/get.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:krishi_link/core/utils/api_constants.dart';
// // import 'package:krishi_link/features/admin/models/product_model.dart';
// //  import 'package:krishi_link/src/features/auth/data/token_service.dart';
// // import 'package:krishi_link/services/popup_service.dart';
// //  
// // // class AdminProductController extends GetxController {
// // // //   final products = <Product>[].obs;
// // // //   final isLoading = false.obs;
// // // //   final totalProducts = 0.obs;
// // // //   final pendingProducts = 0.obs;

// // // //   @override
// // // //   void onInit() {
// // // //     super.onInit();
// // // //     fetchProducts();
// // // //   }

// // // //   Future<void> fetchProducts() async {
// // // //     try {
// // // //       isLoading(true);
// // // //       final token = await TokenService.getAccessToken();
// // // //       if (token == null) throw Exception('No authentication token');
// // // //       final response = await http.get(
// // // //         Uri.parse(ApiConstants.getAllProductsEndpoint),
// // // //         headers: {'Authorization': 'Bearer $token'},
// // // //       );

// // // //       if (response.statusCode == 200) {
// // // //         final List<dynamic> data = jsonDecode(response.body);
// // // //         products.assignAll(data.map((json) => Product.fromJson(json)).toList());
// // // //         totalProducts.value = products.length;
// // // //         pendingProducts.value =
// // // //             products.where((p) => p.status?.toLowerCase() == 'pending').length;
// // // //       } else {
// // // //         throw Exception('Failed to fetch products: ${response.statusCode}');
// // // //       }
// // // //     } catch (e) {
// // // //       PopupService.show(
// // // //         type: PopupType.error,
// // // //         title: 'Error',
// // // //         message: 'Failed to load products: $e',
// // // //         autoDismiss: true,
// // // //       );
// // // //     } finally {
// // // //       isLoading(false);
// // // //     }
// // // //   }

// // // //   Future<void> updateProductStatus(String id, String status) async {
// // // //     try {
// // // //       isLoading(true);
// // // //       final product = products.firstWhere((p) => p.id == id);
// // // //       final response = await http.put(
// // // //         Uri.parse('${ApiConstants.updateProductEndpoint}/$id'),
// // // //         headers: {
// // // //           'Authorization': 'Bearer ${await TokenService.getAccessToken()}',
// // // //           'Content-Type': 'application/json',
// // // //         },
// // // //         body: jsonEncode({'status': status}),
// // // //       );

// // // //       if (response.statusCode == 200) {
// // // //         products[products.indexOf(product)] = product.copyWith(status: status);
// // // //         pendingProducts.value =
// // // //             products.where((p) => p.status?.toLowerCase() == 'pending').length;
// // // //         PopupService.show(
// // // //           type: PopupType.success,
// // // //           title: 'Success',
// // // //           message: 'Product status updated to $status',
// // // //           autoDismiss: true,
// // // //         );
// // // //       } else {
// // // //         throw Exception('Failed to update product');
// // // //       }
// // // //     } catch (e) {
// // // //       PopupService.show(
// // // //         type: PopupType.error,
// // // //         title: 'Error',
// // // //         message: 'Failed to update product: $e',
// // // //         autoDismiss: true,
// // // //       );
// // // //     } finally {
// // // //       isLoading(false);
// // // //     }
// // // //   }

// // // // }

// // // import 'dart:convert';
// // // import 'package:get/get';
// // // import 'package:http/http.dart' as http;
// // // import 'package:krishi_link/core/utils/api_constants.dart';
// // // import 'package:krishi_link/features/admin/models/product_model.dart';
// // //  import 'package:krishi_link/src/features/auth/data/token_service.dart';
// // // import 'package:krishi_link/services/popup_service.dart';
// // //  
// // // class AdminProductController extends GetxController {
// // //   final products = <Product>[].obs;
// // //   final isLoading = false.obs;
// // //   final totalProducts = 0.obs;
// // //   final pendingProducts = 0.obs;

// // //   @override
// // //   void onInit() {
// // //     super.onInit();
// // //     fetchProducts();
// // //   }

// // //   Future<void> fetchProducts() async {
// // //     try {
// // //       isLoading(true);
// // //       final token = await TokenService.getAccessToken();
// // //       if (token == null) throw Exception('No authentication token');
// // //       final response = await http.get(
// // //         Uri.parse(ApiConstants.getAllProductsEndpoint),
// // //         headers: {'Authorization': 'Bearer $token'},
// // //       );

// // //       if (response.statusCode == 200) {
// // //         final List<dynamic> data = jsonDecode(response.body);
// // //         products.assignAll(data.map((json) => Product.fromJson(json)).toList());
// // //         totalProducts.value = products.length;
// // //         pendingProducts.value = products.where((p) => p.status?.toLowerCase() == 'pending').length;
// // //       } else {
// // //         throw Exception('Failed to fetch products: ${response.statusCode}');
// // //       }
// // //     } catch (e) {
// // //       PopupService.show(
// // //         type: PopupType.error,
// // //         title: 'Error',
// // //         message: 'Failed to load products: $e',
// // //         autoDismiss: true,
// // //       );
// // //     } finally {
// // //       isLoading(false);
// // //     }
// // //   }

// // //   Future<void> createProduct({
// // //     required String productName,
// // //     required double rate,
// // //     required String category,
// // //     required String status,  String description, required String location, required String image,  Object soldedQuantity, required String availableQuantity, required String , required String farmerPhone, required String farmerName,
// // //   }) async {
// // //     try {
// // //       isLoading(true);
// // //       final token = await TokenService.getAccessToken();
// // //       if (token == null) throw Exception('No authentication token');
// // //       final response = await http.post(
// // //         Uri.parse(ApiConstants.addProductEndpoint),
// // //         headers: {
// // //           'Authorization': 'Bearer $token',
// // //           'Content-Type': 'application/json',
// // //         },
// // //         body: jsonEncode({
// // //           'productName': productName,
// // //           'rate': rate,
// // //           'category': category,
// // //           'status': status,
// // //         }),
// // //       );

// // //       if (response.statusCode == 201) {
// // //         await fetchProducts(); // Refresh list
// // //         PopupService.show(
// // //           type: PopupType.success,
// // //           title: 'Success',
// // //           message: 'Product created successfully',
// // //           autoDismiss: true,
// // //         );
// // //       } else {
// // //         throw Exception('Failed to create product: ${response.statusCode}');
// // //       }
// // //     } catch (e) {
// // //       PopupService.show(
// // //         type: PopupType.error,
// // //         title: 'Error',
// // //         message: 'Failed to create product: $e',
// // //         autoDismiss: true,
// // //       );
// // //     } finally {
// // //       isLoading(false);
// // //     }
// // //   }

// // //   Future<void> updateProduct(
// // //     String id, {
// // //     String? productName,
// // //     double? rate,
// // //     String? category,
// // //     String? status,
// // //   }) async {
// // //     try {
// // //       isLoading(true);
// // //       final token = await TokenService.getAccessToken();
// // //       if (token == null) throw Exception('No authentication token');
// // //       final product = products.firstWhere((p) => p.id == id);
// // //       final response = await http.put(
// // //         Uri.parse('${ApiConstants.updateProductEndpoint}/$id'),
// // //         headers: {
// // //           'Authorization': 'Bearer $token',
// // //           'Content-Type': 'application/json',
// // //         },
// // //         body: jsonEncode({
// // //           'productName': productName ?? product.productName,
// // //           'rate': rate ?? product.rate,
// // //           'category': category ?? product.category,
// // //           'status': status ?? product.status,
// // //         }),
// // //       );

// // //       if (response.statusCode == 200) {
// // //         products[products.indexOf(product)] = product.copyWith(
// // //           productName: productName ?? product.productName,
// // //           rate: rate ?? product.rate,
// // //           category: category ?? product.category,
// // //           status: status ?? product.status,
// // //         );
// // //         pendingProducts.value = products.where((p) => p.status?.toLowerCase() == 'pending').length;
// // //         PopupService.show(
// // //           type: PopupType.success,
// // //           title: 'Success',
// // //           message: 'Product updated successfully',
// // //           autoDismiss: true,
// // //         );
// // //       } else {
// // //         throw Exception('Failed to update product: ${response.statusCode}');
// // //       }
// // //     } catch (e) {
// // //       PopupService.show(
// // //         type: PopupType.error,
// // //         title: 'Error',
// // //         message: 'Failed to update product: $e',
// // //         autoDismiss: true,
// // //       );
// // //     } finally {
// // //       isLoading(false);
// // //     }
// // //   }

// // //   Future<void> updateProductStatus(String id, String status) async {
// // //     await updateProduct(id, status: status); // Reuse updateProduct for status
// // //   }

// // //   Future<void> deleteProduct(String id) async {
// // //     try {
// // //       isLoading(true);
// // //       final token = await TokenService.getAccessToken();
// // //       if (token == null) throw Exception('No authentication token');
// // //       final response = await http.delete(
// // //         Uri.parse('${ApiConstants.deleteProductEndpoint}/$id'),
// // //         headers: {'Authorization': 'Bearer $token'},
// // //       );

// // //       if (response.statusCode == 200) {
// // //         products.removeWhere((p) => p.id == id);
// // //         totalProducts.value = products.length;
// // //         pendingProducts.value = products.where((p) => p.status?.toLowerCase() == 'pending').length;
// // //         PopupService.show(
// // //           type: PopupType.success,
// // //           title: 'Success',
// // //           message: 'Product deleted successfully',
// // //           autoDismiss: true,
// // //         );
// // //       } else {
// // //         throw Exception('Failed to delete product: ${response.statusCode}');
// // //       }
// // //     } catch (e) {
// // //       PopupService.show(
// // //         type: PopupType.error,
// // //         title: 'Error',
// // //         message: 'Failed to delete product: $e',
// // //         autoDismiss: true,
// // //       );
// // //     } finally {
// // //       isLoading(false);
// // //     }
// // //   }
// // // }

// import 'dart:convert';
// import 'dart:io';
// import 'package:dio/dio.dart';
// import 'package:get/get.dart' hide MultipartFile, FormData;
// import 'package:krishi_link/core/lottie/popup_service.dart';
// import 'package:krishi_link/core/utils/api_constants.dart';
// import 'package:krishi_link/features/admin/models/product_model.dart';
// import 'package:krishi_link/services/popup_service.dart';
//  //  import 'package:krishi_link/src/features/auth/data/token_service.dart';
// import 'package:krishi_link/features/auth/controller/auth_controller.dart';

// class AdminProductController extends GetxController {
//   final products = <Product>[].obs;
//   final isLoading = false.obs;
//   final totalProducts = 0.obs;
//   final Dio _dio = Dio();

//   @override
//   void onInit() {
//     super.onInit();
//     fetchProducts();
//   }

//   Future<void> fetchProducts({
//     String searchQuery = '',
//     Set<String> selectedCategories = const {},
//     Set<String> selectedLocations = const {},
//   }) async {
//     try {
//       isLoading(true);
//       final token = await TokenService.getAccessToken();
//       if (token == null) throw Exception('No authentication token');
//       final role =
//           Get.find<AuthController>().currentUser.value?.role?.toLowerCase() ??
//           '';
//       final endpoint =
//           role == 'farmer'
//               ? ApiConstants.getMyProductsEndpoint
//               : ApiConstants.getAllProductsEndpoint;

//       final queryParams = {
//         if (searchQuery.isNotEmpty) 'search': searchQuery,
//         if (selectedCategories.isNotEmpty)
//           'categories': selectedCategories.join(','),
//         if (selectedLocations.isNotEmpty)
//           'locations': selectedLocations.join(','),
//       };

//       final response = await _dio.get(
//         endpoint,
//         queryParameters: queryParams,
//         options: Options(headers: {'Authorization': 'Bearer $token'}),
//       );

//       if (response.statusCode == 200) {
//         final List<dynamic> data = response.data['data'];
//         products.assignAll(data.map((json) => Product.fromJson(json)).toList());
//         totalProducts.value = products.length;
//       } else {
//         throw Exception('Failed to fetch products: ${response.statusCode}');
//       }
//     } catch (e) {
//       PopupService.error('Failed to load products: $e');
//     } finally {
//       isLoading(false);
//     }
//   }

//   Future<Map<String, dynamic>> fetchFarmerDetails(String phone) async {
//     try {
//       final token = await TokenService.getAccessToken();
//       if (token == null) throw Exception('No authentication token');
//       final response = await _dio.get(
//         '${ApiConstants.getUserDetailsByPhoneNumber}/$phone',
//         options: Options(headers: {'Authorization': 'Bearer $token'}),
//       );

//       if (response.statusCode == 200) {
//         return {
//           'farmerId': response.data['farmerId']?.toString() ?? '',
//           'farmerName': response.data['fullName']?.toString() ?? '',
//         };
//       } else {
//         return {};
//       }
//     } catch (e) {
//       PopupService.error('Failed to fetch farmer: $e');
//       return {};
//     }
//   }

//   // Future<void> createProduct({
//   //   required String productName,
//   //   required String rate,
//   //   required String availableQuantity,
//   //   required String category,
//   //   required String location,
//   //   required File image,
//   //   String? description,
//   //   String? farmerPhoneOrEmail,
//   //   String? farmerName,
//   //   String? farmerId,
//   //   bool isActive = true,
//   // }) async {
//   //   try {
//   //     isLoading(true);
//   //     final token = await TokenService.getAccessToken();
//   //     if (token == null) throw Exception('No authentication token');

//   //     final formData = FormData.fromMap({
//   //       'ProductName': productName,
//   //       'Rate': rate,
//   //       'AvailableQuantity': availableQuantity,
//   //       'Category': category,
//   //       'Location': location,
//   //       if (description != null && description != 'No description')
//   //         'Description': description,
//   //       'FarmerId': farmerId ?? 'admin',
//   //       'FarmerName': farmerName ?? 'Admin',
//   //       'FarmerPhoneNumber': farmerPhoneOrEmail ?? '',
//   //       'SoldedQuantity': '0',
//   //       'IsActive': isActive.toString(),
//   //       'Image': await MultipartFile.fromFile(image.path),
//   //     });

//   //     final response = await _dio.post(
//   //       ApiConstants.addProductEndpoint,
//   //       data: formData,
//   //       options: Options(headers: {'Authorization': 'Bearer $token'}),
//   //     );

//   //     if (response.statusCode == 201 || response.statusCode == 200) {
//   //       await fetchProducts();
//   //       PopupService.success('Product created successfully');
//   //     } else {
//   //       throw Exception('Failed to create product: ${response.statusCode}');
//   //     }
//   //   } catch (e) {
//   //     PopupService.error('Failed to create product: $e');
//   //   } finally {
//   //     isLoading(false);
//   //   }
//   // }

//   // Future<void> updateProduct(
//   //   String id, {
//   //   String? productName,
//   //   String? rate,
//   //   String? availableQuantity,
//   //   String? category,
//   //   String? location,
//   //   File? image,
//   //   String? description,
//   //   String? farmerPhone,
//   //   String? farmerName,
//   //   String? farmerId,
//   //   bool? isActive,
//   // }) async {
//   //   try {
//   //     isLoading(true);
//   //     final token = await TokenService.getAccessToken();
//   //     if (token == null) throw Exception('No authentication token');
//   //     final product = products.firstWhere((p) => p.id == id);

//   //     final formData = FormData.fromMap({
//   //       'ProductName': productName ?? product.productName,
//   //       'Rate': rate ?? product.rate,
//   //       'AvailableQuantity': availableQuantity ?? product.availableQuantity,
//   //       'Category': category ?? product.category,
//   //       'Location': location ?? product.location,
//   //       if (description != null && description != 'No description')
//   //         'Description': description,
//   //       'FarmerId': farmerId ?? product.farmerId,
//   //       'FarmerName': farmerName ?? product.farmerName,
//   //       'FarmerPhoneNumber': farmerPhone ?? product.farmerPhone,
//   //       'SoldedQuantity': product.soldedQuantity,
//   //       'IsActive': (isActive ?? product.isActive).toString(),
//   //       if (image != null) 'Image': await MultipartFile.fromFile(image.path),
//   //     });

//   //     final response = await _dio.put(
//   //       '${ApiConstants.updateProductEndpoint}/$id',
//   //       data: formData,
//   //       options: Options(headers: {'Authorization': 'Bearer $token'}),
//   //     );

//   //     if (response.statusCode == 200) {
//   //       products[products.indexOf(product)] = product.copyWith(
//   //         productName: productName,
//   //         rate: rate as double,
//   //         availableQuantity: availableQuantity as double,
//   //         category: category,
//   //         location: location,
//   //         description: description,
//   //         farmerPhone: farmerPhone,
//   //         farmerName: farmerName,
//   //         farmerId: farmerId,
//   //         isActive: isActive,
//   //         image:
//   //             image != null
//   //                 ? '${ApiConstants.getProductImageEndpoint}/$id?t=${DateTime.now().millisecondsSinceEpoch}'
//   //                 : product.image,
//   //       );
//   //       PopupService.success('Product updated successfully');
//   //     } else {
//   //       throw Exception('Failed to update product: ${response.statusCode}');
//   //     }
//   //   } catch (e) {
//   //     PopupService.error('Failed to update product: $e');
//   //   } finally {
//   //     isLoading(false);
//   //   }
//   // }

//   // Future<void> updateProductActiveStatus(String id, bool isActive) async {
//   //   try {
//   //     isLoading(true);
//   //     final token = await TokenService.getAccessToken();
//   //     if (token == null) throw Exception('No authentication token');
//   //     final response = await _dio.put(
//   //       '${ApiConstants.updateProductStatusEndpoint}/$id',
//   //       data: {'isActive': isActive},
//   //       options: Options(headers: {'Authorization': 'Bearer $token'}),
//   //     );
//   //     if (response.statusCode == 200) {
//   //       final idx = products.indexWhere((p) => p.id == id);
//   //       if (idx != -1)
//   //         products[idx] = products[idx].copyWith(isActive: isActive);
//   //       PopupService.success('Product status updated');
//   //     } else {
//   //       throw Exception(
//   //         'Failed to update product status: ${response.statusCode}',
//   //       );
//   //     }
//   //   } catch (e) {
//   //     PopupService.error('Failed to update product status: $e');
//   //   } finally {
//   //     isLoading(false);
//   //   }
//   // }

//   // Future<void> deleteProduct(String id) async {
//   //   try {
//   //     isLoading(true);
//   //     final token = await TokenService.getAccessToken();
//   //     if (token == null) throw Exception('No authentication token');
//   //     final response = await _dio.delete(
//   //       '${ApiConstants.deleteProductEndpoint}/$id',
//   //       options: Options(headers: {'Authorization': 'Bearer $token'}),
//   //     );

//   //     if (response.statusCode == 200) {
//   //       products.removeWhere((p) => p.id == id);
//   //       totalProducts.value = products.length;
//   //       PopupService.success('Product deleted successfully');
//   //     } else {
//   //       throw Exception('Failed to delete product: ${response.statusCode}');
//   //     }
//   //   } catch (e) {
//   //     PopupService.error('Failed to delete product: $e');
//   //   } finally {
//   //     isLoading(false);
//   //   }
//   // }
// }
