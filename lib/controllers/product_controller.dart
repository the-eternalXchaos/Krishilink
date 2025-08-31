import 'dart:convert';
import 'package:api_sdk/api_sdk.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:krishi_link/controllers/filter_controller.dart';
import 'package:krishi_link/core/components/material_ui/popup.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/features/admin/models/product_model.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/models/review_model.dart';
import 'package:krishi_link/services/api_services/api_service.dart';
import 'package:krishi_link/services/token_service.dart';

class ProductController extends GetxController {
  final RxList<Product> products = <Product>[].obs;
  final RxList<Product> relatedProducts = <Product>[].obs;
  final RxList<Map<String, String>> reviews = <Map<String, String>>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  RxList<Product> filteredProducts = <Product>[].obs;
  final RxList<ReviewModel> reviewsModel = <ReviewModel>[].obs;
  final RxBool isLoadingReviews = false.obs;

  // late final FilterController filterController;
  late final FilterController filterController =
      Get.isRegistered()
          ? Get.find<FilterController>()
          : Get.put(FilterController());

  late final ApiService _apiService = ApiService();
  late final AuthController _authController =
      Get.isRegistered()
          ? Get.find<AuthController>()
          : Get.put(AuthController());

  AuthController get authController => _authController;

  // var relatedProducts = <Product>[].obs;
  var isRelatedLoading = false.obs;
  var relatedErrorMessage = ''.obs;
  Options guestOptions() => Options(extra: {'guestAccess': true});

  // Fetch products with pagination and server-side filtering
  int currentPage = 1;
  int pageSize = 20;
  bool isLastPage = false;
  RxBool isLoadingMore = false.obs;
  RxBool hasMore = true.obs;
  RxMap<String, dynamic> lastFilters = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();

    // Future.delayed(Duration.zero, () {
    //   filterController = Get.find<FilterController>();
    // });

