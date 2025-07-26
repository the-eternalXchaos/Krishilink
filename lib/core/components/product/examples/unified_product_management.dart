import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/components/product/examples/unified_product_controller.dart';
import 'package:krishi_link/core/components/product/add_edit_product_form.dart';
import 'package:krishi_link/core/components/product/product_form.dart';
import 'package:krishi_link/features/admin/controllers/admin_product_controller.dart';
import 'package:krishi_link/controllers/filter_controller.dart';
import 'package:krishi_link/features/admin/models/product_model.dart';
import 'package:krishi_link/widgets/search_bar.dart' as custom;
import 'package:krishi_link/core/lottie/popup_service.dart';

class UnifiedProductManagement extends StatefulWidget {
  const UnifiedProductManagement({super.key});

  @override
  State<UnifiedProductManagement> createState() =>
      _UnifiedProductManagementState();
}

class _UnifiedProductManagementState extends State<UnifiedProductManagement> {
  final UnifiedProductController controller =
      Get.isRegistered<UnifiedProductController>()
          ? Get.find<UnifiedProductController>()
          : Get.put(UnifiedProductController());
  final FilterController filterController =
      Get.isRegistered<FilterController>()
          ? Get.find<FilterController>()
          : Get.put(FilterController());
  final TextEditingController searchController = TextEditingController();
  final RxString filterActiveStatus = 'all'.obs;

