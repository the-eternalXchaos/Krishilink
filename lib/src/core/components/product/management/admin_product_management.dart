// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:krishi_link/features/admin/models/product_model.dart';
// import 'package:krishi_link/src/core/components/product/product_list_screen.dart';
// import 'package:krishi_link/src/core/components/product/product_form.dart';
// import 'package:krishi_link/src/core/components/product/product_form_data.dart';

// /// Example implementation for Admin Product Management
// /// This shows how to use the reusable components for admin users
// class AdminProductManagement extends StatelessWidget {
//   AdminProductManagement({super.key});

//   // Mock controller - replace with your actual admin product controller
//   final AdminProductController controller = Get.put(AdminProductController());

//   @override
//   Widget build(BuildContext context) {
//     return ProductListScreen(
//       products: controller.products,
//       isLoading: controller.isLoading,
//       isAdmin: true, // Show farmer names
//       title: 'manage_products',
//       showActiveToggle: true, // Show active/inactive toggle
//       showAddButton: true,
//       onEdit: _editProduct,
//       onDelete: _deleteProduct,
//       onRefresh: _refreshProducts,
//       onToggleActive: _toggleProductActive,
//       onAdd: _addProduct,
//     );
//   }

//   void _addProduct() {
//     Get.to(() => ProductForm(
//       onSubmit: _handleProductSubmit,
//       submitButtonText: 'add_product'.tr,
//     ));
//   }

//   void _editProduct(Product product) {
//     Get.to(() => ProductForm(
//       product: product,
//       onSubmit: (formData, imagePath) => _handleProductUpdate(product, formData, imagePath),
//       submitButtonText: 'update_product'.tr,
//     ));
//   }

//   void _deleteProduct(Product product) {
//     controller.deleteProduct(product.id);
//   }

//   void _refreshProducts() {
//     controller.fetchProducts();
//   }

//   void _toggleProductActive(Product product, bool isActive) {
//     controller.updateProductActiveStatus(product.id, isActive);
//   }

//   void _handleProductSubmit(ProductFormData formData, String? imagePath) {
//     controller.addProduct(formData, imagePath).then((_) {
//       Get.back(); // Close form
//       Get.snackbar('success'.tr, 'product_added_successfully'.tr);
//     }).catchError((error) {
//       Get.snackbar('error'.tr, error.toString());
//     });
//   }

//   void _handleProductUpdate(Product product, ProductFormData formData, String? imagePath) {
//     controller.updateProduct(product.id, formData, imagePath).then((_) {
//       Get.back(); // Close form
//       Get.snackbar('success'.tr, 'product_updated_successfully'.tr);
//     }).catchError((error) {
//       Get.snackbar('error'.tr, error.toString());
//     });
//   }
// }

// /// Mock Admin Product Controller
// /// Replace this with your actual controller implementation
// class AdminProductController extends GetxController {
//   final RxList<Product> products = <Product>[].obs;
//   final RxBool isLoading = false.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     fetchProducts();
//   }

//   Future<void> fetchProducts() async {
//     try {
//       isLoading.value = true;
//       // TODO: Replace with actual API call
//       await Future.delayed(const Duration(seconds: 1));
      
//       // Mock data - replace with actual API response
//       products.value = [
//         Product(
//           id: '1',
//           productName: 'Organic Tomatoes',
//           description: 'Fresh organic tomatoes from local farm',
//           rate: 50.0,
//           unit: 'kg',
//           latitude: 27.7172,
//           longitude: 85.3240,
//           location: 'Kathmandu, Nepal',
//           image: 'https://example.com/tomato.jpg',
//           soldedQuantity: 10.0,
//           availableQuantity: 100.0,
//           category: 'Vegetables',
//           farmerId: 'farmer1',
//           farmerName: 'Ram Bahadur',
//           farmerPhone: '9841234567',
//           isActive: true,
//           createdAt: DateTime.now(),
//         ),
//         // Add more mock products...
//       ];
//     } catch (e) {
//       Get.snackbar('error'.tr, e.toString());
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   Future<void> addProduct(ProductFormData formData, String? imagePath) async {
//     try {
//       isLoading.value = true;
//       // TODO: Implement actual API call to add product
//       await Future.delayed(const Duration(seconds: 1));
      
//       // Mock success - replace with actual implementation
//       await fetchProducts(); // Refresh list
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   Future<void> updateProduct(String productId, ProductFormData formData, String? imagePath) async {
//     try {
//       isLoading.value = true;
//       // TODO: Implement actual API call to update product
//       await Future.delayed(const Duration(seconds: 1));
      
//       // Mock success - replace with actual implementation
//       await fetchProducts(); // Refresh list
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   Future<void> deleteProduct(String productId) async {
//     try {
//       isLoading.value = true;
//       // TODO: Implement actual API call to delete product
//       await Future.delayed(const Duration(seconds: 1));
      
//       // Mock success - replace with actual implementation
//       products.removeWhere((p) => p.id == productId);
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   Future<void> updateProductActiveStatus(String productId, bool isActive) async {
//     try {
//       // TODO: Implement actual API call to update product status
//       await Future.delayed(const Duration(milliseconds: 500));
      
//       // Mock success - replace with actual implementation
//       final index = products.indexWhere((p) => p.id == productId);
//       if (index != -1) {
//         products[index] = products[index].copyWith(isActive: isActive);
//         products.refresh();
//       }
//     } catch (e) {
//       Get.snackbar('error'.tr, e.toString());
//     }
//   }
// }