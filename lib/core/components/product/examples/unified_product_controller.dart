import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/features/admin/models/product_model.dart';
import 'package:krishi_link/core/components/product/product_form_data.dart';
import 'package:krishi_link/services/farmer_api_service.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'dart:io';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:dio/dio.dart' as dio;
import 'package:krishi_link/core/utils/api_constants.dart';

/// Unified Product Controller that can be used by both Admin and Farmer
/// This controller provides common functionality and can be extended for specific roles
class UnifiedProductController extends GetxController {
  final RxList<Product> products = <Product>[].obs;
  final RxBool isLoading = false.obs;
  final RxString currentUserRole = ''.obs;
  final RxString currentUserId = ''.obs;
  final RxInt page = 1.obs;
  final int pageSize = 20;
  final RxBool hasMore = true.obs;

  final totalProducts = 0.obs;
  final pendingProducts = 0.obs;

  final AuthController authController = Get.find<AuthController>();

  final dio.Dio _dio = dio.Dio(
    dio.BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<dio.Options> _jsonOptions() async {
    final token = authController.currentUser.value?.token;
    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }
    return dio.Options(
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
    );
  }

  Future<dio.Options> _formOptions() async {
    final token = authController.currentUser.value?.token;
    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }
    return dio.Options(
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'multipart/form-data',
        'accept': 'text/plain',
      },
    );
  }

  Future<List<Product>> fetchProductsApi({
    String? searchQuery,
    List<String>? selectedCategories,
    List<String>? selectedLocations,
    String? status, // Add status filter parameter
    int page = 1,
    int pageSize = 20,
  }) async {
    final opts = await _jsonOptions();
    final role = currentUserRole.value;
    final endpoint =
        role == 'admin'
            ? ApiConstants.getAllProductsEndpoint
            : ApiConstants.getMyProductsEndpoint;
    final response = await _dio.get(
      endpoint,
      queryParameters: {
        if (searchQuery != null) 'searchQuery': searchQuery,
        if (selectedCategories != null && selectedCategories.isNotEmpty)
          'categories': selectedCategories.join(','),
        if (selectedLocations != null && selectedLocations.isNotEmpty)
          'locations': selectedLocations.join(','),
        if (status != null && status != 'all')
          'status': status, // Add status filter
        'page': page,
        'pageSize': pageSize,
      },
      options: opts,
    );
    if (response.statusCode == 200) {
      final data = response.data['data'] ?? response.data;
      if (data is List) {
        return data.map((e) => Product.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 404) {
      return [];
    }
    throw Exception(
      'Failed to fetch products:  [31m${response.statusCode} [0m',
    );
  }

  Future<Product> addProductApi({
    required String productName,
    required File image,
    required String rate,
    required String availableQuantity,
    required String category,
    required String emailOrPhone,
    String? description,
    String unit = 'kg',
    double latitude = 0,
    double longitude = 0,
  }) async {
    try {
      print('🔄 [UnifiedProductController] addProductApi called');
      print(
        '🔄 [UnifiedProductController] API endpoint: ${ApiConstants.addProductEndpoint}',
      );
      print(
        '🔄 [UnifiedProductController] Product details - Name: $productName, Rate: $rate, Category: $category, Lat: $latitude, Lng: $longitude',
      );
      print('🔄 [UnifiedProductController] Email/Phone: $emailOrPhone');

      final opts = await _formOptions();
      final formData = dio.FormData.fromMap({
        'ProductName': productName,
        'Rate': rate,
        'AvailableQuantity': availableQuantity,
        'Category': category,
        'Unit': unit,
        'Description': description ?? '',
        'Latitude': latitude.toString(),
        'Longitude': longitude.toString(),
        'Image': await dio.MultipartFile.fromFile(
          image.path,
          filename: image.path.split('/').last,
        ),
      });

      print(
        '🔄 [UnifiedProductController] Form data prepared: ${formData.fields.map((e) => '${e.key}: ${e.value}')}',
      );
      print('🔄 [UnifiedProductController] Image file: ${image.path}');

      final response = await _dio.post(
        ApiConstants.addProductEndpoint,
        data: formData,
        queryParameters: {'EmailorPhone': emailOrPhone},
        options: opts,
      );

      print(
        '🔄 [UnifiedProductController] API response status: ${response.statusCode}',
      );
      print(
        '🔄 [UnifiedProductController] API response data: ${response.data}',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        print('✅ [UnifiedProductController] Add product API call successful');
        return Product.fromJson(response.data['data']);
      }

      print(
        '❌ [UnifiedProductController] Add product API call failed: ${response.data['message'] ?? response.statusCode}',
      );
      throw Exception(
        'Failed to add product: ${response.data['message'] ?? response.statusCode}',
      );
    } catch (e) {
      print('❌ [UnifiedProductController] addProductApi error: $e');
      if (e is dio.DioException) {
        print('❌ [UnifiedProductController] Dio error type: ${e.type}');
        print('❌ [UnifiedProductController] Dio error message: ${e.message}');
        print(
          '❌ [UnifiedProductController] Dio error response: ${e.response?.data}',
        );
        print(
          '❌ [UnifiedProductController] Dio error status code: ${e.response?.statusCode}',
        );
        print(
          '❌ [UnifiedProductController] Dio error headers: ${e.response?.headers}',
        );
      }
      rethrow;
    }
  }

  Future<Product> updateProductApi(
    String productId,
    Product product, {
    File? imageFile,
  }) async {
    try {
      debugPrint(
        '🔄 [UnifiedProductController] updateProductApi called for product: $productId',
      );
      debugPrint(
        '🔄 [UnifiedProductController] API endpoint: ${ApiConstants.updateProductEndpoint}/$productId',
      );

      final opts = await _formOptions();
      final formData = dio.FormData.fromMap({
        'ProductName': product.productName,
        'Rate': product.rate.toString(),
        'AvailableQuantity': product.availableQuantity.toString(),
        'Category': product.category,
        'Unit': product.unit,
        'Description': product.description ?? '',
        'Latitude': product.latitude.toString(),
        'Longitude': product.longitude.toString(),
        if (imageFile != null)
          'Image': await dio.MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.path.split('/').last,
          ),
      });

      debugPrint(
        '🔄 [UnifiedProductController] Form data prepared: ${formData.fields.map((e) => '${e.key}: ${e.value}')}',
      );
      debugPrint(
        '🔄 [UnifiedProductController] Product details - Name: ${product.productName}, Rate: ${product.rate}, Category: ${product.category}, Lat: ${product.latitude}, Lng: ${product.longitude}',
      );

      final response = await _dio.put(
        '${ApiConstants.updateProductEndpoint}/$productId',
        data: formData,
        queryParameters: {
          'EmailorPhone': authController.currentUser.value?.email ?? '',
        },
        options: opts,
      );

      debugPrint(
        '🔄 [UnifiedProductController] API response status: ${response.statusCode}',
      );
      debugPrint(
        '🔄 [UnifiedProductController] API response data: ${response.data}',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        print('✅ [UnifiedProductController] API call successful');
        return product.copyWith(
          image:
              imageFile != null
                  ? '${ApiConstants.getProductImageEndpoint}/$productId?t=${DateTime.now().millisecondsSinceEpoch}'
                  : product.image,
        );
      }

      debugPrint(
        '❌ [UnifiedProductController] API call failed: ${response.data['message'] ?? response.statusCode}',
      );
      throw Exception(
        'Failed to update product: ${response.data['message'] ?? response.statusCode}',
      );
    } catch (e) {
      debugPrint('❌ [UnifiedProductController] updateProductApi error: $e');
      if (e is dio.DioException) {
        debugPrint('❌ [UnifiedProductController] Dio error type: ${e.type}');
        debugPrint(
          '❌ [UnifiedProductController] Dio error message: ${e.message}',
        );
        debugPrint(
          '❌ [UnifiedProductController] Dio error response: ${e.response?.data}',
        );
        debugPrint(
          '❌ [UnifiedProductController] Dio error status code: ${e.response?.statusCode}',
        );
        debugPrint(
          '❌ [UnifiedProductController] Dio error headers: ${e.response?.headers}',
        );
      }
      rethrow;
    }
  }

  Future<void> deleteProductApi(String productId) async {
    final opts = await _jsonOptions();
    final response = await _dio.delete(
      '${ApiConstants.deleteProductEndpoint}/$productId',
      options: opts,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete product: ${response.statusCode}');
    }
  }

  // Future<void> updateProductActiveStatusApi(
  //   String productId,
  //   bool isActive,
  // ) async {
  //   final opts = await _jsonOptions();
  //   final response = await _dio.put(
  //     '${ApiConstants.updateProductStatusEndpoint}/$productId',
  //     data: {'isActive': isActive},
  //     options: opts,
  //   );
  //   if (response.statusCode != 200) {
  //     throw Exception(
  //       'Failed to update product status: ${response.statusCode}',
  //     );
  //   }
  // }

  Future<void> updateProductActiveStatus(
    String productId,
    bool isActive,
  ) async {
    try {
      final opts = await _jsonOptions();
      print('Updating product $productId to isActive: $isActive');
      print(
        'API endpoint: ${ApiConstants.updateProductStatusEndpoint}/$productId',
      );
      final response = await _dio.put(
        '${ApiConstants.updateProductStatusEndpoint}/$productId',
        data: {'isActive': isActive},
        options: opts,
      );
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to update product status: ${response.statusCode}',
        );
      }

      // Update the local product list to make the toggle reactive
      final productIndex = products.indexWhere((p) => p.id == productId);
      if (productIndex != -1) {
        products[productIndex] = products[productIndex].copyWith(
          isActive: isActive,
        );
        products.refresh(); // Notify listeners that the list has changed
        debugPrint('Updated local product status for $productId to $isActive');
      } else {
        debugPrint('Warning: Product $productId not found in local list');
        // Refresh the entire list to ensure we have the latest data
        await fetchProducts();
      }

      // Show success message
      PopupService.success('Product status updated successfully');
    } catch (e) {
      debugPrint('Error updating product status: $e');
      if (e is dio.DioException) {
        debugPrint('Dio error details: ${e.response?.data}');
        PopupService.error(
          'Failed to update product status: ${e.response?.data['message'] ?? 'Network error'}',
        );
        throw Exception(
          'Failed to update product status: ${e.response?.data['message'] ?? 'Network error'}',
        );
      }
      PopupService.error('Failed to update product status: $e');
      rethrow;
    }
  }

  bool isEmail(String input) => RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(input);

  Future<Map<String, dynamic>?> fetchUserDetailsByEmailOrPhone(
    String input,
  ) async {
    final opts = await _jsonOptions();
    try {
      dio.Response response;
      if (isEmail(input)) {
        response = await _dio.get(
          '${ApiConstants.getUserDetailsByEmail}?email=$input',
          options: opts,
        );
      } else {
        response = await _dio.get(
          '${ApiConstants.getUserDetailsByPhoneNumber}/$input',
          options: opts,
        );
      }
      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user details: $e');
      return null;
    }
  }

  // Filtered products based on current user role
  RxList<Product> get userProducts =>
      currentUserRole.value == 'admin'
          ? products // Admin sees all products
          : products
              .where((p) => p.farmerId == currentUserId.value)
              .toList()
              .obs;

  @override
  void onInit() {
    super.onInit();
    _initializeUser();

    Future.delayed(const Duration(seconds: 2), () {
      fetchProducts();
      debugPrint('fetchProducts');
    });
  }

  void _initializeUser() {
    final user = authController.currentUser.value;
    currentUserRole.value = user?.role.toLowerCase() ?? 'guest';
    currentUserId.value = user?.uid ?? '';
  }

  /// Fetch products based on user role
  Future<void> fetchProducts({
    String? searchQuery,
    List<String>? selectedCategories,
    List<String>? selectedLocations,
    String? status, // Add status filter parameter
    bool reset = false,
  }) async {
    try {
      isLoading.value = true;
      if (reset) {
        page.value = 1;
        hasMore.value = true;
        products.clear();
      }
      if (!hasMore.value) return;
      try {
        final fetchedProducts = await fetchProductsApi(
          searchQuery: searchQuery,
          selectedCategories: selectedCategories,
          selectedLocations: selectedLocations,
          status: status, // Pass status filter to API
          page: page.value,
          pageSize: pageSize,
        );
        if (fetchedProducts.length < pageSize) {
          hasMore.value = false;
        }
        products.addAll(fetchedProducts);
        page.value++;
      } on Exception catch (e) {
        final msg = e.toString();
        if (msg.contains('404')) {
          PopupService.showSnackbar(
            title: 'No Data',
            message: 'No products found.',
          );
          hasMore.value = false;
          isLoading.value = false;
          return;
        } else {
          PopupService.error('Failed to fetch products. $msg', title: 'Error');
          hasMore.value = false;
          isLoading.value = false;
          return;
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Load next page of products
  Future<void> loadMoreProducts() async {
    await fetchProducts();
  }

  /// Fetch all products (Admin only)
  Future<void> _fetchAllProducts(
    String? searchQuery,
    List<String>? selectedCategories,
    List<String>? selectedLocations,
    String? status,
  ) async {
    // Use FarmerApiServices for admin getAllProducts
    final fetched = await fetchProductsApi(
      searchQuery: searchQuery,
      selectedCategories: selectedCategories,
      selectedLocations: selectedLocations,
      status: status,
    );
    products.value = fetched;
  }

  /// Fetch user's own products (Farmer)
  Future<void> _fetchUserProducts(
    String? searchQuery,
    List<String>? selectedCategories,
    List<String>? selectedLocations,
    String? status,
  ) async {
    // Use FarmerApiServices for farmer's products
    final fetched = await fetchProductsApi(
      searchQuery: searchQuery,
      selectedCategories: selectedCategories,
      selectedLocations: selectedLocations,
      status: status,
    );
    // Only keep products for this farmer
    products.value =
        fetched.where((p) => p.farmerId == currentUserId.value).toList();
  }

  /// Add new product
  Future<void> addProduct(ProductFormData formData, String? imagePath) async {
    try {
      isLoading.value = true;
      await addProductApi(
        productName: formData.productName,
        image: imagePath != null ? File(imagePath) : File(''),
        rate: formData.rate.toString(),
        availableQuantity: formData.availableQuantity.toString(),
        category: formData.category,
        emailOrPhone: authController.currentUser.value?.email ?? '',
        description: formData.description,
        unit: formData.unit,
        latitude: formData.latitude,
        longitude: formData.longitude,
      );
      await fetchProducts();
    } finally {
      isLoading.value = false;
    }
  }

  /// Update existing product
  Future<void> updateProduct(
    String productId,
    ProductFormData formData,
    String? imagePath,
  ) async {
    try {
      debugPrint(
        '🔄 [UnifiedProductController] Starting update for product: $productId',
      );
      debugPrint(
        '🔄 [UnifiedProductController] Form data: ${formData.productName}, ${formData.rate}, ${formData.category}',
      );

      isLoading.value = true;

      // Check if product exists in the list
      final productIndex = products.indexWhere((p) => p.id == productId);
      if (productIndex == -1) {
        debugPrint(
          '❌ [UnifiedProductController] Product not found in list: $productId',
        );
        debugPrint(
          '❌ [UnifiedProductController] Available products: ${products.map((p) => p.id).toList()}',
        );
        throw Exception('Product not found in local list');
      }

      final product = products[productIndex];
      debugPrint(
        '✅ [UnifiedProductController] Found product: ${product.productName}',
      );

      // Create updated product with new form data
      final updatedProduct = product.copyWith(
        productName: formData.productName,
        description: formData.description,
        rate: formData.rate,
        availableQuantity: formData.availableQuantity,
        category: formData.category,
        unit: formData.unit,
        latitude: formData.latitude,
        longitude: formData.longitude,
      );

      debugPrint('🔄 [UnifiedProductController] Calling updateProductApi...');
      await updateProductApi(
        productId,
        updatedProduct,
        imageFile: imagePath != null ? File(imagePath) : null,
      );

      debugPrint(
        '✅ [UnifiedProductController] API call successful, refreshing products...',
      );
      await fetchProducts();
      debugPrint('✅ [UnifiedProductController] Update completed successfully');
    } catch (e) {
      debugPrint('❌ [UnifiedProductController] Error updating product: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      isLoading.value = true;
      await deleteProductApi(productId);
      await fetchProducts();
    } finally {
      isLoading.value = false;
    }
  }

  /// Toggle product active status (Admin only)
  Future<void> updateProductActiveStatusApi(
    String productId,
    bool isActive,
  ) async {
    if (currentUserRole.value != 'admin') {
      Get.snackbar('error'.tr, 'admin_only_action'.tr);
      return;
    }
    try {
      await updateProductActiveStatus(
        productId,
        isActive,
      ); // Call the actual API method
      await fetchProducts();
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    }
  }

  /// Get product statistics
  Map<String, dynamic> getProductStats() {
    final userProductsList = userProducts.toList();

    return {
      'total': userProductsList.length,
      'active': userProductsList.where((p) => p.isActive).length,
      'inactive': userProductsList.where((p) => !p.isActive).length,
      'totalValue': userProductsList.fold<double>(
        0,
        (sum, p) => sum + (p.rate * p.availableQuantity),
      ),
      'categories': userProductsList.map((p) => p.category).toSet().length,
    };
  }

  /// Get available categories
  Set<String> getAvailableCategories() {
    return userProducts.map((p) => p.category).toSet()..remove('');
  }

  /// Search products
  List<Product> searchProducts(String query) {
    if (query.isEmpty) return userProducts.toList();

    final lowerQuery = query.toLowerCase();
    return userProducts.where((product) {
      return product.productName.toLowerCase().contains(lowerQuery) ||
          product.category.toLowerCase().contains(lowerQuery) ||
          product.description.toLowerCase().contains(lowerQuery) ||
          (product.location?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }
}
