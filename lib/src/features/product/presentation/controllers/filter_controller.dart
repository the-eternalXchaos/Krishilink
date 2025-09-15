import 'dart:async';
import 'package:get/get.dart';
import 'package:krishi_link/src/features/product/presentation/controllers/product_controller.dart';

class FilterController extends GetxController {
  final RxList<String> categories = <String>[].obs;
  final RxList<String> locations = <String>[].obs;
  final RxSet<String> selectedCategories = <String>{}.obs;
  final RxSet<String> selectedLocations = <String>{}.obs;
  final RxString locationSearchQuery = ''.obs;
  final RxString productSearchQuery = ''.obs;
  final RxString errorMessage = ''.obs;
  final RxString selectedStatus = 'active'.obs;
  final RxList<String> filteredLocations = <String>[].obs;

  // Nearby filtering (lat/lon + address + toggle)
  final RxnDouble selectedLatitude = RxnDouble();
  final RxnDouble selectedLongitude = RxnDouble();
  final RxString selectedAddress = ''.obs;
  final RxBool useNearby = false.obs;

  // Loading states for better UX
  final RxBool isLoadingCategories = false.obs;
  final RxBool isLoadingLocations = false.obs;
  final RxBool isApplyingFilters = false.obs;

  Timer? _debounce;
  Timer? _searchDebounce;

  // Resolve ProductController strictly via Get.find to avoid DI cycles
  late final ProductController productController =
      Get.find<ProductController>();

  // Computed properties for UI feedback
  bool get hasAnyFilters =>
      selectedCategories.isNotEmpty ||
      selectedLocations.isNotEmpty ||
      selectedStatus.value != 'active' ||
      hasLocationSelected ||
      productSearchQuery.value.isNotEmpty;

  bool get hasLocationSelected =>
      selectedLatitude.value != null && selectedLongitude.value != null;

  int get totalFiltersCount {
    int count = 0;
    count += selectedCategories.length;
    count += selectedLocations.length;

    // Count status if it's not the default 'active'
    if (selectedStatus.value != 'active') count++;

    // Count location selection
    if (hasLocationSelected) count++;

    // Count search query
    if (productSearchQuery.value.isNotEmpty) count++;

    return count;
  }

  // Reactive getters for UI
  RxBool get hasAnyFiltersRx => hasAnyFilters.obs;
  RxInt get totalFiltersCountRx => totalFiltersCount.obs;

  @override
  void onInit() {
    super.onInit();

    // Set up reactive listeners for computed properties
    ever(selectedCategories, (_) => _notifyFilterChange());
    ever(selectedLocations, (_) => _notifyFilterChange());
    ever(selectedStatus, (_) => _notifyFilterChange());
    ever(selectedLatitude, (_) => _notifyFilterChange());
    ever(selectedLongitude, (_) => _notifyFilterChange());
    ever(productSearchQuery, (_) => _notifyFilterChange());

    Future.delayed(Duration.zero, () => _fetchInitialData());
  }

  void _notifyFilterChange() {
    // Trigger UI updates for computed properties
    update(['filters_count', 'has_filters']);
  }