    initializeData();
    // ever(filterController.selectedStatus, (_) => updateFilteredProducts());  //TODO: Uncomment this when the filter is implemented
  }

  Future<void> initializeData() async {
    try {
      await fetchProducts();
      await Future.wait([fetchCategories(), fetchLocations()]);
    } catch (e) {
      errorMessage.value = 'Initialization error: $e';
      debugPrint('Failed to initialize data');
      PopupService.error('failed_to_initialize_data'.tr, title: 'error'.tr);
    }
  }

  // Parse products from the API response's data array
  static List<Product> parseProducts(String responseBody) {
    final List<dynamic> data = jsonDecode(responseBody);
    return data.map((json) => Product.fromJson(json)).toList();
  }

  // Fetch all products (for buyer, admin, farmer)
  Future<void> fetchProducts({
    int? page,
    int? pageSizeParam,
    String? searchQuery,
    Set<String>? selectedCategories,
    Set<String>? selectedLocations,
    String? status,
    bool reset = false,
  }) async {
    debugPrint('[ProductController] fetchProducts called with:');
    debugPrint(
      '  page: $page, pageSizeParam: $pageSizeParam, searchQuery: $searchQuery',
    );
    debugPrint(
      '  selectedCategories: $selectedCategories, selectedLocations: $selectedLocations, status: $status, reset: $reset',
    );
    if (isLoading.value || isLoadingMore.value) return;
    if (reset) {
      products.clear();
      currentPage = 1;
      isLastPage = false;
      hasMore.value = true;
    }
    isLoading.value = page == null || page == 1;
    isLoadingMore.value = page != null && page > 1;
    errorMessage.value = '';
    try {
      final Dio dioClient = Dio();
      final token = await TokenService.getAccessToken();
      final role =
          _authController.currentUser.value?.role.toLowerCase() ?? 'guest';
      String statusParam = status ?? 'all';
      if (role == 'buyer' || role == 'guest') {
        statusParam = 'active';
      }
      final queryParams = {
        'page': page ?? currentPage,
        'pageSize': pageSizeParam ?? pageSize,
        if (searchQuery != null && searchQuery.isNotEmpty)
          'search': searchQuery,
        if (selectedCategories != null && selectedCategories.isNotEmpty)
          'categories': selectedCategories.join(','),
        if (selectedLocations != null && selectedLocations.isNotEmpty)
          'locations': selectedLocations.join(','),
        if (statusParam != 'all') 'status': statusParam,
      };
      debugPrint('[ProductController] API queryParams: $queryParams');
      debugPrint(
        '[ProductController] API endpoint:  [32m${ApiConstants.getAllProductsEndpoint} [0m',
      );
      lastFilters.value = queryParams;
      Options options;
      if (token != null) {
        options = Options(headers: {'Authorization': 'Bearer $token'});
      } else {
        options = guestOptions();
      }
      final response = await dioClient.get(
        ApiConstants.getAllProductsEndpoint,
        queryParameters: queryParams,
        options: options,
      );
      debugPrint(
        '[ProductController] API response status: ${response.statusCode}',
      );
      debugPrint('[ProductController] API response data: ${response.data}');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        final List<Product> fetchedProducts =
            data.map((json) => Product.fromJson(json)).toList();
        debugPrint(
          '[ProductController] Products fetched: ${fetchedProducts.length}',
        );
        if (reset || (page ?? currentPage) == 1) {
          products.assignAll(fetchedProducts);
        } else {
          products.addAll(fetchedProducts);
        }
        updateFilteredProducts();
        hasMore.value = fetchedProducts.length == (pageSizeParam ?? pageSize);
        if (hasMore.value) {
          currentPage = (page ?? currentPage) + 1;
        } else {
          isLastPage = true;
        }
      } else {
        errorMessage.value = 'Server error: ${response.statusCode}';
        debugPrint('[ProductController] Server error: ${response.statusCode}');
        _showErrorSnackbar(
          'failed_to_load_products_status'.trArgs([
            response.statusCode.toString(),
          ]),
        );
      }
    } catch (e, stackTrace) {
      errorMessage.value = 'Exception: $e';
      debugPrint('[ProductController] Error fetching products: $e');
      debugPrint('[ProductController] Stack trace: $stackTrace');
      _showErrorSnackbar(
        'error_fetching_products_details'.trArgs([e.toString()]),
      );
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  // Fetch related products by productId
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
          relatedProducts.value = List<Product>.from(
            (body['data'] as List).map((item) => Product.fromJson(item)),
          );
        } else {
          relatedErrorMessage.value = 'No related products found';
        }
      } else {
        relatedErrorMessage.value = 'Failed to load related products';
      }
    } catch (e) {
      relatedErrorMessage.value = e.toString();
    } finally {
      isRelatedLoading.value = false;
    }
  }

  void _showErrorSnackbar(String message) {
    debugPrint(message);
    PopupService.error(message, title: 'error'.tr);
  }

  // //------------------------------------------------

  // ------------------------------------------------------------

  Future<List<String>> fetchCategories() async {
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 3);
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        final response = await http.get(
          Uri.parse(ApiConstants.getAllProductsEndpoint),
        );

        if (response.statusCode == 200) {
          final responseBody = jsonDecode(response.body);
          if (responseBody['success'] == true && responseBody['data'] != null) {
            final List<dynamic> data = responseBody['data'];
            final categories =
                data
                    .map((item) => item['category'].toString())
                    .toSet()
                    .toList();

            if (attempt > 0) {
              debugPrint('Categories loaded successfully after retrying.');
              PopupService.success(
                'categories_loaded_successfully_after_retrying'.tr,
              );
            }

            errorMessage.value = '';
            return categories;
          } else {
            throw Exception(
              responseBody['message'] ?? 'Failed to parse categories',
            );
          }
        } else {
          // Log the error but don't crash
          errorMessage.value =
              'Server responded with status code ${response.statusCode}';
        }
      } catch (e) {
        attempt++;
        errorMessage.value = 'Error fetching categories: $e';

        // Show a loading notification on first error
        if (attempt == 1) {
          debugPrint('Trying to fetch categories. Please wait...');
          PopupService.info(
            'trying_to_fetch_categories_please_wait'.tr,
            title: 'loading_categories'.tr,
          );
        }

        // Retry after delay
        await Future.delayed(retryDelay);
      }
    }

    // If still fails after retries
    debugPrint(
      'Failed to Load Categories. Please check your internet connection.',
    );
    PopupService.error(
      'please_check_your_internet_connection'.tr,
      title: 'failed_to_load_categories'.tr,
    );

    return []; // Return empty list to avoid crash
  }

  // ------------------------------------------------------------
  //Fewtch locations
  Future<List<String>> fetchLocations({String? query, int limit = 10}) async {
    const int maxRetries = 3;
    const retryDelay = Duration(seconds: 2);
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        final response = await http.get(
          Uri.parse(ApiConstants.getAllProductsEndpoint),
        );

        if (response.statusCode == 200) {
          final responseBody = jsonDecode(response.body);
          if (responseBody['success'] == true && responseBody['data'] != null) {
            final List<dynamic> data = responseBody['data'];
            final locations =
                data
                    .map((item) => item['location'].toString())
                    .toSet()
                    .toList();

            final filtered =
                query != null && query.isNotEmpty
                    ? locations
                        .where(
                          (loc) =>
                              loc.toLowerCase().contains(query.toLowerCase()),
                        )
                        .take(limit)
                        .toList()
                    : locations.take(limit).toList();

            errorMessage.value = '';
            return filtered;
          } else {
            throw Exception(
              responseBody['message'] ?? 'Failed to parse locations',
            );
          }
        } else {
          throw Exception('Server error: ${response.statusCode}');
        }
      } catch (e) {
        attempt++;
        errorMessage.value = 'Error fetching locations: $e';
        await Future.delayed(retryDelay);
      }
    }

    debugPrint(
      'Failed to Load Locations. Unable to load location data. Please check your internet.',
    );
    PopupService.error(
      'unable_to_load_location_data_please_check_your_internet'.tr,
      title: 'failed_to_load_locations'.tr,
    );

    return [];
  }

  // Remove updateFilteredProducts and in-memory filtering

  get relatedProductsEndpoint => ApiConstants.getRelatedProductsEndpoint;

  void updateFilteredProducts() {
    debugPrint(
      '[ProductController] Filtering  [32m${products.length} [0m products',
    );
    final role =
        _authController.currentUser.value?.role.toLowerCase() ?? 'guest';
    final statusFilter = filterController.selectedStatus.value;
    final search =
        filterController.productSearchQuery.value.trim().toLowerCase();
    final locationQuery =
        filterController.locationSearchQuery.value.trim().toLowerCase();
    debugPrint('Selected categories: ${filterController.selectedCategories}');
    debugPrint('Selected locations: ${filterController.selectedLocations}');
    filteredProducts.value =
        products
            .where((product) {
              // Status filter
              final matchesStatus =
                  statusFilter == 'all' ||
                  (statusFilter == 'active' && product.isActive == true) ||
                  (statusFilter == 'inactive' && product.isActive == false) ||
                  (role == 'buyer' && product.isActive == true);
              // Search filter (now includes name, description, location)
              final matchesSearch =
                  search.isEmpty ||
                  product.productName.toLowerCase().contains(search) ||
                  (product.description.toLowerCase().contains(search)) ||
                  (product.location?.toLowerCase().contains(search) ?? false);
              // Category filter (partial match)
              final productCategory = product.category.toLowerCase().trim();
              final matchesCategory =
                  filterController.selectedCategories.isEmpty ||
                  filterController.selectedCategories.any(
                    (cat) => productCategory.contains(cat),
                  );
              // Location filter (partial match)
              final productLocation =
                  (product.location ?? '').toLowerCase().trim();
              final matchesLocation =
                  filterController.selectedLocations.isEmpty ||
                  filterController.selectedLocations.any(
                    (loc) => productLocation.contains(loc),
                  );
              if (!matchesCategory) {
                debugPrint(
                  'Filtered out by category: ${product.productName} ($productCategory)',
                );
              }
              if (!matchesLocation) {
                debugPrint(
                  'Filtered out by location: ${product.productName} ($productLocation)',
                );
              }
              return matchesStatus &&
                  matchesSearch &&
                  matchesCategory &&
                  matchesLocation;
            })
            .toList()
            .obs;
    debugPrint(
      '[ProductController] Filtered products:  [32m${filteredProducts.length} [0m',
    );
  }

  Future<void> loadProductReviews(String productId) async {
    try {
      debugPrint(
        '🔄 [ProductController] Loading reviews for product: $productId',
      );

      // Clear previous reviews to prevent showing wrong product's reviews
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

      // Don't show popup for review loading errors - just log them
      // PopupService.info(errorMessage.value);
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
      debugPrint('Please login to submit a review');
      PopupService.info(
        'please_login_to_submit_review'.tr,
        title: 'login_required'.tr,
      );
      return;
    }

    if (reviewText.trim().isEmpty) {
      debugPrint('Review cannot be empty');
      PopupService.error('review_cannot_be_empty'.tr);
      return;
    }

    if (reviewText.length > 200) {
      debugPrint('Review too long (max 200 chars)');
      PopupService.error('review_too_long_max_200_chars'.tr);
      return;
    }

    final review = ReviewModel(
      // id: '',
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

      PopupService.success(
        'review_added_successfully_wait_for_admin_approval'.tr,
      );
    } catch (e) {
      String errorMsg = '';
      final role = _authController.currentUser.value?.role.toLowerCase();
      if (role == 'farmer') {
        errorMsg = 'farmers_cannot_add_reviews'.tr;
        debugPrint('Farmers cannot add reviews.');
      } else if (role == 'buyer') {
        if (e is DioException) {
          final serverMessage =
              e.response?.data['message']?.toString().toLowerCase() ?? '';
          if (serverMessage.contains('offensive')) {
            errorMsg = 'review_contains_offensive_words'.tr;
            debugPrint('Review contains offensive words.');
          } else {
            errorMsg = 'review_submission_failed'.tr;
            debugPrint('Review submission failed: $serverMessage');
          }
        } else {
          errorMsg = 'review_submission_failed'.tr;
          debugPrint('Review submission failed: $e');
        }
      } else {
        errorMsg = 'review_submission_failed'.tr;
        debugPrint('Review submission failed: $e');
      }
      PopupService.error(errorMsg);
    }
  }

  void addToCart(Product product) {
    // Implement cart logic TODO Add the cart logic

    PopupService.success('added_to_cart'.tr);
  }

  void initiateCheckout(Product product) {
    //TODO Implement checkout logic
  }

  Future<void> refreshAll() async {
    try {
      await fetchProducts();
      await fetchCategories();
      await fetchLocations();
    } catch (e) {
      PopupService.error('Failed to Refresh: $e');
      errorMessage.value = 'Refresh failed: $e';
    }
  }

  Future<void> fetchNearbyProducts(double latitude, double longitude) async {
    try {
      isLoading.value = true;
      final Dio dioClient = Dio();
      final token = await TokenService.getAccessToken();
      final endpoint =
          '${ApiConstants.baseUrl}/api/Product/getNearProducts/$latitude,$longitude';
      debugPrint('[ProductController] Fetching nearby products from $endpoint');
      final response = await dioClient.get(
        endpoint,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        final List<Product> fetchedProducts =
            data.map((json) => Product.fromJson(json)).toList();
        // Sort by distance if available
        fetchedProducts.sort(
          (a, b) => ((a.distance ?? double.infinity).compareTo(
            b.distance ?? double.infinity,
          )),
        );
        products.assignAll(fetchedProducts);
        updateFilteredProducts();
        PopupService.success(
          'Found ${fetchedProducts.length} nearby product${fetchedProducts.length == 1 ? '' : ' s'}',
          title: 'Nearby Products',
        );
      } else {
        errorMessage.value = 'Server error: ${response.statusCode}';
        _showErrorSnackbar('Failed to load nearby products');
      }
    } catch (e) {
      errorMessage.value = 'Exception: $e';
      _showErrorSnackbar('Failed to load nearby products');
    } finally {
      isLoading.value = false;
    }
  }

  // Clear reviews when switching products or on errors
  void clearReviews() {
    debugPrint('🧹 [ProductController] Clearing reviews');
    reviewsModel.clear();
    errorMessage.value = '';
    isLoadingReviews.value = false;
  }
}
