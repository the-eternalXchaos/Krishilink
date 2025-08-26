// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:krishi_link/features/admin/models/product_model.dart';
// import 'package:krishi_link/core/components/product/product_list_screen.dart';
// import 'package:krishi_link/core/components/product/product_form.dart';
// import 'package:krishi_link/core/components/product/product_form_data.dart';

// /// Example implementation for Farmer Product Management
// /// This shows how to use the reusable components for farmer users
// class FarmerProductManagement extends StatelessWidget {
//   FarmerProductManagement({super.key});

//   // Mock controller - replace with your actual farmer product controller
//   final FarmerProductController controller = Get.put(FarmerProductController());

//   @override
//   Widget build(BuildContext context) {
//     return ProductListScreen(
//       products: controller.products,
//       isLoading: controller.isLoading,
//       isAdmin:
//           false, // Don't show farmer names (farmer sees their own products)
//       title: 'my_products',
//       showActiveToggle: false, // Farmers might not need active/inactive toggle
//       showAddButton: true,
//       onEdit: _editProduct,
//       onDelete: _deleteProduct,
//       onRefresh: _refreshProducts,
//       onAdd: _addProduct,
//     );
//   }

//   void _addProduct() {
//     Get.dialog(
//       ProductForm(
//         onSubmit: _handleProductSubmit,
//         submitButtonText: 'add_product'.tr,
//       ),
//     );
//   }

//   void _editProduct(Product product) {
//     Get.dialog(
//       ProductForm(
//         product: product,
//         onSubmit:
//             (formData, imagePath) =>
//                 _handleProductUpdate(product, formData, imagePath),
//         submitButtonText: 'update_product'.tr,
//       ),
//     );
//   }

//   void _deleteProduct(Product product) {
//     // Show confirmation dialog specific to farmers
//     Get.dialog(
//       AlertDialog(
//         title: Text('delete_product'.tr),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('confirm_delete_product'.trArgs([product.productName])),
//             const SizedBox(height: 8),
//             Text(
//               'delete_product_warning'.tr,
//               style: TextStyle(color: Colors.orange[700], fontSize: 12),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
//           TextButton(
//             onPressed: () {
//               Get.back();
//               controller.deleteProduct(product.id);
//             },
//             child: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }

//   void _refreshProducts() {
//     controller.fetchMyProducts();
//   }

//   void _handleProductSubmit(ProductFormData formData, String? imagePath) {
//     controller
//         .addProduct(formData, imagePath)
//         .then((_) {
//           Get.back(); // Close form
//           Get.snackbar(
//             'success'.tr,
//             'product_added_successfully'.tr,
//             backgroundColor: Colors.green.withOpacity(0.8),
//             colorText: Colors.white,
//           );
//         })
//         .catchError((error) {
//           Get.snackbar('error'.tr, error.toString());
//         });
//   }

//   void _handleProductUpdate(
//     Product product,
//     ProductFormData formData,
//     String? imagePath,
//   ) {
//     controller
//         .updateProduct(product.id, formData, imagePath)
//         .then((_) {
//           Get.back(); // Close form
//           Get.snackbar(
//             'success'.tr,
//             'product_updated_successfully'.tr,
//             backgroundColor: Colors.green.withOpacity(0.8),
//             colorText: Colors.white,
//           );
//         })
//         .catchError((error) {
//           Get.snackbar('error'.tr, error.toString());
//         });
//   }
// }

// /// Mock Farmer Product Controller
// /// Replace this with your actual controller implementation
// class FarmerProductController extends GetxController {
//   final RxList<Product> products = <Product>[].obs;
//   final RxBool isLoading = false.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     fetchMyProducts();
//   }

//   Future<void> fetchMyProducts() async {
//     try {
//       isLoading.value = true;
//       // TODO: Replace with actual API call to get farmer's products
//       await Future.delayed(const Duration(seconds: 1));

//       // Mock data - replace with actual API response
//       products.value = [
//         Product(
//           id: '1',
//           productName: 'Fresh Carrots',
//           description: 'Organically grown carrots from my farm',
//           rate: 40.0,
//           unit: 'kg',
//           latitude: 27.7172,
//           longitude: 85.3240,
//           location: 'Bhaktapur, Nepal',
//           image: 'https://example.com/carrot.jpg',
//           soldedQuantity: 5.0,
//           availableQuantity: 50.0,
//           category: 'Vegetables',
//           farmerId: 'current_farmer_id',
//           farmerName: 'Current Farmer',
//           farmerPhone: '9841234567',
//           isActive: true,
//           createdAt: DateTime.now().subtract(const Duration(days: 2)),
//         ),
//         Product(
//           id: '2',
//           productName: 'Organic Spinach',
//           description: 'Fresh spinach leaves, pesticide-free',
//           rate: 60.0,
//           unit: 'kg',
//           latitude: 27.7172,
//           longitude: 85.3240,
//           location: 'Bhaktapur, Nepal',
//           image: 'https://example.com/spinach.jpg',
//           soldedQuantity: 2.0,
//           availableQuantity: 25.0,
//           category: 'Leafy Greens',
//           farmerId: 'current_farmer_id',
//           farmerName: 'Current Farmer',
//           farmerPhone: '9841234567',
//           isActive: true,
//           createdAt: DateTime.now().subtract(const Duration(days: 1)),
//         ),
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
//       await Future.delayed(const Duration(seconds: 2));

//       // Mock success - replace with actual implementation
//       await fetchMyProducts(); // Refresh list
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   Future<void> updateProduct(
//     String productId,
//     ProductFormData formData,
//     String? imagePath,
//   ) async {
//     try {
//       isLoading.value = true;
//       // TODO: Implement actual API call to update product
//       await Future.delayed(const Duration(seconds: 2));

//       // Mock success - replace with actual implementation
//       await fetchMyProducts(); // Refresh list
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

//       Get.snackbar(
//         'success'.tr,
//         'product_deleted_successfully'.tr,
//         backgroundColor: Colors.green.withOpacity(0.8),
//         colorText: Colors.white,
//       );
//     } catch (e) {
//       Get.snackbar('error'.tr, e.toString());
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   // Additional farmer-specific methods
//   Future<void> markProductAsSoldOut(String productId) async {
//     try {
//       // TODO: Implement API call to mark product as sold out
//       final index = products.indexWhere((p) => p.id == productId);
//       if (index != -1) {
//         products[index] = products[index].copyWith(availableQuantity: 0);
//         products.refresh();
//       }
//     } catch (e) {
//       Get.snackbar('error'.tr, e.toString());
//     }
//   }

//   Future<void> updateProductQuantity(
//     String productId,
//     double newQuantity,
//   ) async {
//     try {
//       // TODO: Implement API call to update product quantity
//       final index = products.indexWhere((p) => p.id == productId);
//       if (index != -1) {
//         products[index] = products[index].copyWith(
//           availableQuantity: newQuantity,
//         );
//         products.refresh();
//       }
//     } catch (e) {
//       Get.snackbar('error'.tr, e.toString());
//     }
//   }
// }
