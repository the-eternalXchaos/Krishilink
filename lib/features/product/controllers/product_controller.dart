import 'dart:convert';
import 'package:api_sdk/api_sdk.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:http/http.dart' as http;
// Avoid hard dependency to prevent DI cycles; only use type and resolve lazily when needed.
import 'package:krishi_link/src/features/product/presentation/controllers/filter_controller.dart';

import 'package:krishi_link/core/lottie/pop_up.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/features/admin/models/product_model.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/auth/controller/cart_controller.dart';
import 'package:krishi_link/models/review_model.dart';
import 'package:krishi_link/services/api_services/api_service.dart';
import 'package:krishi_link/src/core/networking/dio_provider.dart';
import 'package:krishi_link/services/token_service.dart';

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
  bool _initialFetchCompleted =
      false; // Track whether first attempt finished (success or fail)

  // Filter state tracking
  final RxMap<String, dynamic> lastFilters = <String, dynamic>{}.obs;
  final RxMap<String, List<String>> _cachedFilterData =
      <String, List<String>>{}.obs;

  // Dependencies (FilterController resolved lazily to avoid cycles)
  late final ApiService _apiService;
  late final AuthController _authController;
  late Dio _dioClient;

  // Getters
  AuthController get authController {
    debugPrint(
      '🔐 [ProductController] AuthController accessed - Current login status: ${_authController.isLoggedIn}',
    );
    return _authController;
  }

  String get relatedProductsEndpoint => ApiConstants.getRelatedProductsEndpoint;

  @override
  void onInit() {
    super.onInit();
    debugPrint(
      '🔄 [ProductController] onInit called - Controller ID: ${hashCode}',
    );
    _initializeDependencies();

    // DON'T automatically fetch data in onInit to avoid unnecessary API calls
    // Data will be fetched only when explicitly requested by UI components
    debugPrint(
      '✅ [ProductController] Controller initialized without data fetching',
    );
  }

  void _initializeDependencies() {
    debugPrint('🔧 [ProductController] Initializing dependencies...');

    _apiService = ApiService();
    debugPrint('✅ [ProductController] ApiService initialized');

    _authController =
        Get.isRegistered<AuthController>()
            ? Get.find<AuthController>()
            : Get.put(AuthController());
    debugPrint(
      '✅ [ProductController] AuthController initialized - User logged in: ${_authController.isLoggedIn}',
    );

    // Use central DioProvider (lazy singleton with fenix). This prevents stale
    // instances while still allowing rebuild via provider.rebuild().
    final dioProvider = Get.find<DioProvider>();
    _dioClient = dioProvider.client;
    debugPrint('✅ [ProductController] Dio client obtained from DioProvider');

    debugPrint(
      '🎯 [ProductController] All dependencies initialized successfully',
    );
  }

  Future<void> initializeData() async {
    try {
      debugPrint('🚀 [ProductController] Starting initializeData...');
      isLoading.value = true;
      errorMessage.value = '';

      debugPrint(
        '🔄 [ProductController] About to call fetchProducts and _initializeFilterData in parallel',
      );

      // Parallel initialization for better performance
      await Future.wait([fetchProducts(reset: true), _initializeFilterData()]);

      debugPrint('✅ [ProductController] Initialization completed successfully');
      debugPrint(
        '📊 [ProductController] Final products count: ${products.length}',
      );
      debugPrint(
        '📋 [ProductController] Final filtered products count: ${filteredProducts.length}',
      );
    } catch (e) {
      errorMessage.value = 'Initialization error: $e';
      debugPrint('❌ [ProductController] Failed to initialize: $e');
      debugPrint('❌ [ProductController] Error type: ${e.runtimeType}');
      PopupService.error('failed_to_initialize_data'.tr, title: 'error'.tr);
    } finally {
      isLoading.value = false;
      debugPrint(
        '🏁 [ProductController] initializeData completed. Loading: ${isLoading.value}',
      );
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

  // fetchProducts
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

    if (!_canFetch()) {
      debugPrint(
        '❌ [ProductController] _canFetch returned false, exiting early',
      );
      return;
    }

    debugPrint('✅ [ProductController] _canFetch passed, proceeding with fetch');
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

      final options = await _buildRequestOptions(
        requireAuth: false,
      ); // Public endpoint

      debugPrint(
        '[ProductController] 🚀 Making API call to: ${ApiConstants.getAllProductsEndpoint}',
      );
      debugPrint('[ProductController] 📡 Request params: $queryParams');
      debugPrint(
        '[ProductController] 🔐 Request options headers: ${options.headers}',
      );

      Response response;
      try {
        response = await _dioClient.get(
          ApiConstants.getAllProductsEndpoint,
          queryParameters: queryParams,
          options: options,
        );
      } on DioException catch (dioErr) {
        // Handle specific closed-connection scenario: rebuild Dio then retry once.
        final msg = dioErr.message ?? '';
        final isClosedConn =
            msg.contains(
              "can't establish a new connection after it was closed",
            ) ||
            msg.toLowerCase().contains('connection was disposed') ||
            msg.toLowerCase().contains('client is closed');
        if (isClosedConn) {
          debugPrint(
            '[ProductController] 🔄 Detected closed Dio adapter – rebuilding and retrying once',
          );
          try {
            final provider = Get.find<DioProvider>();
            provider.rebuild(forceClose: true);
            _dioClient = provider.client;
            response = await _dioClient.get(
              ApiConstants.getAllProductsEndpoint,
              queryParameters: queryParams,
              options: options,
            );
          } catch (retryErr, st) {
            debugPrint(
              '[ProductController] ❌ Retry after rebuild failed: $retryErr',
            );
            debugPrint('[ProductController] Retry stack: $st');
            rethrow; // Bubble to outer catch
          }
        } else {
          rethrow; // Not a closed-connection case; let outer catch handle it.
        }
      }

      debugPrint(
        '[ProductController] 📥 Response received with status: ${response.statusCode}',
      );
      debugPrint(
        '[ProductController] 📊 Response data type: ${response.data?.runtimeType}',
      );

      await _handleProductResponse(response, reset, page, pageSizeParam);
      // Mark last fetch time only on success so failed attempts can be retried quickly
      _lastFetchTime = DateTime.now();
      _initialFetchCompleted = true;
    } catch (e, stackTrace) {
      debugPrint('[ProductController] ❌ Exception in fetchProducts: $e');
      debugPrint('[ProductController] 📚 Exception type: ${e.runtimeType}');
      _handleFetchError(e, stackTrace);
      _initialFetchCompleted = true; // attempt finished even if failed
    } finally {
      _finalizeFetch();
      debugPrint('[ProductController] 🏁 fetchProducts completed');
    }
  }

  bool _canFetch() {
    final now = DateTime.now();

    debugPrint('[ProductController] 🔍 Checking if can fetch...');
    debugPrint(
      '[ProductController] 📊 Current state: _isFetching=$_isFetching, isLoading=${isLoading.value}, isLoadingMore=${isLoadingMore.value}',
    );

    if (_isFetching) {
      debugPrint('[ProductController] ⏳ Already fetching, skipping request');
      return false;
    }

    if (_lastFetchTime != null) {
      final since = now.difference(_lastFetchTime!);
      if (since < _minFetchInterval) {
        final hasError = errorMessage.value.isNotEmpty;
        final noData = products.isEmpty;
        if (hasError && noData) {
          debugPrint(
            '[ProductController] ⚡ Bypassing rate limit after failure (elapsed ${since.inMilliseconds}ms)',
          );
        } else {
          debugPrint(
            '[ProductController] ⏱️ Rate limit: ${since.inMilliseconds}ms < ${_minFetchInterval.inMilliseconds}ms',
          );
          return false;
        }
      }
    }

    if (isLoading.value || isLoadingMore.value) {
      debugPrint('[ProductController] ⏳ Already loading, skipping request');
      return false;
    }

    debugPrint('[ProductController] ✅ Can fetch - all checks passed');
    return true;
  }

  // Public helper for UI to know if we attempted at least one load
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

    // Force active status for buyers and guests
    if (role == 'buyer' || role == 'guest') {
      statusParam = 'active';
    }

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
    // For public endpoints (getAllProducts, getNearProducts), we don't require authentication
    // For private endpoints (user-specific operations), we do require authentication
    if (!requireAuth) {
      debugPrint(
        '[ProductController] 📄 Building request options without authentication for public endpoint',
      );
      return Options();
    }

    final token = await TokenService.getAccessToken();
    final role =
        _authController.currentUser.value?.role.toLowerCase() ?? 'guest';

    debugPrint(
      '[ProductController] � Building request options with authentication for private endpoint',
    );
    debugPrint(
      '[ProductController] 👤 User role: $role, Token available: ${token != null}',
    );

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
    debugPrint(
      '[ProductController] 📊 Processing response with status: ${response.statusCode}',
    );

    if (response.statusCode != 200) {
      debugPrint(
        '[ProductController] ❌ Non-200 status code: ${response.statusCode}',
      );
      throw Exception('Server error: ${response.statusCode}');
    }

    debugPrint('[ProductController] 📄 Raw response data: ${response.data}');

    if (response.data == null) {
      debugPrint('[ProductController] ❌ Response data is null');
      throw Exception('No data received from server');
    }

    if (response.data['data'] == null) {
      debugPrint('[ProductController] ❌ Response data["data"] is null');
      debugPrint(
        '[ProductController] 📄 Full response structure: ${response.data}',
      );
      throw Exception('Invalid response structure - missing data field');
    }

    final List<dynamic> data = response.data['data'] ?? [];
    debugPrint('[ProductController] 📋 Data array length: ${data.length}');

    if (data.isEmpty) {
      debugPrint('[ProductController] ⚠️ No products returned from API');
    } else {
      debugPrint('[ProductController] 📦 First product sample: ${data.first}');
    }

    final List<Product> fetchedProducts =
        data.map((json) => Product.fromJson(json)).toList();

    debugPrint(
      '[ProductController] ✅ Products parsed successfully: ${fetchedProducts.length}',
    );

    // Update products list
    if (reset || (page ?? currentPage) == 1) {
      products.assignAll(fetchedProducts);
      debugPrint(
        '[ProductController] 🔄 Products list reset/assigned with ${fetchedProducts.length} items',
      );
    } else {
      products.addAll(fetchedProducts);
      debugPrint(
        '[ProductController] ➕ Products added to list, total: ${products.length}',
      );
    }

    // Update pagination state
    hasMore.value = fetchedProducts.length == (pageSizeParam ?? pageSize);
    if (hasMore.value) {
      currentPage = (page ?? currentPage) + 1;
    } else {
      isLastPage = true;
    }

    debugPrint(
      '[ProductController] 📊 Pagination state: hasMore=${hasMore.value}, currentPage=$currentPage',
    );

    // Update filtered products
    debugPrint('[ProductController] 🔍 Calling updateFilteredProducts...');
    updateFilteredProducts();
    debugPrint(
      '[ProductController] 🔍 After filtering: ${filteredProducts.length} products',
    );

    lastSuccessfulFetch = DateTime.now();
    debugPrint(
      '[ProductController] ✅ Product response handling completed successfully',
    );
  }

  void _handleFetchError(dynamic e, StackTrace stackTrace) {
    errorMessage.value = 'Exception: $e';
    debugPrint('[ProductController] ❌ Error fetching products: $e');
    debugPrint('[ProductController] Stack trace: $stackTrace');

    _showErrorSnackbar(
      'error_fetching_products_details'.trArgs([e.toString()]),
    );
  }

  void _finalizeFetch() {
    isLoading.value = false;
    isLoadingMore.value = false;
    _isFetching = false;
  }

  // Enhanced updateFilteredProducts with better performance
  void updateFilteredProducts() {
    if (products.isEmpty) {
      // Don't clear filteredProducts if we recently had a successful fetch
      // This prevents race conditions between multiple controller instances
      final hasRecentSuccess =
          lastSuccessfulFetch != null &&
          DateTime.now().difference(lastSuccessfulFetch!) <
              Duration(seconds: 30);

      if (!hasRecentSuccess && filteredProducts.isNotEmpty) {
        filteredProducts.clear();
        debugPrint(
          '📋 [ProductController] No products to filter, clearing filtered list',
        );
      } else if (hasRecentSuccess) {
        debugPrint(
          '📋 [ProductController] Products empty but recent fetch success - keeping filtered list',
        );
      }
      return;
    }

    debugPrint('[ProductController] 🔍 Filtering ${products.length} products');

    final role =
        _authController.currentUser.value?.role.toLowerCase() ?? 'guest';
    debugPrint('[ProductController] 👤 User role: $role');

    FilterController? fc;
    try {
      fc = Get.find<FilterController>();
      debugPrint('[ProductController] ✅ FilterController found');
    } catch (_) {
      fc = null;
      debugPrint(
        '[ProductController] ⚠️ FilterController not found, using defaults',
      );
    }
    final statusFilter =
        fc?.selectedStatus.value ??
        (role == 'buyer' || role == 'guest' ? 'active' : 'all');
    final search = fc?.productSearchQuery.value.trim().toLowerCase() ?? '';
    final selectedCategories = fc?.selectedCategories.toSet() ?? <String>{};
    final selectedLocations = fc?.selectedLocations.toSet() ?? <String>{};

    debugPrint('[ProductController] 🔧 Filter parameters:');
    debugPrint('[ProductController]   - Status: $statusFilter');
    debugPrint(
      '[ProductController]   - Search: "${search.isEmpty ? 'None' : search}"',
    );
    debugPrint(
      '[ProductController]   - Categories: ${selectedCategories.isEmpty ? 'All' : selectedCategories.join(', ')}',
    );
    debugPrint(
      '[ProductController]   - Locations: ${selectedLocations.isEmpty ? 'All' : selectedLocations.join(', ')}',
    );

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
    debugPrint(
      '[ProductController] ✅ Filtered products: ${filteredProducts.length}/${products.length} products match filters',
    );

    // Log cart-relevant info
    if (authController.isLoggedIn) {
      debugPrint(
        '[ProductController] 🛒 User logged in - cart functionality available for ${filteredProducts.length} products',
      );
    } else {
      debugPrint(
        '[ProductController] 🔒 User not logged in - cart functionality disabled',
      );
    }
  }

  bool _matchesAllFilters(
    Product product,
    String role,
    String statusFilter,
    String search,
    Set<String> selectedCategories,
    Set<String> selectedLocations,
  ) {
    // Status filter
    final matchesStatus = _matchesStatus(product, statusFilter, role);
    if (!matchesStatus) return false;

    // Search filter
    final matchesSearch = _matchesSearch(product, search);
    if (!matchesSearch) return false;

    // Category filter
    final matchesCategory = _matchesCategory(product, selectedCategories);
    if (!matchesCategory) return false;

    // Location filter
    final matchesLocation = _matchesLocation(product, selectedLocations);
    if (!matchesLocation) return false;

    return true;
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

  // Enhanced category fetching with caching
  Future<List<String>> fetchCategories({bool silent = false}) async {
    // Return cached data if available and recent
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

  // Enhanced location fetching with caching
  Future<List<String>> fetchLocations({
    String? query,
    int limit = 10,
    bool silent = false,
  }) async {
    // Return cached data if available and recent
    if (_cachedFilterData.containsKey('locations') &&
        _isCacheValid('locations')) {
      final locations = _cachedFilterData['locations']!;
      return _filterLocations(locations, query, limit);
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
    // Simple cache validity check - could be enhanced with timestamps
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
        if (attempt < 1 && !silent && loadingMessage.isNotEmpty) {
          PopupService.info(loadingMessage, title: 'loading_$dataType'.tr);
        }

        final result = await fetcher();
        _cachedFilterData[dataType] = result;

        if (attempt > 0) {
          PopupService.success(
            '${dataType}_loaded_successfully_after_retrying'.tr,
          );
        }

        return result;
      } catch (e) {
        if (attempt == maxRetries - 1) {
          PopupService.error(
            'please_check_your_internet_connection'.tr,
            title: errorMessage,
          );
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

    final List<dynamic> data = responseBody['data'];
    return data
        .map((item) => (item[field] ?? '').toString().trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  // Enhanced nearby products with better error handling
  Future<void> fetchNearbyProducts(double latitude, double longitude) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final endpoint =
          '${ApiConstants.baseUrl}/api/Product/getNearProducts/$latitude,$longitude';
      debugPrint(
        '[ProductController] 📍 Fetching nearby products from $endpoint',
      );

      final options = await _buildRequestOptions(
        requireAuth: false,
      ); // Public endpoint
      final response = await _dioClient.get(endpoint, options: options);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        final List<Product> fetchedProducts =
            data.map((json) => Product.fromJson(json)).toList();

        // Sort by distance if available
        fetchedProducts.sort(
          (a, b) => (a.distance ?? double.infinity).compareTo(
            b.distance ?? double.infinity,
          ),
        );

        products.assignAll(fetchedProducts);
        updateFilteredProducts();

        PopupService.success(
          'Found ${fetchedProducts.length} nearby product${fetchedProducts.length == 1 ? '' : 's'}',
          title: 'Nearby Products',
        );
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      errorMessage.value = 'Exception: $e';
      _showErrorSnackbar('Failed to load nearby products');
    } finally {
      isLoading.value = false;
    }
  }

  // Enhanced related products fetching
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

  // Enhanced review methods
  Future<void> loadProductReviews(String productId) async {
    try {
      debugPrint(
        '🔄 [ProductController] Loading reviews for product: $productId',
      );

      reviewsModel.clear();
      errorMessage.value = '';
      isLoadingReviews.value = true;

      final fetchedReviews = await _apiService.getReviews(productId);

      debugPrint(
        '✅ [ProductController] Successfully loaded ${fetchedReviews.length} reviews',
      );
      reviewsModel.assignAll(fetchedReviews);
    } catch (e) {
      debugPrint('❌ [ProductController] Failed to load reviews: $e');
      errorMessage.value = 'failed_to_load_reviews'.tr;
    } finally {
      isLoadingReviews.value = false;
    }
  }

  Future<void> submitReview({
    required String productId,
    required String reviewText,
    required String username,
  }) async {
    // Validation
    if (!_authController.isLoggedIn) {
      PopupService.info(
        'please_login_to_submit_review'.tr,
        title: 'login_required'.tr,
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

      // Optimistic update
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
    final role = _authController.currentUser.value?.role.toLowerCase();
    String errorMsg = 'review_submission_failed'.tr;

    if (role == 'farmer') {
      errorMsg = 'farmers_cannot_add_reviews'.tr;
    } else if (e is DioException) {
      final serverMessage =
          e.response?.data['message']?.toString().toLowerCase() ?? '';
      if (serverMessage.contains('offensive')) {
        errorMsg = 'review_contains_offensive_words'.tr;
      }
    }

    PopupService.error(errorMsg);
    debugPrint('❌ [ProductController] Review submission failed: $e');
  }

  // Cart and checkout methods
  void addToCart(Product product) {
    debugPrint(
      '🛒 [ProductController] Starting addToCart process for product: ${product.productName} (ID: ${product.id})',
    );

    if (!authController.isLoggedIn) {
      debugPrint(
        '❌ [ProductController] User not logged in, cannot add to cart',
      );
      PopupService.info(
        'please_login_to_add_to_cart'.tr,
        title: 'login_required'.tr,
      );
      return;
    }

    debugPrint(
      '✅ [ProductController] User is logged in: ${authController.currentUser.value?.fullName ?? authController.currentUser.value?.email ?? "Unknown User"}',
    );
    debugPrint(
      '🔍 [ProductController] Checking for existing CartController...',
    );

    final cartController =
        Get.isRegistered<CartController>()
            ? Get.find<CartController>()
            : Get.put(CartController());

    debugPrint('✅ [ProductController] CartController obtained successfully');
    debugPrint('📦 [ProductController] Adding product to cart with details:');
    debugPrint('   - Product ID: ${product.id}');
    debugPrint('   - Product Name: ${product.productName}');
    debugPrint('   - Rate: ${product.rate}');
    debugPrint('   - Image: ${product.image}');

    try {
      // Use the enhanced method that passes the full Product reference
      cartController.addProductWithReference(product);
      debugPrint(
        '🎉 [ProductController] Successfully called addProductWithReference method',
      );
    } catch (e) {
      debugPrint('❌ [ProductController] Error adding product to cart: $e');
      PopupService.error('Failed to add product to cart: $e');
    }
  }

  void initiateCheckout(Product product) {
    debugPrint(
      '🛍️ [ProductController] Checkout initiated for product: ${product.productName} (ID: ${product.id})',
    );
    debugPrint('💰 [ProductController] Product rate: ₹${product.rate}');

    if (!authController.isLoggedIn) {
      debugPrint(
        '❌ [ProductController] User not logged in, cannot proceed with checkout',
      );
      PopupService.info(
        'please_login_to_checkout'.tr,
        title: 'login_required'.tr,
      );
      return;
    }

    debugPrint(
      '⚠️ [ProductController] Checkout functionality not yet implemented',
    );
    PopupService.info(
      'Checkout coming soon!',
      title: 'Feature Under Development',
    );
    //TODO: Implement checkout logic
  }

  // Utility methods
  Future<void> refreshAll() async {
    try {
      isLoading.value = true;

      // Clear cache to force fresh data
      _cachedFilterData.clear();

      await Future.wait([
        fetchProducts(reset: true),
        fetchCategories(),
        fetchLocations(),
      ]);

      PopupService.success('Data refreshed successfully');
    } catch (e) {
      PopupService.error('Failed to refresh: $e');
      errorMessage.value = 'Refresh failed: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void clearReviews() {
    debugPrint('🧹 [ProductController] Clearing reviews');
    reviewsModel.clear();
    errorMessage.value = '';
    isLoadingReviews.value = false;
  }

  void _showErrorSnackbar(String message) {
    debugPrint('❌ [ProductController] $message');
    PopupService.error(message, title: 'error'.tr);
  }

  // Memory management
  @override
  void onClose() {
    _dioClient.close();
    super.onClose();
  }
}
