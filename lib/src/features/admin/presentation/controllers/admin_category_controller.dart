// import 'package:get/get.dart';
// import 'package:krishi_link/features/admin/models/category_model.dart';

// class AdminCategoryController extends GetxController {
//   final RxList<CategoryModel> categories = <CategoryModel>[].obs;
//   final RxInt totalCategories = 0.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     fetchCategories();
//   }

//   void fetchCategories() {
//     // Mock data
//     final mockCategories = [
//       CategoryModel(id: '1', name: 'Grains', createdAt: DateTime.now()),
//       CategoryModel(id: '2', name: 'Vegetables', createdAt: DateTime.now()),
//     ];
//     categories.assignAll(mockCategories);
//     totalCategories.value = mockCategories.length;
//   }
// }
// lib/features/admin/controller/admin_category_controller.dart
import 'package:get/get.dart';
import 'package:krishi_link/src/features/admin/presentation/controllers/admin_category_controller.dart';

// lib/features/admin/controller/admin_category_controller.dart
import 'package:krishi_link/src/features/product/data/models/category_model.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';

class AdminCategoryController extends GetxController {
  final categories = <CategoryModel>[].obs;
  final isLoading = false.obs;
  final totalCategories = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      isLoading(true);
      // Mock API; replace with real endpoint
      categories.assignAll([
        CategoryModel(id: '1', name: 'Vegetables'),
        CategoryModel(id: '2', name: 'Fruits'),
        CategoryModel(id: '3', name: 'Grains'),
      ]);
      totalCategories.value = categories.length;
    } catch (e) {
      PopupService.error('Failed to load categories: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> addCategory(String name) async {
    try {
      isLoading(true);
      // Mock; replace with API
      final newCategory = CategoryModel(
        id: '${categories.length + 1}',
        name: name,
      );
      categories.add(newCategory);
      totalCategories.value = categories.length;
      PopupService.success('Category added');
    } catch (e) {
      PopupService.error('Failed to add category: $e');
    } finally {
      isLoading(false);
    }
  }
}
