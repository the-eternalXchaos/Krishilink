import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:http/http.dart' as http;
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/auth/controller/cart_controller.dart';
import 'package:krishi_link/src/core/components/material_ui/pop_up.dart';
import 'package:krishi_link/src/core/networking/api_service.dart';
import 'package:krishi_link/src/core/networking/dio_provider.dart';
import 'package:krishi_link/src/features/auth/data/token_service.dart';
import 'package:krishi_link/src/features/product/data/models/product_model.dart';
import 'package:krishi_link/src/features/product/data/models/review_model.dart';
import 'package:krishi_link/src/features/product/presentation/controllers/filter_controller.dart';

class ProductController extends GetxController {
  // Core product data
  final RxList<Product> products = <Product>[].obs;
  final RxList<Product> filteredProducts = <Product>[].obs;
  final RxList<Product> relatedProducts = <Product>[].obs;

  // Review data
  final RxList<ReviewModel> reviewsModel = <ReviewModel>[].obs;
  final RxBool isLoadingReviews = false.obs;

  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isRelatedLoading = false.obs;
  final RxBool hasMore = true.obs;

  // Error handling
  final RxString errorMessage = ''.obs;
  final RxString relatedErrorMessage = ''.obs;

  // Pagination
  int currentPage = 1;
  int pageSize = 20;
  bool isLastPage = false;

  // Rate limiting and caching
  DateTime? _lastFetchTime;
  DateTime? lastSuccessfulFetch;
  static const Duration _minFetchInterval = Duration(seconds: 2);
  bool _isFetching = false;
  bool _initialFetchCompleted = false;

  // Filter state tracking
  final RxMap<String, dynamic> lastFilters = <String, dynamic>{}.obs;
  final RxMap<String, List<String>> _cachedFilterData =
      <String, List<String>>{}.obs;

  // Dependencies
  late final ApiService _apiService;
  late final AuthController _authController;
  late Dio _dioClient;

  // Getters
  AuthController get authController => _authController;
  String get relatedProductsEndpoint => ApiConstants.getRelatedProductsEndpoint;

  @override
  void onInit() {
    super.onInit();
    debugPrint(
      '🔄 [ProductController] onInit called - Controller ID: $hashCode',
    );
    _initializeDependencies();
    debugPrint(
      '✅ [ProductController] Controller initialized without data fetching',
    );
  }

  void _initializeDependencies() {
    debugPrint('🔧 [ProductController] Initializing dependencies...');
    _apiService = ApiService();
    _authController =
        Get.isRegistered<AuthController>()
            ? Get.find<AuthController>()
            : Get.put(AuthController());
    final dioProvider = Get.find<DioProvider>();
    _dioClient = dioProvider.client;
    debugPrint(
      '✅ [ProductController] All dependencies initialized successfully',
    );
  }

