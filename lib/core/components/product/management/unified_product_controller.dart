import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:krishi_link/core/components/product/management/unified_product_api_services.dart';
import 'package:krishi_link/core/lottie/popup.dart';
import 'package:path_provider/path_provider.dart';
import 'package:krishi_link/core/components/product/product_form_data.dart';
import 'package:krishi_link/features/admin/models/product_model.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/core/utils/api_constants.dart';

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

  // Track last request time for cooldown
  DateTime? _lastRequestTime;
  static const Duration _requestCooldown = Duration(seconds: 30);

  final AuthController authController = Get.find<AuthController>();
  final UnifiedProductApiServices apiService =
      Get.find<UnifiedProductApiServices>();
  dio.CancelToken? _currentRequestToken;

  @override
  void onInit() {
    super.onInit();
    _initializeUser();
  }

  @override
  void onClose() {
    _currentRequestToken?.cancel('Controller disposed');
    super.onClose();
  }

  void _initializeUser() {
    final user = authController.currentUser.value;
    currentUserRole.value = user?.role.toLowerCase() ?? 'guest';
    currentUserId.value = user?.id ?? '';
  }

  Future<void> fetchProducts({
    String? searchQuery,
    List<String>? selectedCategories,
    List<String>? selectedLocations,
    String? status,
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

      final fetchedProducts = await apiService.fetchProducts(
        endpoint:
            currentUserRole.value == 'admin'
                ? ApiConstants.getAllProductsEndpoint
                : ApiConstants.getMyProductsEndpoint,
        searchQuery: searchQuery,
        selectedCategories: selectedCategories,
        selectedLocations: selectedLocations,
        status: status,
        page: page.value,
        pageSize: pageSize,
      );

      if (fetchedProducts.length < pageSize) {
        hasMore.value = false;
      }
      products.addAll(fetchedProducts);
      page.value++;
    } catch (e) {
      debugPrint('❌ [UnifiedProductController] Error fetching products: $e');
      if (e.toString().contains('404')) {
        PopupService.showSnackbar(
          title: 'No Data',
          message: 'No products found.',
        );
        hasMore.value = false;
      } else {
        PopupService.error('Failed to fetch products: $e', title: 'Error');
        hasMore.value = false;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addProduct(ProductFormData formData, String? imagePath) async {
    debugPrint(
      '🔄 [Controller] addProduct called with formData: ${formData.productName}, imagePath: $imagePath',
    );

    // Cooldown check
    if (_lastRequestTime != null &&
        DateTime.now().difference(_lastRequestTime!) < _requestCooldown) {
      final remainingSeconds =
          _requestCooldown.inSeconds -
          DateTime.now().difference(_lastRequestTime!).inSeconds;
      debugPrint(
        '❌ [Controller] Cooldown active, remaining: $remainingSeconds seconds',
      );
      PopupService.error(
        'Please wait $remainingSeconds seconds before adding another product.',
      );
      return;
    }

    // Check network connectivity
    if (!await _checkNetworkConnectivity()) {
      debugPrint('❌ [Controller] No network connectivity');
      _showNetworkError();
      // PopupService.error('No internet connection. Please check your network.');
      return;
    }

    try {
      isLoading.value = true;
      debugPrint('🔄 [Controller] Calling apiService.addProduct');

      // Cancel any existing request
      _currentRequestToken?.cancel('New addProduct request started');
      _currentRequestToken = dio.CancelToken();

      final product = await apiService.addProduct(
        productName: formData.productName,
        image: File(imagePath!),
        rate: formData.rate,
        availableQuantity: formData.availableQuantity,
        category: formData.category,
        emailOrPhone: authController.currentUser.value?.email ?? '',
        unit: formData.unit,
        description: formData.description,
        latitude: formData.latitude,
        longitude: formData.longitude,
        cancelToken: _currentRequestToken,
      );
      debugPrint('✅ [Controller] Product added: ${product.productName}');

      _lastRequestTime = DateTime.now();
      products.add(product);
      products.refresh();
      PopupService.success('Product added successfully!');
      await Future.delayed(const Duration(milliseconds: 500));
      // Get.back();
    } catch (e) {
      debugPrint('❌ [Controller] Error adding product: $e');
      String errorMessage = 'Failed to add product';
      if (e is dio.DioException) {
        if (e.type == dio.DioExceptionType.connectionTimeout ||
            e.type == dio.DioExceptionType.receiveTimeout) {
          errorMessage =
              'Network timeout. Please check your internet connection.';
        } else if (e.type == dio.DioExceptionType.badResponse) {
          errorMessage =
              e.response?.data['message'] ?? 'Server error occurred.';
        } else if (e.type == dio.DioExceptionType.cancel) {
          errorMessage = 'Request was cancelled.';
        } else {
          errorMessage = e.message ?? 'Unknown error occurred.';
        }
      }
      PopupService.error(errorMessage);
      rethrow;
    } finally {
      isLoading.value = false;
      _currentRequestToken = null;
      debugPrint(
        '🔄 [Controller] addProduct completed, isLoading set to false',
      );
    }
  }

  Future<void> updateProduct(
    String productId,
    ProductFormData formData,
    String? imagePath,
  ) async {
    try {
      isLoading.value = true;
      debugPrint('🔄 [Controller] Updating product: $productId');

      // Cancel any existing request
      _currentRequestToken?.cancel('New updateProduct request started');
      _currentRequestToken = dio.CancelToken();

      final product = Product(
        id: productId,
        productName: formData.productName,
        rate: formData.rate,
        availableQuantity: formData.availableQuantity,
        category: formData.category,
        unit: formData.unit,
        description: formData.description,
        latitude: formData.latitude,
        longitude: formData.longitude,
        image: formData.imagePath,
        soldedQuantity: 0.0,
        farmerId: authController.currentUser.value?.id ?? '',
        farmerName: authController.currentUser.value?.fullName ?? '',
        farmerPhone: formData.farmerContact,
        isActive: true,
        createdAt: DateTime.now(),
      );

      final updatedProduct = await apiService.updateProduct(
        productId,
        product,
        imageFile: imagePath != null ? File(imagePath) : null,
        cancelToken: _currentRequestToken,
      );

      // Update local list and refresh
      final index = products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        products[index] = updatedProduct;
        products.refresh();
        debugPrint('✅ [Controller] Local product list updated');
      } else {
        // If product not found in list, fetch fresh data
        await fetchProducts(reset: true);
        debugPrint('✅ [Controller] Products list refreshed from API');
      }

      PopupService.success('Product updated successfully');
      Get.back();

      // Add delay to ensure UI updates
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      debugPrint('❌ [Controller] Update error: $e');
      String errorMessage = 'Failed to update product';
      if (e is dio.DioException) {
        errorMessage = e.response?.data['message'] ?? 'Server error occurred.';
      }
      PopupService.error(errorMessage);
      rethrow;
    } finally {
      isLoading.value = false;
      _currentRequestToken = null;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      isLoading.value = true;
      debugPrint(
        '🔄 [UnifiedProductController] deleteProduct called for productId: $productId',
      );

      _currentRequestToken?.cancel('New deleteProduct request started');
      _currentRequestToken = dio.CancelToken();

      await apiService.deleteProduct(
        productId,
        cancelToken: _currentRequestToken,
      );

      products.removeWhere((p) => p.id == productId);
      products.refresh();
      await fetchProducts(reset: true);
      PopupService.success('Product deleted successfully!');
      await Future.delayed(const Duration(milliseconds: 500));
      Get.back();
    } catch (e) {
      debugPrint('❌ [UnifiedProductController] Error deleting product: $e');
      String errorMessage = 'Failed to delete product';
      if (e is dio.DioException) {
        errorMessage = e.response?.data['message'] ?? 'Server error occurred.';
      }
      PopupService.error(errorMessage);
      rethrow;
    } finally {
      isLoading.value = false;
      _currentRequestToken = null;
    }
  }

  Future<void> updateProductActiveStatusApi(
    String productId,
    bool isActive,
  ) async {
    if (currentUserRole.value != 'admin' && currentUserRole.value != 'farmer') {
      PopupService.error('Only admins and farmers can update product status.');
      return;
    }
    try {
      await apiService.updateProductActiveStatus(productId, isActive);

      final productIndex = products.indexWhere((p) => p.id == productId);
      if (productIndex != -1) {
        products[productIndex] = products[productIndex].copyWith(
          isActive: isActive,
        );
        products.refresh();
      } else {
        await fetchProducts(reset: true);
      }
      PopupService.success('Product status updated successfully');
    } catch (e) {
      debugPrint(
        '❌ [UnifiedProductController] Error updating product status: $e',
      );
      PopupService.error(
        'Failed to update product status: ${e.toString().replaceAll('Exception: ', '')}',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> fetchUserDetailsByEmailOrPhone(
    String input,
  ) async {
    try {
      return await apiService.fetchUserDetailsByEmailOrPhone(input);
    } catch (e) {
      debugPrint(
        '❌ [UnifiedProductController] Error fetching user details: $e',
      );
      PopupService.error(
        'Failed to fetch user details: ${e.toString().replaceAll('Exception: ', '')}',
      );
      return null;
    }
  }

  RxList<Product> get userProducts =>
      currentUserRole.value == 'admin'
          ? products
          : products
              .where((p) => p.farmerId == currentUserId.value)
              .toList()
              .obs;

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

  Set<String> getAvailableCategories() {
    return userProducts.map((p) => p.category).toSet()..remove('');
  }

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

  // TODO: Unused method - commented out to resolve lint warnings
  // Future<File?> _downloadImageToLocal(String imageUrl) async {
  //   try {
  //     debugPrint('🔄 [UnifiedProductController] Downloading image: $imageUrl');
  //     final response = await dio.Dio().get(
  //       imageUrl,
  //       options: dio.Options(responseType: dio.ResponseType.bytes),
  //     );

  //     if (response.statusCode == 200) {
  //       final bytes = response.data as List<int>;
  //       final tempDir = await getTemporaryDirectory();
  //       final fileName =
  //           'temp_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
  //       final file = File('${tempDir.path}/$fileName');
  //       await file.writeAsBytes(bytes);
  //       debugPrint(
  //         '✅ [UnifiedProductController] Image downloaded to: ${file.path}',
  //       );
  //       return file;
  //     }
  //   } catch (e) {
  //     debugPrint('❌ [UnifiedProductController] Failed to download image: $e');
  //   }
  //   return null;
  // }

  Future<bool> _checkNetworkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      debugPrint(
        '❌ [UnifiedProductController] Error checking connectivity: $e',
      );
      return false;
    }
  }

  void _showNetworkError() {
    PopupService.showSnackbar(
      type: PopupType.error,
      message:
          'No internet connection. Please check your internet connection and try again.',
      title: 'No Internet Connection',
    );
  }

  Future<bool> _showDeleteConfirmation(String productName) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "$productName"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> deleteProductWithConfirmation(
    String productId,
    String productName,
  ) async {
    final confirmed = await _showDeleteConfirmation(productName);
    if (confirmed) {
      await deleteProduct(productId);
    }
  }

  String getCooldownStatus() {
    if (_lastRequestTime == null) return 'No requests made yet';
    final elapsed = DateTime.now().difference(_lastRequestTime!);
    if (elapsed >= _requestCooldown) {
      return 'Ready for new requests';
    } else {
      final remaining = _requestCooldown - elapsed;
      return 'Cooldown active, ${remaining.inSeconds} seconds remaining';
    }
  }
}