  @override
  void initState() {
    super.initState();
    controller.fetchProducts();
    searchController.addListener(() {
      filterController.searchProducts(searchController.text);
      controller.fetchProducts(
        searchQuery: filterController.productSearchQuery.value,
        selectedCategories: filterController.selectedCategories.toList(),
        selectedLocations: filterController.selectedLocations.toList(),
      );
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('manage_products'.tr),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                () => controller.fetchProducts(
                  searchQuery: filterController.productSearchQuery.value,
                  selectedCategories:
                      filterController.selectedCategories.toList(),
                  selectedLocations:
                      filterController.selectedLocations.toList(),
                  status:
                      filterActiveStatus.value, // Include current status filter
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => Get.dialog(
              ProductForm(
                product: null,
                onSubmit: (formData, newImagePath) async {
                  // TODO: Implement product submission logic
                },
              ),
            ),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: custom.SearchBar(
                    onSearch: (value) {
                      filterController.searchProducts(value);
                      controller.fetchProducts(
                        searchQuery: filterController.productSearchQuery.value,
                        selectedCategories:
                            filterController.selectedCategories.toList(),
                        selectedLocations:
                            filterController.selectedLocations.toList(),
                        status:
                            filterActiveStatus
                                .value, // Include current status filter
                      );
                    },
                    searchController: searchController,
                  ),
                ),
                const SizedBox(width: 8),
                Obx(
                  () => DropdownButton<String>(
                    value: filterActiveStatus.value,
                    items:
                        ['all', 'active', 'inactive']
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(status.tr.capitalizeFirst!),
                              ),
                            )
                            .toList(),
                    onChanged: (value) async {
                      if (value != null) {
                        filterActiveStatus.value = value;
                        // Fetch products with the new status filter
                        await controller.fetchProducts(
                          searchQuery:
                              filterController.productSearchQuery.value,
                          selectedCategories:
                              filterController.selectedCategories.toList(),
                          selectedLocations:
                              filterController.selectedLocations.toList(),
                          status: value, // Pass the selected status
                          reset:
                              true, // Reset to get fresh data with new filter
                        );
                      }
                    },
                    underline: Container(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(
              () =>
                  controller.isLoading.value
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                        onRefresh: () async {
                          await controller.fetchProducts(
                            searchQuery:
                                filterController.productSearchQuery.value,
                            selectedCategories:
                                filterController.selectedCategories.toList(),
                            selectedLocations:
                                filterController.selectedLocations.toList(),
                            status:
                                filterActiveStatus
                                    .value, // Include current status filter
                            reset:
                                true, // This will clear the list and start fresh
                          );
                        },
                        child:
                            controller.products.isEmpty
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('no_products_found'.tr),
                                      SizedBox(height: 040),
                                      ElevatedButton(
                                        onPressed: () async {
                                          await controller.fetchProducts(
                                            searchQuery:
                                                filterController
                                                    .productSearchQuery
                                                    .value,
                                            selectedCategories:
                                                filterController
                                                    .selectedCategories
                                                    .toList(),
                                            selectedLocations:
                                                filterController
                                                    .selectedLocations
                                                    .toList(),
                                            status: filterActiveStatus.value,
                                            reset: true,
                                          );
                                        },
                                        child: Text('refresh'.tr),
                                      ),
                                    ],
                                  ),
                                )
                                : ListView.builder(
                                  itemCount: controller.products.length,
                                  itemBuilder: (context, index) {
                                    final product = controller.products[index];
                                    if (filterActiveStatus.value != 'all' &&
                                        ((filterActiveStatus.value ==
                                                    'active' &&
                                                !product.isActive) ||
                                            (filterActiveStatus.value ==
                                                    'inactive' &&
                                                product.isActive))) {
                                      return const SizedBox.shrink();
                                    }
                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ExpansionTile(
                                        leading: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            product.image,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) => Container(
                                                  width: 60,
                                                  height: 60,
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                    Icons.image_not_supported,
                                                  ),
                                                ),
                                          ),
                                        ),
                                        title: Text(
                                          product.productName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Price: Rs.${product.rate}/${product.unit}',
                                            ),
                                          ],
                                        ),
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                SwitchListTile(
                                                  title: Text(
                                                    product.isActive
                                                        ? 'Active'
                                                        : 'Inactive',
                                                    style: TextStyle(
                                                      color:
                                                          product.isActive
                                                              ? Colors.green
                                                              : Colors.red,
                                                    ),
                                                  ),
                                                  value: product.isActive,
                                                  onChanged: (value) async {
                                                    try {
                                                      await controller
                                                          .updateProductActiveStatus(
                                                            product.id,
                                                            value,
                                                          );
                                                    } catch (e) {
                                                      // Error is already handled in the controller
                                                      // The toggle will revert to its previous state
                                                    }
                                                  },
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                  dense: true,
                                                ),
                                                Text(
                                                  'Category: ${product.category}',
                                                ),
                                                Text(
                                                  'Quantity: ${product.availableQuantity} ${product.unit}',
                                                ),
                                                if (product.location != null &&
                                                    product
                                                        .location!
                                                        .isNotEmpty)
                                                  Text(
                                                    'Location: ${product.location}',
                                                  ),
                                                if (product
                                                        .description
                                                        .isNotEmpty &&
                                                    product.description !=
                                                        'No description')
                                                  Text(
                                                    'Description: ${product.description}',
                                                  ),
                                                if (product.farmerName !=
                                                        null &&
                                                    product
                                                        .farmerName!
                                                        .isNotEmpty)
                                                  Text(
                                                    'Farmer: ${product.farmerName}',
                                                  ),
                                                const SizedBox(height: 16),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  children: [
                                                    ElevatedButton.icon(
                                                      onPressed:
                                                          () =>
                                                              _showProductDialog(
                                                                context,
                                                                product:
                                                                    product,
                                                              ),
                                                      icon: const Icon(
                                                        Icons.edit,
                                                      ),
                                                      label: Text('edit'.tr),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.blue,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                    ElevatedButton.icon(
                                                      onPressed:
                                                          () => _confirmDelete(
                                                            context,
                                                            controller,
                                                            product,
                                                          ),
                                                      icon: const Icon(
                                                        Icons.delete,
                                                      ),
                                                      label: Text('delete'.tr),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProductDialog(BuildContext context, {Product? product}) {
    Get.dialog(
      ProductForm(
        product: product,
        onSubmit: (formData, newImagePath) async {
          try {
            if (product != null) {
              // Update existing product
              await controller.updateProduct(
                product.id,
                formData,
                newImagePath,
              );
              PopupService.success('Product updated successfully');
            } else {
              // Add new product
              await controller.addProduct(formData, newImagePath);
              PopupService.success('Product added successfully');
            }
            Get.back(); // Close the dialog
          } catch (e) {
            PopupService.error('Failed to save product: $e');
          }
        },
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    UnifiedProductController controller,
    Product product,
  ) {
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
              controller.deleteProduct(product.id);
              Get.back();
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
}
