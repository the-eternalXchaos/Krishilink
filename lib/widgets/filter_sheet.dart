import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/controllers/filter_controller.dart';
import 'package:krishi_link/controllers/product_controller.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:geolocator/geolocator.dart';

class FilterSheet extends StatelessWidget {
  final Function(Set<String>, Set<String>, String)
  onFiltersApplied; // Add status param

  const FilterSheet({super.key, required this.onFiltersApplied});

  @override
  Widget build(BuildContext context) {
    final FilterController filterController = Get.find<FilterController>();
    final ProductController productController = Get.find<ProductController>();
    final AuthController authController = Get.find<AuthController>();
    final String role =
        authController.currentUser.value?.role.toLowerCase() ?? 'guest';

    // Add observable for status if not present
    filterController.selectedStatus.value = 'active';
    if (role == 'admin' || role == 'farmer') {
      // Do not override user selection
      filterController.selectedStatus.value = 'all';
    } else {
      // For buyer/guest, always set to 'active'
      filterController.selectedStatus.value = 'active';
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildDragHandle(),
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status filter for admin/farmer
                    if (role == 'admin' || role == 'farmer') ...[
                      const SizedBox(height: 16),
                      Text(
                        'Product Status',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Obx(
                        () => Row(
                          children: [
                            Radio<String>(
                              value: 'all',
                              groupValue: filterController.selectedStatus.value,
                              onChanged: (value) {
                                if (value != null) {
                                  filterController.selectedStatus.value = value;
                                  filterController.applyFilters(
                                    filterController.selectedCategories,
                                    filterController.selectedLocations,
                                    value,
                                  );
                                }
                              },
                            ),
                            const Text('All'),
                            Radio<String>(
                              value: 'active',
                              groupValue: filterController.selectedStatus.value,
                              onChanged: (value) {
                                if (value != null) {
                                  filterController.selectedStatus.value = value;
                                  filterController.applyFilters(
                                    filterController.selectedCategories,
                                    filterController.selectedLocations,
                                    value,
                                  );
                                }
                              },
                            ),
                            const Text('Active'),
                            Radio<String>(
                              value: 'inactive',
                              groupValue: filterController.selectedStatus.value,
                              onChanged: (value) {
                                if (value != null) {
                                  filterController.selectedStatus.value = value;
                                  filterController.applyFilters(
                                    filterController.selectedCategories,
                                    filterController.selectedLocations,
                                    value,
                                  );
                                }
                              },
                            ),
                            const Text('Inactive'),
                          ],
                        ),
                      ),
                    ],
                    _buildSectionHeader(context, 'categories'.tr),
                    _buildCategoryFilters(filterController),
                    const SizedBox(height: 20),
                    _buildSectionHeader(context, 'locations'.tr),
                    _buildLocationSearch(filterController),
                    _buildLocationFilters(filterController),
                    // After location search bar
                    const SizedBox(height: 12),
                    Obx(
                      () => ElevatedButton.icon(
                        icon: Icon(Icons.my_location),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Show Nearby Products'),
                            if (productController.isLoading.value) ...[
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                ),
                              ),
                            ],
                          ],
                        ),
                        onPressed:
                            productController.isLoading.value
                                ? null
                                : () async {
                                  await _showNearbyProducts(context);
                                },
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
          _buildActionButtons(filterController, productController, role),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        'filter_products'.tr,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withAlpha(204),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters(FilterController controller) {
    return Obx(
      () => Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            controller.availableCategories.map((category) {
              final isSelected = controller.selectedCategories.contains(
                category.toLowerCase(),
              );

              return FilterChip(
                label: Text(category),
                tooltip: category,

                selected: isSelected,
                onSelected: (_) => controller.toggleCategory(category),
                selectedColor: Colors.green[100],
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.green[800] : Colors.grey[800],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                backgroundColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildLocationSearch(FilterController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'search_locations'.tr,
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
        ),
        onChanged: (query) => controller.searchLocations(query),
      ),
    );
  }

  Widget _buildLocationFilters(FilterController controller) {
    return Obx(() {
      if (controller.filteredLocations.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'no_locations_found'.tr,
            style: TextStyle(color: Colors.grey),
          ),
        );
      }

      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            controller.filteredLocations.toList().map((location) {
              final isSelected = controller.selectedLocations.contains(
                location.toLowerCase(),
              );
              return ChoiceChip(
                label: Text(location),
                tooltip: location,
                selected: isSelected,
                onSelected: (_) => controller.toggleLocation(location),
                showCheckmark: false,
                selectedColor: Colors.green[100],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.green[800] : Colors.grey[800],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                backgroundColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              );
            }).toList(),
      );
    });
  }

  Widget _buildStatusFilter(FilterController controller) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Product Status', style: TextStyle(fontWeight: FontWeight.w600)),
          Row(
            children: [
              Radio<String>(
                value: 'active',
                groupValue: controller.selectedStatus.value,
                onChanged: (v) => controller.selectedStatus.value = v!,
              ),
              const Text('Active'),
              Radio<String>(
                value: 'inactive',
                groupValue: controller.selectedStatus.value,
                onChanged: (v) => controller.selectedStatus.value = v!,
              ),
              const Text('Inactive'),
              Radio<String>(
                value: 'all',
                groupValue: controller.selectedStatus.value,
                onChanged: (v) => controller.selectedStatus.value = v!,
              ),
              const Text('All'),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    FilterController filterController,
    ProductController productController,
    String role,
  ) {
    return Obx(() {
      final isApplyDisabled =
          filterController.selectedCategories.isEmpty &&
          filterController.selectedLocations.isEmpty;

      // For admin/farmer, require a status to be selected
      final statusSelected = filterController.selectedStatus.value.isNotEmpty;
      final canApply =
          (role == 'admin' || role == 'farmer')
              ? statusSelected
              : !isApplyDisabled;

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  filterController.clearFilters();
                  productController.fetchProducts();
                  Get.back();
                  PopupService.info('Filter reset', title: 'Filter');
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.green[800]!),
                ),
                child: Text(
                  'clear_all'.tr,
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                onPressed:
                    canApply
                        ? () {
                          onFiltersApplied(
                            filterController.selectedCategories.toSet(),
                            filterController.selectedLocations.toSet(),
                            filterController.selectedStatus.value,
                          );
                          Get.back();
                          PopupService.success(
                            'Filter applied successfully',
                            title: 'Filter',
                          );
                        }
                        : null,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green[800],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.green[200],
                ),
                child: Text(
                  'apply_filters'.tr,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

Future<void> _showNearbyProducts(BuildContext context) async {
  try {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      Get.snackbar(
        'Location Required',
        'Please enable location permission to find nearby products.',
      );
      return;
    }
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    await Get.find<ProductController>().fetchNearbyProducts(
      position.latitude,
      position.longitude,
    );
    Navigator.of(context).pop(); // Close the filter sheet
  } catch (e) {
    Get.snackbar('Error', 'Failed to get location: $e');
  }
}