  Future<void> initializeData() async {
    try {
      debugPrint('🚀 [ProductController] Starting initializeData...');
      isLoading.value = true;
      errorMessage.value = '';
      await Future.wait([fetchProducts(reset: true), _initializeFilterData()]);
      debugPrint('✅ [ProductController] Initialization completed successfully');
    } catch (e) {
      errorMessage.value = 'Initialization error: $e';
      debugPrint('❌ [ProductController] Failed to initialize: $e');
      PopupService.error('failed_to_initialize_data'.tr, title: 'error'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _initializeFilterData() async {
    try {
      final results = await Future.wait([fetchCategories(), fetchLocations()]);
      _cachedFilterData['categories'] = results[0];
      _cachedFilterData['locations'] = results[1];
      debugPrint('✅ [ProductController] Filter data cached');
    } catch (e) {
      debugPrint('⚠️ [ProductController] Failed to cache filter data: $e');
    }
  }

  Future<void> fetchProducts({
    int? page,
    int? pageSizeParam,
    String? searchQuery,
    Set<String>? selectedCategories,
    Set<String>? selectedLocations,
    String? status,
    bool reset = false,
  }) async {
    debugPrint(
      '🔍 [ProductController] fetchProducts called with reset=$reset, page=$page',
    );
    if (!_canFetch()) return;

    _prepareFetch(reset, page);
    try {
      final queryParams = _buildQueryParams(
        page,
        pageSizeParam,
        searchQuery,
        selectedCategories,
        selectedLocations,
        status,
      );
      final options = await _buildRequestOptions(requireAuth: false);
      late Response response; // Initialize with late keyword

      // Enhanced retry logic with exponential backoff
      const maxRetries = 3;

      for (int attempt = 0; attempt < maxRetries; attempt++) {
        try {
          response = await _dioClient.get(
            ApiConstants.getAllProductsEndpoint,
            queryParameters: queryParams,
            options: options,
          );
          break; // Success, exit retry loop
        } on DioException catch (dioErr) {
          if (_isConnectionClosedError(dioErr) && attempt < maxRetries - 1) {
            debugPrint(
              '[ProductController] 🔄 Detected closed Dio adapter – rebuilding and retrying (attempt ${attempt + 1})',
            );
            final provider = Get.find<DioProvider>();
            provider.rebuild(forceClose: true);
            _dioClient = provider.client;
            await Future.delayed(
              Duration(milliseconds: 500 * (attempt + 1)),
            ); // Exponential backoff
            continue;
          }
          rethrow;
        }
      }

      await _handleProductResponse(response, reset, page, pageSizeParam);
      _lastFetchTime = DateTime.now();
      _initialFetchCompleted = true;
    } catch (e, stackTrace) {
      debugPrint('[ProductController] ❌ Exception in fetchProducts: $e');
      _handleFetchError(e, stackTrace);
      _initialFetchCompleted = true;
    } finally {
      _finalizeFetch();
    }
  }

  bool _isConnectionClosedError(DioException e) {
    final msg = e.message?.toLowerCase() ?? '';
    return msg.contains(
          "can't establish a new connection after it was closed",
        ) ||
        msg.contains('connection was disposed') ||
        msg.contains('client is closed');
  }

  bool _canFetch() {
    final now = DateTime.now();
    if (_isFetching || isLoading.value || isLoadingMore.value) {
      debugPrint(
        '[ProductController] ⏳ Already fetching or loading, skipping request',
      );
      return false;
    }

    if (_lastFetchTime != null &&
        now.difference(_lastFetchTime!) < _minFetchInterval) {
      if (errorMessage.value.isNotEmpty && products.isEmpty) {
        debugPrint('[ProductController] ⚡ Bypassing rate limit after failure');
      } else {
        debugPrint('[ProductController] ⏱️ Rate limit hit');
        return false;
      }
    }
    return true;
  }

  bool get hasCompletedInitialFetch => _initialFetchCompleted;

  void _prepareFetch(bool reset, int? page) {
    _isFetching = true;
    _lastFetchTime = DateTime.now();
    if (reset) {
      products.clear();
      filteredProducts.clear();
      currentPage = 1;
      isLastPage = false;
      hasMore.value = true;
    }
    isLoading.value = page == null || page == 1;
    isLoadingMore.value = page != null && page > 1;
    errorMessage.value = '';
  }

  Map<String, dynamic> _buildQueryParams(
    int? page,
    int? pageSizeParam,
    String? searchQuery,
    Set<String>? selectedCategories,
    Set<String>? selectedLocations,
    String? status,
  ) {
    final role =
        _authController.currentUser.value?.role.toLowerCase() ?? 'guest';
    String statusParam = status ?? 'all';
    if (role == 'buyer' || role == 'guest') statusParam = 'active';

    return {
      'page': page ?? currentPage,
      'pageSize': pageSizeParam ?? pageSize,
      if (searchQuery != null && searchQuery.isNotEmpty) 'search': searchQuery,
      if (selectedCategories != null && selectedCategories.isNotEmpty)
        'categories': selectedCategories.join(','),
      if (selectedLocations != null && selectedLocations.isNotEmpty)
        'locations': selectedLocations.join(','),
      if (statusParam != 'all') 'status': statusParam,
    };
  }

  Future<Options> _buildRequestOptions({bool requireAuth = false}) async {
    if (!requireAuth) return Options();
    final token = await TokenService.getAccessToken();
    final role =
        _authController.currentUser.value?.role.toLowerCase() ?? 'guest';
    if (token != null && role != 'guest') {
      return Options(headers: {'Authorization': 'Bearer $token'});
    }
    return Options();
  }

  Future<void> _handleProductResponse(
    Response response,
    bool reset,
    int? page,
    int? pageSizeParam,
  ) async {
    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
    if (response.data == null || response.data['data'] == null) {
      throw Exception('Invalid response structure');
    }

    final List<dynamic> data = response.data['data'] ?? [];
    final List<Product> fetchedProducts =
        data.map((json) => Product.fromJson(json)).toList();

    if (reset || (page ?? currentPage) == 1) {
      products.assignAll(fetchedProducts);
    } else {
      products.addAll(fetchedProducts);
    }

    hasMore.value = fetchedProducts.length == (pageSizeParam ?? pageSize);
    if (hasMore.value) {
      currentPage = (page ?? currentPage) + 1;
    } else {
      isLastPage = true;
    }

    updateFilteredProducts();
    lastSuccessfulFetch = DateTime.now();
  }

  void _handleFetchError(dynamic e, StackTrace stackTrace) {
    errorMessage.value = 'Exception: $e';
    debugPrint('[ProductController] ❌ Error fetching products: $e');
    debugPrint('[ProductController] Stack trace: $stackTrace');
    PopupService.error(
      'error_fetching_products_details'.trArgs([e.toString()]),
    );
  }

  void _finalizeFetch() {
    isLoading.value = false;
    isLoadingMore.value = false;
    _isFetching = false;
  }

  void updateFilteredProducts() {
    if (products.isEmpty && lastSuccessfulFetch == null) {
      filteredProducts.clear();
      return;
    }

    final role =
        _authController.currentUser.value?.role.toLowerCase() ?? 'guest';
    final fc =
        Get.isRegistered<FilterController>()
            ? Get.find<FilterController>()
            : null;
    final statusFilter =
        fc?.selectedStatus.value ??
        (role == 'buyer' || role == 'guest' ? 'active' : 'all');
    final search = fc?.productSearchQuery.value.trim().toLowerCase() ?? '';
    final selectedCategories = fc?.selectedCategories.toSet() ?? <String>{};
    final selectedLocations = fc?.selectedLocations.toSet() ?? <String>{};

    final filtered =
        products.where((product) {
          return _matchesAllFilters(
            product,
            role,
            statusFilter,
            search,
            selectedCategories,
            selectedLocations,
          );
        }).toList();

    filteredProducts.assignAll(filtered);
  }

  bool _matchesAllFilters(
    Product product,
    String role,
    String statusFilter,
    String search,
    Set<String> selectedCategories,
    Set<String> selectedLocations,
  ) {
    return _matchesStatus(product, statusFilter, role) &&
        _matchesSearch(product, search) &&
        _matchesCategory(product, selectedCategories) &&
        _matchesLocation(product, selectedLocations);
  }

  bool _matchesStatus(Product product, String statusFilter, String role) {
    if (statusFilter == 'all') return true;
    if (role == 'buyer' && product.isActive == true) return true;
    if (statusFilter == 'active' && product.isActive == true) return true;
    if (statusFilter == 'inactive' && product.isActive == false) return true;
    return false;
  }

  bool _matchesSearch(Product product, String search) {
    if (search.isEmpty) return true;
    return product.productName.toLowerCase().contains(search) ||
        product.description.toLowerCase().contains(search) ||
        (product.location?.toLowerCase().contains(search) ?? false);
  }

  bool _matchesCategory(Product product, Set<String> selectedCategories) {
    if (selectedCategories.isEmpty) return true;
    final productCategory = product.category.toLowerCase().trim();
    return selectedCategories.any((cat) => productCategory.contains(cat));
  }

  bool _matchesLocation(Product product, Set<String> selectedLocations) {
    if (selectedLocations.isEmpty) return true;
    final productLocation = (product.location ?? '').toLowerCase().trim();
    return selectedLocations.any((loc) => productLocation.contains(loc));
  }

  Future<List<String>> fetchCategories({bool silent = false}) async {
    if (_cachedFilterData.containsKey('categories') &&
        _isCacheValid('categories')) {
      return _cachedFilterData['categories']!;
    }
    return await _fetchWithRetry(
      'categories',
      () => _extractUniqueValues('category'),
      silent ? '' : 'trying_to_fetch_categories_please_wait'.tr,
      'failed_to_load_categories'.tr,
      silent: silent,
    );
  }

  Future<List<String>> fetchLocations({
    String? query,
    int limit = 10,
    bool silent = false,
  }) async {
    if (_cachedFilterData.containsKey('locations') &&
        _isCacheValid('locations')) {
      return _filterLocations(_cachedFilterData['locations']!, query, limit);
    }
    final locations = await _fetchWithRetry(
      'locations',
      () => _extractUniqueValues('location'),
      silent ? '' : 'trying_to_fetch_locations_please_wait'.tr,
      'failed_to_load_locations'.tr,
      silent: silent,
    );
    return _filterLocations(locations, query, limit);
  }

  List<String> _filterLocations(
    List<String> locations,
    String? query,
    int limit,
  ) {
    if (query != null && query.isNotEmpty) {
      return locations
          .where((loc) => loc.toLowerCase().contains(query.toLowerCase()))
          .take(limit)
          .toList();
    }
    return locations.take(limit).toList();
  }

  bool _isCacheValid(String key) {
    return lastSuccessfulFetch != null &&
        DateTime.now().difference(lastSuccessfulFetch!) <
            const Duration(minutes: 5);
  }

  Future<List<String>> _fetchWithRetry(
    String dataType,
    Future<List<String>> Function() fetcher,
    String loadingMessage,
    String errorMessage, {
    bool silent = false,
  }) async {
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 2);
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        if (!silent && loadingMessage.isNotEmpty) {
          PopupService.info(loadingMessage, title: 'loading_$dataType'.tr);
        }
        final result = await fetcher();
        _cachedFilterData[dataType] = result;
        return result;
      } catch (e) {
        if (attempt == maxRetries - 1) {
          if (!silent) {
            PopupService.error(
              'please_check_your_internet_connection'.tr,
              title: errorMessage,
            );
          }
          return [];
        }
        await Future.delayed(retryDelay);
      }
    }
    return [];
  }

