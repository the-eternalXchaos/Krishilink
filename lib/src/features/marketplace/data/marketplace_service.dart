import 'package:krishi_link/src/core/networking/base_service.dart';
import 'package:krishi_link/features/admin/models/product_model.dart';

class ProductsRequest {
  final int page;
  final int pageSize;
  final String? searchQuery;
  final List<String>? categories;
  final List<String>? locations;
  final String? status;
  final double? latitude;
  final double? longitude;
  final double? radius;

  ProductsRequest({
    this.page = 1,
    this.pageSize = 20,
    this.searchQuery,
    this.categories,
    this.locations,
    this.status,
    this.latitude,
    this.longitude,
    this.radius,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{'page': page, 'page_size': pageSize};

    if (searchQuery?.isNotEmpty == true) {
      params['search'] = searchQuery;
    }
    if (categories?.isNotEmpty == true) {
      params['categories'] = categories!.join(',');
    }
    if (locations?.isNotEmpty == true) {
      params['locations'] = locations!.join(',');
    }
    if (status?.isNotEmpty == true) {
      params['status'] = status;
    }
    if (latitude != null) {
      params['latitude'] = latitude;
    }
    if (longitude != null) {
      params['longitude'] = longitude;
    }
    if (radius != null) {
      params['radius'] = radius;
    }

    return params;
  }
}

class ProductsResponse {
  final List<Product> products;
  final int totalCount;
  final int totalPages;
  final int currentPage;
  final bool hasNext;
  final bool hasPrevious;

  ProductsResponse({
    required this.products,
    required this.totalCount,
    required this.totalPages,
    required this.currentPage,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory ProductsResponse.fromJson(Map<String, dynamic> json) {
    return ProductsResponse(
      products:
          (json['results'] as List)
              .map((item) => Product.fromJson(item as Map<String, dynamic>))
              .toList(),
      totalCount: json['count'] as int,
      totalPages: ((json['count'] as int) / 20).ceil(),
      currentPage: json['current_page'] as int? ?? 1,
      hasNext: json['next'] != null,
      hasPrevious: json['previous'] != null,
    );
  }
}

/// Marketplace/Product service using the new architecture
class MarketplaceService extends BaseService {
  MarketplaceService({super.apiClient});

  /// Get products with filters and pagination
  Future<ProductsResponse> getProducts(ProductsRequest request) async {
    return executeApiCall(() async {
      final response = await apiClient.get(
        '/products/',
        queryParameters: request.toQueryParams(),
      );

      if (response.data == null) {
        throw Exception('Failed to load products');
      }

      return ProductsResponse.fromJson(response.data);
    });
  }

  /// Get product by ID
  Future<Product> getProduct(String productId) async {
    return executeApiCall(() async {
      final response = await apiClient.get('/products/$productId/');

      if (response.data == null) {
        throw Exception('Product not found');
      }

      return Product.fromJson(response.data);
    });
  }

  /// Get categories
  Future<List<String>> getCategories() async {
    return executeApiCall(() async {
      final response = await apiClient.get('/products/categories/');

      if (response.data == null) {
        throw Exception('Failed to load categories');
      }

      return (response.data as List).cast<String>();
    });
  }

  /// Get locations
  Future<List<String>> getLocations() async {
    return executeApiCall(() async {
      final response = await apiClient.get('/products/locations/');

      if (response.data == null) {
        throw Exception('Failed to load locations');
      }

      return (response.data as List).cast<String>();
    });
  }

  /// Search products
  Future<ProductsResponse> searchProducts({
    required String query,
    int page = 1,
    int pageSize = 20,
  }) async {
    final request = ProductsRequest(
      page: page,
      pageSize: pageSize,
      searchQuery: query,
    );

    return getProducts(request);
  }

  /// Get products by category
  Future<ProductsResponse> getProductsByCategory({
    required String category,
    int page = 1,
    int pageSize = 20,
  }) async {
    final request = ProductsRequest(
      page: page,
      pageSize: pageSize,
      categories: [category],
    );

    return getProducts(request);
  }

  /// Get nearby products
  Future<ProductsResponse> getNearbyProducts({
    required double latitude,
    required double longitude,
    double radius = 50.0, // km
    int page = 1,
    int pageSize = 20,
  }) async {
    final request = ProductsRequest(
      page: page,
      pageSize: pageSize,
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );

    return getProducts(request);
  }

  /// Get farmer's products
  Future<ProductsResponse> getFarmerProducts({
    required String farmerId,
    int page = 1,
    int pageSize = 20,
  }) async {
    return executeApiCall(() async {
      final response = await apiClient.get(
        '/farmers/$farmerId/products/',
        queryParameters: {'page': page, 'page_size': pageSize},
      );

      if (response.data == null) {
        throw Exception('Failed to load farmer products');
      }

      return ProductsResponse.fromJson(response.data);
    });
  }
}