  void searchProducts(String query) {
    productSearchQuery.value = query.toLowerCase();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      productController.updateFilteredProducts();
    });
  }

  Future<void> _fetchInitialData() async {
    try {
      isLoadingCategories.value = true;
      isLoadingLocations.value = true;

      final results = await Future.wait([
        productController.fetchCategories(silent: true),
        productController.fetchLocations(silent: true),
      ]);

      final cats = results[0] as List<String>;
      final locs = results[1] as List<String>;

      initializeCategories(cats, selectedCategories.toSet());
      initializeLocations(locs);

      errorMessage.value = '';
    } catch (e) {
      errorMessage.value = 'Failed to load filter data: $e';
    } finally {
      isLoadingCategories.value = false;
      isLoadingLocations.value = false;
    }
  }

  void initializeCategories(List<String> newCategories, Set<String> initial) {
    categories.assignAll(newCategories);
    selectedCategories.assignAll(initial.map((c) => c.toLowerCase()));
  }

  void initializeLocations(List<String> newLocations) {
    locations.assignAll(newLocations);
    filteredLocations.assignAll(newLocations);
  }

  Future<void> applyFilters(
    Set<String> cats,
    Set<String> locs,
    String status,
  ) async {
    try {
      isApplyingFilters.value = true;

      selectedCategories.assignAll(cats.map((c) => c.toLowerCase()));
      selectedLocations.assignAll(locs.map((l) => l.toLowerCase()));
      selectedStatus.value = status;

      productController.updateFilteredProducts();

      errorMessage.value = '';
      update();
    } catch (e) {
      errorMessage.value = 'Failed to apply filters: $e';
    } finally {
      isApplyingFilters.value = false;
    }
  }

  void toggleCategory(String category) {
    final c = category.toLowerCase();
    if (selectedCategories.contains(c)) {
      selectedCategories.remove(c);
    } else {
      selectedCategories.add(c);
    }

    // Auto-apply filters for immediate feedback
    _debouncedFilterUpdate();
  }

  void toggleLocation(String location) {
    final l = location.toLowerCase();
    if (selectedLocations.contains(l)) {
      selectedLocations.remove(l);
    } else {
      selectedLocations.add(l);
    }

    // Auto-apply filters for immediate feedback
    _debouncedFilterUpdate();
  }

  void _debouncedFilterUpdate() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      productController.updateFilteredProducts();
    });
  }

  Future<void> searchLocations(String query) async {
    locationSearchQuery.value = query;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performLocationSearch(query);
    });
  }

  void _performLocationSearch(String query) {
    try {
      final allLocations = _getAllUniqueLocations();

      if (query.isEmpty) {
        filteredLocations.assignAll(allLocations);
      } else {
        final filtered =
            allLocations
                .where((loc) => loc.toLowerCase().contains(query.toLowerCase()))
                .toList();
        filteredLocations.assignAll(filtered);
      }
    } catch (e) {
      errorMessage.value = 'Failed to search locations: $e';
    }
  }

  List<String> _getAllUniqueLocations() {
    return productController.products
        .map((p) => p.location?.trim() ?? '')
        .where((loc) => loc.isNotEmpty)
        .toSet()
        .toList()
      ..sort(); // Sort alphabetically for better UX
  }

  void clearFilters() {
    selectedCategories.clear();
    selectedLocations.clear();
    locationSearchQuery.value = '';
    productSearchQuery.value = '';
    selectedStatus.value = 'active'; // Reset to default

    // Clear location data
    clearSelectedLocation();
    useNearby.value = false;

    // Reset filtered locations to show all
    filteredLocations.assignAll(locations);

    // Clear any error messages
    errorMessage.value = '';

    // Update products immediately
    productController.updateFilteredProducts();

    update();
  }

  void setSelectedLocation({
    required double latitude,
    required double longitude,
    String address = '',
  }) {
    selectedLatitude.value = latitude;
    selectedLongitude.value = longitude;
    selectedAddress.value = address;

    // Auto-enable nearby if location is selected
    if (!useNearby.value) {
      useNearby.value = true;
    }

    update();
  }

  void clearSelectedLocation() {
    selectedLatitude.value = null;
    selectedLongitude.value = null;
    selectedAddress.value = '';

    // Optionally disable nearby when location is cleared
    // useNearby.value = false;

    update();
  }

  // Convenience methods for UI
  bool isCategorySelected(String category) {
    return selectedCategories.contains(category.toLowerCase());
  }

  bool isLocationSelected(String location) {
    return selectedLocations.contains(location.toLowerCase());
  }

  bool isStatusSelected(String status) {
    return selectedStatus.value == status;
  }

  // Method to reset specific filter types
  void clearCategories() {
    selectedCategories.clear();
    productController.updateFilteredProducts();
    update();
  }

  void clearLocations() {
    selectedLocations.clear();
    locationSearchQuery.value = '';
    filteredLocations.assignAll(locations);
    productController.updateFilteredProducts();
    update();
  }

  void clearStatus() {
    selectedStatus.value = 'active';
    productController.updateFilteredProducts();
    update();
  }

  // Method to refresh filter data
  Future<void> refreshFilterData() async {
    await _fetchInitialData();
  }

  // Get filter summary for debugging or display
  Map<String, dynamic> getFilterSummary() {
    return {
      'categories': selectedCategories.toList(),
      'locations': selectedLocations.toList(),
      'status': selectedStatus.value,
      'hasLocation': hasLocationSelected,
      'useNearby': useNearby.value,
      'searchQuery': productSearchQuery.value,
      'totalFilters': totalFiltersCount,
    };
  }

  @override
  void onClose() {
    _debounce?.cancel();
    _searchDebounce?.cancel();
    super.onClose();
  }
}