  Future<List<String>> _extractUniqueValues(String field) async {
    final response = await http.get(
      Uri.parse(ApiConstants.getAllProductsEndpoint),
    );
    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
    final responseBody = jsonDecode(response.body);
    if (responseBody['success'] != true || responseBody['data'] == null) {
      throw Exception(responseBody['message'] ?? 'Failed to parse $field');
    }
    return (responseBody['data'] as List)
        .map((item) => (item[field] ?? '').toString().trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  Future<void> fetchNearbyProducts(double latitude, double longitude) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final endpoint =
          '${ApiConstants.baseUrl}/api/Product/getNearProducts/$latitude,$longitude';
      final options = await _buildRequestOptions(requireAuth: false);
      final response = await _dioClient.get(endpoint, options: options);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        final List<Product> fetchedProducts =
            data.map((json) => Product.fromJson(json)).toList();
        fetchedProducts.sort(
          (a, b) => (a.distance ?? double.infinity).compareTo(
            b.distance ?? double.infinity,
          ),
        );
        products.assignAll(fetchedProducts);
        updateFilteredProducts();
        PopupService.success(
          'Found ${fetchedProducts.length} nearby product${fetchedProducts.length == 1 ? '' : 's'}',
        );
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      errorMessage.value = 'Exception: $e';
      PopupService.error('Failed to load nearby products');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchRelatedProducts(String productId) async {
    isRelatedLoading.value = true;
    relatedErrorMessage.value = '';
    try {
      final response = await http.get(
        Uri.parse('$relatedProductsEndpoint/$productId'),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          relatedProducts.assignAll(
            List<Product>.from(
              (body['data'] as List).map((item) => Product.fromJson(item)),
            ),
          );
        } else {
          relatedErrorMessage.value = 'no_related_products_found'.tr;
        }
      } else {
        relatedErrorMessage.value = 'failed_to_load_related_products'.tr;
      }
    } catch (e) {
      relatedErrorMessage.value = e.toString();
      debugPrint('❌ [ProductController] Error fetching related products: $e');
    } finally {
      isRelatedLoading.value = false;
    }
  }

  Future<void> loadProductReviews(String productId) async {
    try {
      reviewsModel.clear();
      errorMessage.value = '';
      isLoadingReviews.value = true;
      final fetchedReviews = await _apiService.getReviews(productId);
      reviewsModel.assignAll(fetchedReviews);
    } catch (e) {
      errorMessage.value = 'failed_to_load_reviews'.tr;
      debugPrint('❌ [ProductController] Failed to load reviews: $e');
    } finally {
      isLoadingReviews.value = false;
    }
  }

  Future<void> submitReview({
    required String productId,
    required String reviewText,
    required String username,
  }) async {
    if (!_authController.isLoggedIn) {
      PopupService.info(
        'please_login_to_submit_review'.tr,
        title: 'login_required'.tr,
      );
      return;
    }

    // Check if user has already submitted a review for this product
    final currentUserId = _authController.currentUser.value?.id ?? '';
    final hasExistingReview = reviewsModel.any(
      (review) =>
          review.userId == currentUserId && review.productId == productId,
    );

    if (hasExistingReview) {
      PopupService.warning(
        'you_have_already_reviewed_this_product'.tr,
        title: 'duplicate_review'.tr,
      );
      return;
    }

    if (reviewText.trim().isEmpty) {
      PopupService.error('review_cannot_be_empty'.tr);
      return;
    }
    if (reviewText.length > 200) {
      PopupService.error('review_too_long_max_200_chars'.tr);
      return;
    }

    final review = ReviewModel(
      productId: productId,
      userId: _authController.currentUser.value?.id ?? '',
      username: username,
      review: reviewText,
      timestamp: DateTime.now(),
    );

    try {
      await _apiService.submitReview(review);
      reviewsModel.insert(0, review);
      PopupService.showSnackbar(
        title: 'success'.tr,
        type: PopupType.success,
        message: 'review_added_successfully'.tr,
      );
    } catch (e) {
      _handleReviewSubmissionError(e);
    }
  }

  void _handleReviewSubmissionError(dynamic e) {
    String errorMsg = 'review_submission_failed'.tr;
    if (_authController.currentUser.value?.role.toLowerCase() == 'farmer') {
      errorMsg = 'farmers_cannot_add_reviews'.tr;
    } else if (e is DioException &&
        e.response?.data['message']?.toString().toLowerCase().contains(
              'offensive',
            ) ==
            true) {
      errorMsg = 'review_contains_offensive_words'.tr;
    }
    PopupService.error(errorMsg);
    debugPrint('❌ [ProductController] Review submission failed: $e');
  }

  Future<void> deleteReview(String reviewId) async {
    if (!_authController.isLoggedIn) {
      PopupService.info(
        'please_login_to_delete_review'.tr,
        title: 'login_required'.tr,
      );
      return;
    }

    try {
      await _apiService.deleteReview(reviewId);
      // Remove from local list
      reviewsModel.removeWhere((review) => review.id == reviewId);
      PopupService.showSnackbar(
        title: 'success'.tr,
        type: PopupType.success,
        message: 'review_deleted_successfully'.tr,
      );
    } catch (e) {
      PopupService.error('failed_to_delete_review'.tr);
      debugPrint('❌ [ProductController] Review deletion failed: $e');
    }
  }

  Future<void> updateReview(String reviewId, String newReviewText) async {
    if (!_authController.isLoggedIn) {
      PopupService.info(
        'please_login_to_update_review'.tr,
        title: 'login_required'.tr,
      );
      return;
    }

    if (newReviewText.trim().isEmpty) {
      PopupService.error('review_cannot_be_empty'.tr);
      return;
    }

    if (newReviewText.length > 200) {
      PopupService.error('review_too_long_max_200_chars'.tr);
      return;
    }

    try {
      await _apiService.updateReview(reviewId, newReviewText);

      // Update in local list
      final index = reviewsModel.indexWhere((review) => review.id == reviewId);
      if (index != -1) {
        final updatedReview = ReviewModel(
          id: reviewsModel[index].id,
          productId: reviewsModel[index].productId,
          userId: reviewsModel[index].userId,
          username: reviewsModel[index].username,
          review: newReviewText,
          timestamp: DateTime.now(),
          isApproved: reviewsModel[index].isApproved,
        );
        reviewsModel[index] = updatedReview;
      }

      PopupService.showSnackbar(
        title: 'success'.tr,
        type: PopupType.success,
        message: 'review_updated_successfully'.tr,
      );
    } catch (e) {
      PopupService.error('failed_to_update_review'.tr);
      debugPrint('❌ [ProductController] Review update failed: $e');
    }
  }

  void addToCart(Product product) {
    if (!authController.isLoggedIn) {
      PopupService.info(
        'please_login_to_add_to_cart'.tr,
        title: 'login_required'.tr,
      );
      return;
    }
    final cartController =
        Get.isRegistered<CartController>()
            ? Get.find<CartController>()
            : Get.put(CartController());
    try {
      cartController.addProductWithReference(product);
    } catch (e) {
      PopupService.error('Failed to add product to cart: $e');
    }
  }

  void initiateCheckout(Product product) {
    if (!authController.isLoggedIn) {
      PopupService.info(
        'please_login_to_checkout'.tr,
        title: 'login_required'.tr,
      );
      return;
    }
    PopupService.info(
      'Checkout coming soon!',
      title: 'Feature Under Development',
    );
  }

  Future<void> refreshAll() async {
    try {
      isLoading.value = true;
      _cachedFilterData.clear();
      await Future.wait([
        fetchProducts(reset: true),
        fetchCategories(),
        fetchLocations(),
      ]);
      PopupService.success('Data refreshed successfully');
    } catch (e) {
      errorMessage.value = 'Refresh failed: $e';
      PopupService.error('Failed to refresh: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void clearReviews() {
    reviewsModel.clear();
    errorMessage.value = '';
    isLoadingReviews.value = false;
  }

  @override
  void onClose() {
    // Avoid closing Dio instance here as it's managed by DioProvider
    super.onClose();
  }
}
