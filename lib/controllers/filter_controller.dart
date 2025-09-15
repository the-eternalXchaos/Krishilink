// Legacy shim
export 'package:krishi_link/src/features/product/presentation/controllers/filter_controller.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:krishi_link/features/product/controllers/product_controller.dart';

class FilterController extends GetxController {
  final RxList<String> categories = <String>[].obs;
  final RxList<String> locations = <String>[].obs;
  final RxSet<String> selectedCategories = <String>{}.obs;
  final RxSet<String> selectedLocations = <String>{}.obs;
  final RxString locationSearchQuery = ''.obs;
  final RxString productSearchQuery = ''.obs;
  final RxString errorMessage = ''.obs;
  final RxString selectedStatus = 'active'.obs;

  final RxList<String> filteredLocations =
      <String>[].obs; // ✅ converted to observable

  Timer? _debounce;
  Timer? _searchDebounce;

  final ProductController productController =
      Get.isRegistered<ProductController>()
          ? Get.find<ProductController>()
          : throw Exception('ProductController must be initialized first');

  @override
  void onInit() {
    super.onInit();
    // Defer initial data loading to avoid setState during build
    Future.delayed(Duration.zero, () => _fetchInitialData());
  }

  void searchProducts(String query) {
    productSearchQuery.value = query.toLowerCase();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      productController.updateFilteredProducts();
    });
  }

  Future<void> loadInitialData() async {
    try {
      final categories = await productController.fetchCategories();
      final locations = await productController.fetchLocations();
      initializeCategories(categories, selectedCategories.toSet());
      initializeLocations(locations);
    } catch (e) {
      errorMessage.value = 'Failed to load filter data: $e';
    }
  }

  void applyFilters(
    Set<String> categories,
    Set<String> locations,
    String status,
  ) {
    selectedCategories.assignAll(categories.map((c) => c.toLowerCase()));
    selectedLocations.assignAll(locations.map((l) => l.toLowerCase()));
    selectedStatus.value = status;
    productController.updateFilteredProducts();
    update();
  }

  Future<void> _fetchInitialData() async {
    try {
      final categories = await productController.fetchCategories();
      final locations = await productController.fetchLocations();
      initializeCategories(categories, selectedCategories.toSet());
      initializeLocations(locations);
    } catch (e) {
      errorMessage.value = 'Failed to load filter data: $e';
    }
  }

  void initializeCategories(
    List<String> newCategories,
    Set<String> initialFilters,
  ) {
    categories.assignAll(newCategories);
    selectedCategories.assignAll(initialFilters.map((c) => c.toLowerCase()));
  }

  void initializeLocations(List<String> newLocations) {
    locations.assignAll(newLocations);
    filteredLocations.assignAll(newLocations); // ✅ initialize filteredLocations
  }

  void toggleCategory(String category) {
    final normalized = category.toLowerCase();
    if (selectedCategories.contains(normalized)) {
      selectedCategories.remove(normalized);
    } else {
      selectedCategories.add(normalized);
    }
    update();
  }

  void toggleLocation(String location) {
    final normalized = location.toLowerCase();
    if (selectedLocations.contains(normalized)) {
      selectedLocations.remove(normalized);
    } else {
      selectedLocations.add(normalized);
    }
    update();
  }

  // ✅ Debounced location search with address extraction
  Future<void> searchLocations(String query) async {
    locationSearchQuery.value = query;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      // Extract unique addresses from products for suggestions
      final allAddresses =
          productController.products
              .map((p) => p.location?.trim() ?? '')
              .where((loc) => loc.isNotEmpty)
              .toSet()
              .toList();
      if (query.isEmpty) {
        locations.assignAll(allAddresses);
        filteredLocations.assignAll(allAddresses);
      } else {
        final result =
            allAddresses
                .where((loc) => loc.toLowerCase().contains(query.toLowerCase()))
                .toList();
        locations.assignAll(result);
        filteredLocations.assignAll(result);
      }
      productController.updateFilteredProducts();
    });
  }

  void clearFilters() {
    selectedCategories.clear();
    selectedLocations.clear();
    locationSearchQuery.value = '';
    productSearchQuery.value = '';
    filteredLocations.assignAll(locations); // ✅ reset filteredLocations
    update();
  }

  List<String> get availableCategories => categories.toList();

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
