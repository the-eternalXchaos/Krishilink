import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/core/widgets/app_widgets.dart';
import 'package:krishi_link/src/core/components/product/product_form.dart';
import 'package:krishi_link/src/features/product/data/models/product_model.dart';
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
  final RxList<Product> filteredProducts = <Product>[].obs;
  final RxMap<String, bool> toggleLoading = <String, bool>{}.obs;

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    // Use debounced listeners to prevent excessive filtering
    debounce(
      searchQuery,
      (_) => _applyFilters(),
      time: const Duration(milliseconds: 300),
    );
    ever(filterActiveStatus, (_) => _applyFilters());
    ever(widget.products, (_) => _applyFilters());

    // Initial filter application
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyFilters());
  }

  void _applyFilters() {
    try {
      List<Product> filtered = List<Product>.from(widget.products);

      // Apply search filter
      if (searchQuery.value.isNotEmpty) {
        final query = searchQuery.value.toLowerCase().trim();
        filtered =
            filtered.where((product) {
              return product.productName.toLowerCase().contains(query) ||
                  product.category.toLowerCase().contains(query) ||
                  product.description.toLowerCase().contains(query) ||
                  (product.location?.toLowerCase().contains(query) ?? false) ||
                  (widget.isAdmin &&
                      (product.farmerName?.toLowerCase().contains(query) ??
                          false));
            }).toList();
      }

      // Apply status filter
      if (filterActiveStatus.value != 'all') {
        filtered =
            filtered.where((product) {
              return filterActiveStatus.value == 'active'
                  ? product.isActive
                  : !product.isActive;
            }).toList();
      }

      filteredProducts.value = filtered;
      debugPrint(
        '🔄 [ProductListScreen] Filters applied: ${filtered.length} products found',
      );
    } catch (e) {
      debugPrint('❌ [ProductListScreen] Error applying filters: $e');
      filteredProducts.value = widget.products.toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title.tr),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.onRefresh();
            },
            tooltip: 'refresh'.tr,
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(theme),
      body: Column(
        children: [
          _buildFilterSection(theme),
          Expanded(
            child: Obx(() {
              if (widget.isLoading.value) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading products...'),
                    ],
                  ),
                );
              }
              return _buildProductList();
            }),
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton(ThemeData theme) {
    if (!widget.showAddButton || widget.onAdd == null) return null;

    return Obx(() {
      final isBusy = widget.isLoading.value;
      return FloatingActionButton(
        onPressed: isBusy ? null : _handleAddProduct,
        backgroundColor:
            isBusy
                ? theme.primaryColor.withValues(alpha: 0.5)
                : theme.primaryColor,
        tooltip: 'add_product'.tr,
        child:
            isBusy
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : const Icon(Icons.add),
      );
    });
  }

  void _handleAddProduct() {
    if (widget.isLoading.value) {
      PopupService.error('Please wait for the current request to finish.');
      return;
    }
    HapticFeedback.lightImpact();
    widget.onAdd!();
  }

  Widget _buildFilterSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
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
          // Search bar
          SearchBar(
            onSearch: (value) => searchQuery.value = value,
            searchController: searchController,
          ),
          if (widget.showActiveToggle) ...[
            const SizedBox(height: 12),
            // Status filter dropdown
            Row(
              children: [
                Expanded(
                  child: Obx(
                    () => AppWidgets.dropdown(
                      value: filterActiveStatus.value,
                      items: const ['all', 'active', 'inactive'],
                      onChanged: (value) {
                        if (value != null) {
                          filterActiveStatus.value = value;
                        }
                      },
                      label: 'status'.tr,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return Obx(() {
      if (filteredProducts.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.lightImpact();
          widget.onRefresh();
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 80), // Account for FAB
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            final product = filteredProducts[index];
            return _buildProductCard(product, index);
          },
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              widget.products.isEmpty
                  ? 'no_products_found'.tr
                  : 'no_products_match_filter'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.products.isNotEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all),
                label: Text('clear_filters'.tr),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _clearFilters() {
    searchController.clear();
    searchQuery.value = '';
    filterActiveStatus.value = 'all';
    HapticFeedback.lightImpact();
  }

  Widget _buildProductCard(Product product, int index) {
    final toggleKey = product.id;
    final theme = Theme.of(context);

    return Card(
      key: ValueKey(product.id),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ExpansionTile(
        leading: _buildProductImage(product),
        title: Text(
          product.productName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: _buildProductSubtitle(product),
        children: [_buildProductDetails(product, toggleKey, theme)],
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 60,
        height: 60,
        child:
            product.image.isNotEmpty
                ? Image.network(
                  product.image,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder:
                      (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      ),
                )
                : Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported),
                ),
      ),
    );
  }

  Widget _buildProductSubtitle(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price: Rs.${product.rate}/${product.unit}',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).primaryColor,
          ),
        ),
        Text('Category: ${product.category}'),
        if (product.location?.isNotEmpty == true)
          Text('Location: ${product.location}'),
        if (widget.isAdmin && product.farmerName?.isNotEmpty == true)
          Text('Farmer: ${product.farmerName}'),
      ],
    );
  }

  Widget _buildProductDetails(
    Product product,
    String toggleKey,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product details
          _buildDetailRow(
            'Quantity',
            '${product.availableQuantity} ${product.unit}',
          ),
          if (product.description.isNotEmpty &&
              product.description != 'No description')
            _buildDetailRow('Description', product.description),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          // Action buttons
          _buildActionButtons(product, toggleKey, theme),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    Product product,
    String toggleKey,
    ThemeData theme,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        // Active/Inactive toggle
        if (widget.showActiveToggle && widget.onToggleActive != null)
          _buildActiveToggle(product, toggleKey, theme),

        // Edit button
        ElevatedButton.icon(
          onPressed: () => _handleEditProduct(product),
          icon: const Icon(Icons.edit, size: 18),
          label: Text('edit'.tr),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),

        // Delete button
        ElevatedButton.icon(
          onPressed: () => _handleDeleteProduct(product),
          icon: const Icon(Icons.delete, size: 18),
          label: Text('delete'.tr),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveToggle(
    Product product,
    String toggleKey,
    ThemeData theme,
  ) {
    return Obx(() {
      final isToggling = toggleLoading[toggleKey] == true;
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          dense: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                product.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: product.isActive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              if (isToggling) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          value: product.isActive,
          onChanged:
              isToggling
                  ? null
                  : (value) => _handleToggleActive(product, value, toggleKey),
          activeThumbColor: theme.primaryColor,
        ),
      );
    });
  }

  void _handleEditProduct(Product product) {
    HapticFeedback.lightImpact();
    Get.to(
      () => ProductForm(
        product: product,
        onSubmit: (formData, newImagePath) async {
          widget.onEdit(product);
        },
      ),
    );
  }

  void _handleDeleteProduct(Product product) {
    HapticFeedback.lightImpact();
    // Call the delete handler directly - confirmation dialog is handled in unified_product_management.dart
    widget.onDelete(product);
  }

  Future<void> _handleToggleActive(
    Product product,
    bool value,
    String toggleKey,
  ) async {
    toggleLoading[toggleKey] = true;
    try {
      // Optimistically update the UI
      final index = widget.products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        widget.products[index] = product.copyWith(isActive: value);
      }

      // Call the toggle function
      await widget.onToggleActive!(product, value);

      // Reset filter to 'all' to show the updated product
      if (filterActiveStatus.value != 'all') {
        filterActiveStatus.value = 'all';
      }

      PopupService.success(
        value
            ? 'Product activated successfully'
            : 'Product deactivated successfully',
      );
    } catch (e) {
      // Revert the optimistic update on error
      final index = widget.products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        widget.products[index] = product.copyWith(isActive: !value);
      }

      PopupService.error('Failed to toggle product status: $e');
      debugPrint('❌ [ProductListScreen] Toggle error: $e');
    } finally {
      toggleLoading[toggleKey] = false;
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
