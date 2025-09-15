import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/src/features/product/presentation/controllers/filter_controller.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/core/components/product/location_picker.dart';

class FilterSheet extends StatelessWidget {
  FilterSheet({super.key});
  final FilterController controller = Get.put(FilterController());
  final AuthController authController =
      Get.isRegistered<AuthController>()
          ? Get.find<AuthController>()
          : Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar for better UX
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with clear all action
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Filters',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GetBuilder<FilterController>(
                  id: 'has_filters',
                  builder: (_) {
                    return controller.hasAnyFilters
                        ? TextButton.icon(
                          onPressed: () => controller.clearFilters(),
                          icon: const Icon(Icons.clear_all, size: 18),
                          label: const Text('Clear All'),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                          ),
                        )
                        : const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Scrollable content
          Flexible(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Location Section with improved layout
                _buildSectionHeader(
                  context,
                  'Location',
                  Icons.location_on_outlined,
                ),
                const SizedBox(height: 12),
                _buildLocationSection(context),

                const SizedBox(height: 24),

                // Categories with counter
                GetBuilder<FilterController>(
                  id: 'filters_count',
                  builder:
                      (_) => _buildSectionHeader(
                        context,
                        'Categories',
                        Icons.category_outlined,
                        count: controller.selectedCategories.length,
                      ),
                ),
                const SizedBox(height: 12),
                _buildCategoriesSection(),

                const SizedBox(height: 24),

                // Locations with counter
                GetBuilder<FilterController>(
                  id: 'filters_count',
                  builder:
                      (_) => _buildSectionHeader(
                        context,
                        'Locations (by name)',
                        Icons.place_outlined,
                        count: controller.selectedLocations.length,
                      ),
                ),
                const SizedBox(height: 12),
                _buildLocationsSection(),

                const SizedBox(height: 24),

                // Status section (role-based)
                _buildStatusSection(context),

                const SizedBox(height: 32),
              ],
            ),
          ),

          // Fixed bottom action bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: SafeArea(child: _buildActionButtons(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon, {
    int? count,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (count != null && count > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationSection(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final hasCoords =
          controller.selectedLatitude.value != null &&
          controller.selectedLongitude.value != null;
      final address = controller.selectedAddress.value;

      return Card(
        elevation: 0,
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location picker button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: Icon(
                    hasCoords ? Icons.location_on : Icons.map_outlined,
                    color: hasCoords ? theme.colorScheme.primary : null,
                  ),
                  label: Text(
                    hasCoords
                        ? (address.isNotEmpty
                            ? address
                            : 'lat: ${controller.selectedLatitude.value!.toStringAsFixed(4)}, lng: ${controller.selectedLongitude.value!.toStringAsFixed(4)}')
                        : 'Select location on map',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.centerLeft,
                    backgroundColor:
                        hasCoords
                            ? theme.colorScheme.primary.withValues(alpha: 0.05)
                            : null,
                  ),
                  onPressed: () => _openLocationPicker(context),
                ),
              ),

              // Clear location button (only show when location is selected)
              if (hasCoords) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => controller.clearSelectedLocation(),
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear location'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              // Nearby toggle with better styling
              Row(
                children: [
                  Switch.adaptive(
                    value: controller.useNearby.value,
                    onChanged: (v) => controller.useNearby.value = v,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Find nearby products',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Uses selected or current location',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCategoriesSection() {
    return Obx(
      () => Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            controller.categories.map((c) {
              final isSelected = controller.selectedCategories.contains(
                c.toLowerCase(),
              );
              return FilterChip(
                label: Text(c),
                selected: isSelected,
                onSelected: (_) => controller.toggleCategory(c),
                selectedColor: Theme.of(
                  Get.context!,
                ).colorScheme.primary.withValues(alpha: 0.15),
                checkmarkColor: Theme.of(Get.context!).colorScheme.primary,
                elevation: isSelected ? 2 : 0,
                pressElevation: 1,
              );
            }).toList(),
      ),
    );
  }

  Widget _buildLocationsSection() {
    final theme = Theme.of(Get.context!);
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'Search locations...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: theme.colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: controller.searchLocations,
        ),
        const SizedBox(height: 12),
        Obx(() {
          if (controller.filteredLocations.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No locations found',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            );
          }

          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                controller.filteredLocations.map((l) {
                  final isSelected = controller.selectedLocations.contains(
                    l.toLowerCase(),
                  );
                  return FilterChip(
                    label: Text(l),
                    selected: isSelected,
                    onSelected: (_) => controller.toggleLocation(l),
                    selectedColor: theme.colorScheme.secondary.withValues(
                      alpha: 0.15,
                    ),
                    checkmarkColor: theme.colorScheme.secondary,
                    elevation: isSelected ? 2 : 0,
                    pressElevation: 1,
                  );
                }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildStatusSection(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final role =
          authController.currentUser.value?.role.toLowerCase() ?? 'guest';
      final showStatus = role == 'admin' || role == 'farmer';
      if (!showStatus) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Status', Icons.check_circle_outline),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatusChip(
                  'All',
                  'all',
                  theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusChip('Active', 'active', Colors.green),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusChip('Inactive', 'inactive', Colors.red),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildStatusChip(String label, String value, Color color) {
    final theme = Theme.of(Get.context!);
    return Obx(() {
      final selected = controller.selectedStatus.value == value;
      return ChoiceChip(
        label: SizedBox(
          width: double.infinity,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? color : theme.colorScheme.onSurface,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
        selected: selected,
        selectedColor: color.withValues(alpha: 0.15),
        onSelected: (_) => controller.selectedStatus.value = value,
        elevation: selected ? 2 : 0,
        pressElevation: 1,
        side: BorderSide(
          color:
              selected
                  ? color
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      );
    });
  }

  Widget _buildActionButtons(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => controller.clearFilters(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Clear Filters'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: GetBuilder<FilterController>(
            id: 'filters_count',
            builder:
                (_) => ElevatedButton(
                  onPressed: () => _applyFilters(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.filter_alt, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Apply${controller.totalFiltersCount > 0 ? ' (${controller.totalFiltersCount})' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
          ),
        ),
      ],
    );
  }

  Future<void> _openLocationPicker(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.8,
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      ctx,
                    ).colorScheme.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        'Select Location',
                        style: Theme.of(ctx).textTheme.headlineSmall,
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Location picker
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: LocationPicker(
                      onLocationSelected: (lat, lon, addr) {
                        controller.setSelectedLocation(
                          latitude: lat,
                          longitude: lon,
                          address: addr,
                        );
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _applyFilters(BuildContext context) async {
    final pc = controller.productController;
    if (controller.useNearby.value &&
        controller.selectedLatitude.value != null &&
        controller.selectedLongitude.value != null) {
      await pc.fetchNearbyProducts(
        controller.selectedLatitude.value!,
        controller.selectedLongitude.value!,
      );
    } else {
      controller.applyFilters(
        controller.selectedCategories.toSet(),
        controller.selectedLocations.toSet(),
        controller.selectedStatus.value,
      );
    }
    if (context.mounted) Navigator.of(context).pop();
  }
}
