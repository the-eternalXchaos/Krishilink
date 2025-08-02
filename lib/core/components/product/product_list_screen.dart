import 'package:flutter/material.dart' hide SearchBar;
import 'package:get/get.dart';
import 'package:krishi_link/core/components/product/product_form.dart';
import 'package:krishi_link/core/components/product/product_list_management.dart';
import 'package:krishi_link/features/admin/models/product_model.dart';
import 'package:krishi_link/widgets/search_bar.dart';

class ProductListScreen extends StatefulWidget {
  final RxList<Product> products;
  final RxBool isLoading;
  final bool isAdmin;
  final bool isFarmer;
  final Function(Product) onEdit;
  final Function(Product) onDelete;
  final VoidCallback onRefresh;
  final Function(Product, bool)? onToggleActive;
  final String title;
  final bool showActiveToggle;
  final bool showAddButton;
  final VoidCallback? onAdd;

  const ProductListScreen({
    super.key,
    required this.products,
    required this.isLoading,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh,
    this.isAdmin = false,
    this.isFarmer = false,
    this.onToggleActive,
    this.title = 'Products',
    this.showActiveToggle = true,
    this.showAddButton = true,
    this.onAdd,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxString filterActiveStatus = 'all'.obs;
  final RxString filterCategory = 'all'.obs;
  final RxList<Product> filteredProducts = <Product>[].obs;

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    // Listen to products changes
    ever(widget.products, (_) => _applyFilters());

    // Listen to search query changes
    ever(searchQuery, (_) => _applyFilters());

    // Listen to filter changes
    ever(filterActiveStatus, (_) => _applyFilters());
    ever(filterCategory, (_) => _applyFilters());

    // Initial filter application
    _applyFilters();
  }

  void _applyFilters() {
    List<Product> filtered = widget.products.toList();

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      //  controller.fetchProducts(
      //         page: 1,
      //         pageSizeParam: 20,
      //         searchQuery: controller.filterController.productSearchQuery.value,
      //         selectedCategories:
      //             controller.filterController.selectedCategories,
      //         selectedLocations: controller.filterController.selectedLsocations,
      //         status: controller.filterController.selectedStatus.value,
      //         reset: true,
      //       );

      filtered =
          filtered.where((product) {
            final query = searchQuery.value.toLowerCase();
            return product.productName.toLowerCase().contains(query) ||
                product.category.toLowerCase().contains(query) ||
                product.description.toLowerCase().contains(query) ||
                (product.location?.toLowerCase().contains(query) ?? false) ||
                (widget.isAdmin &&
                    (product.farmerName?.toLowerCase().contains(query) ??
                        false));
          }).toList();
    }

    // Apply active status filter
    if (filterActiveStatus.value != 'all') {
      filtered =
          filtered.where((product) {
            return filterActiveStatus.value == 'active'
                ? product.isActive
                : !product.isActive;
          }).toList();
    }

    // Apply category filter
    if (filterCategory.value != 'all') {
      filtered =
          filtered.where((product) {
            return product.category == filterCategory.value;
          }).toList();
    }

    filteredProducts.value = filtered;
  }

  Set<String> get availableCategories {
    final categories = widget.products.map((p) => p.category).toSet();
    categories.remove('');
    return categories;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title.tr),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: widget.onRefresh,
          ),
        ],
      ),
      floatingActionButton:
          widget.showAddButton && widget.onAdd != null
              ? FloatingActionButton(
                onPressed: widget.onAdd,
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(Icons.add),
              )
              : null,
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(child: Obx(() => _buildProductList())),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          SearchBar(
            onSearch: (value) => searchQuery.value = value,
            searchController: searchController,
          ),
          const SizedBox(height: 12),

          // Filter Row
          Row(
            children: [
              // Active Status Filter
              if (widget.showActiveToggle)
                Expanded(
                  child: Obx(
                    () => DropdownButtonFormField<String>(
                      value: filterActiveStatus.value,
                      decoration: InputDecoration(
                        labelText: 'status'.tr,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items:
                          ['all', 'active', 'inactive']
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status.tr.capitalizeFirst!),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          filterActiveStatus.value = value;
                        }
                      },
                    ),
                  ),
                ),

              // Remove the category filter dropdown for unified product management
              // if (widget.showActiveToggle) const SizedBox(width: 12),
              // Expanded(
              //   child: Obx(
              //     () => DropdownButtonFormField<String>(
              //       value: filterCategory.value,
              //       decoration: InputDecoration(
              //         labelText: 'category'.tr,
              //         border: const OutlineInputBorder(),
              //         contentPadding: const EdgeInsets.symmetric(
              //           horizontal: 12,
              //           vertical: 8,
              //         ),
              //       ),
              //       items: [
              //         DropdownMenuItem(
              //           value: 'all',
              //           child: Text('all'.tr.capitalizeFirst!),
              //         ),
              //         ...availableCategories.map(
              //           (category) => DropdownMenuItem(
              //             value: category,
              //             child: Text(category),
              //           ),
              //         ),
              //       ],
              //       onChanged: (value) {
              //         if (value != null) {
              //           filterCategory.value = value;
              //         }
              //       },
              //     ),
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    if (widget.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              widget.products.isEmpty
                  ? 'no_products_found'.tr
                  : 'no_products_match_filter'.tr,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (widget.products.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  searchController.clear();
                  searchQuery.value = '';
                  filterActiveStatus.value = 'all';
                  filterCategory.value = 'all';
                },
                child: Text('clear_filters'.tr),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      child: ListView.builder(
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          final product = filteredProducts[index];
          return ProductListManagement(
            product: product,
            isAdmin: widget.isAdmin,
            isFarmer: widget.isFarmer,
            showActiveToggle: widget.showActiveToggle,
            // onEdit: () => widget.onEdit(product),
            onEdit: () {
              Get.to(
                () => ProductForm(
                  product: product,
                  onSubmit: (formData, newImagePath) async {
                    // Handle form submission
                    debugPrint(
                      '🔄 [ProductListScreen] New image path: $newImagePath',
                    );
                    debugPrint(
                      '🔄 [ProductListScreen] Form data: ${formData.productName}, ${formData.rate}, ${formData.category}',
                    );
                    debugPrint('🔄 [ProductListScreen] Form submitted');
                    debugPrint(
                      '🔄 [ProductListScreen] Product: ${product.id ?? 'new'}',
                    );
                    debugPrint(
                      '🔄 [ProductListScreen] Form data: ${formData.productName}, ${formData.rate}, ${formData.category}',
                    );
                  },
                ),
              );
              // Get.toNamed('/product-edit', arguments: {'product': product});
            },

            onDelete: () => _confirmDelete(product),
            onToggleActive:
                widget.onToggleActive != null
                    ? (value) => widget.onToggleActive!(product, value)
                    : null,
          );
        },
      ),
    );
  }

  void _confirmDelete(Product product) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'delete_product'.tr,
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
        content: Text('confirm_delete_product'.trArgs([product.productName])),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'cancel'.tr,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              widget.onDelete(product);
            },
            child: Text(
              'delete'.tr,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
