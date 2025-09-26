// import 'dart:io';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart' hide SearchBar;
// import 'package:get/get.dart';
// import 'package:krishi_link/src/features/profile/presentation/controllers/filter_controller.dart
// import 'package:krishi_link/controllers/product_controller.dart';
// import 'package:krishi_link/features/admin/controllers/admin_product_controller.dart';
// import 'package:krishi_link/features/admin/models/product_model.dart';
// import 'package:krishi_link/features/admin/widgets/product_form_dialog.dart';
// import 'package:krishi_link/features/auth/controller/auth_controller.dart';
// import 'package:krishi_link/widgets/search_bar.dart';
// import 'package:krishi_link/core/lottie/popup_service.dart';

// class ManageProductsScreen extends StatefulWidget {
//   const ManageProductsScreen({super.key});

//   @override
//   State<ManageProductsScreen> createState() => _ManageProductsScreenState();
// }

// class _ManageProductsScreenState extends State<ManageProductsScreen> {
//   final AdminProductController controller =
//       Get.isRegistered()
//           ? Get.find<AdminProductController>()
//           : Get.put(AdminProductController());
//   final FilterController filterController =
//       Get.isRegistered()
//           ? Get.find<FilterController>()
//           : Get.put(FilterController());
//   final TextEditingController searchController = TextEditingController();
//   final RxString filterActiveStatus = 'all'.obs;

//   @override
//   void initState() {
//     super.initState();
//     final authController = Get.find<AuthController>();
//     if (authController.currentUser.value?.role != 'admin') {
//       Get.offAllNamed('/login');
//       PopupService.error(
//         'only_admins_can_access'.tr,
//         title: 'access_denied'.tr,
//       );
//       return;
//     }
//     if (!Get.isRegistered<ProductController>()) {
//       Get.put(ProductController());
//     }
//     if (!Get.isRegistered<FilterController>()) {
//       Get.put(FilterController());
//     }
//     controller.fetchProducts(
//       searchQuery: filterController.productSearchQuery.value,
//       selectedCategories: filterController.selectedCategories,
//       selectedLocations: filterController.selectedLocations,
//     );
//     searchController.text = filterController.productSearchQuery.value;
//     searchController.addListener(() {
//       filterController.searchProducts(searchController.text);
//       controller.fetchProducts(
//         searchQuery: filterController.productSearchQuery.value,
//         selectedCategories: filterController.selectedCategories,
//         selectedLocations: filterController.selectedLocations,
//       );
//     });
//   }

//   @override
//   void dispose() {
//     searchController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('manage_products'.tr),
//         backgroundColor: Theme.of(context).primaryColor,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed:
//                 () => controller.fetchProducts(
//                   searchQuery: filterController.productSearchQuery.value,
//                   selectedCategories: filterController.selectedCategories,
//                   selectedLocations: filterController.selectedLocations,
//                 ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _showProductDialog(context),
//         backgroundColor: Theme.of(context).primaryColor,
//         child: const Icon(Icons.add),
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.symmetric(
//               horizontal: 16.0,
//               vertical: 8.0,
//             ),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 Expanded(
//                   child: SearchBar(
//                     onSearch: (value) {
//                       filterController.searchProducts(value);
//                       controller.fetchProducts(
//                         searchQuery: filterController.productSearchQuery.value,
//                         selectedCategories: filterController.selectedCategories,
//                         selectedLocations: filterController.selectedLocations,
//                       );
//                     },
//                     searchController: searchController,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Obx(
//                   () => DropdownButton<String>(
//                     value: filterActiveStatus.value,
//                     items:
//                         ['all', 'active', 'inactive']
//                             .map(
//                               (status) => DropdownMenuItem(
//                                 value: status,
//                                 child: Text(status.tr.capitalizeFirst!),
//                               ),
//                             )
//                             .toList(),
//                     onChanged: (value) {
//                       if (value != null) {
//                         filterActiveStatus.value = value;
//                       }
//                     },
//                     underline: Container(),
//                     padding: const EdgeInsets.symmetric(horizontal: 8),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: Obx(
//               () =>
//                   controller.isLoading.value
//                       ? const Center(child: CircularProgressIndicator())
//                       : RefreshIndicator(
//                         onRefresh: () async {
//                           await controller.fetchProducts(
//                             searchQuery:
//                                 filterController.productSearchQuery.value,
//                             selectedCategories:
//                                 filterController.selectedCategories,
//                             selectedLocations:
//                                 filterController.selectedLocations,
//                           );
//                         },
//                         child:
//                             controller.products.isEmpty
//                                 ? Center(child: Text('no_products_found'.tr))
//                                 : ListView.builder(
//                                   itemCount: controller.products.length,
//                                   itemBuilder: (context, index) {
//                                     final product = controller.products[index];
//                                     if (filterActiveStatus.value != 'all' &&
//                                         ((filterActiveStatus.value ==
//                                                     'active' &&
//                                                 !product.isActive) ||
//                                             (filterActiveStatus.value ==
//                                                     'inactive' &&
//                                                 product.isActive))) {
//                                       return const SizedBox.shrink();
//                                     }
//                                     return Card(
//                                       margin: const EdgeInsets.symmetric(
//                                         horizontal: 8,
//                                         vertical: 4,
//                                       ),
//                                       elevation: 2,
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(12),
//                                       ),
//                                       child: ExpansionTile(
//                                         leading: ClipRRect(
//                                           borderRadius: BorderRadius.circular(
//                                             8,
//                                           ),
//                                           child: Image.network(
//                                             product.image,
//                                             width: 60,
//                                             height: 60,
//                                             fit: BoxFit.cover,
//                                             errorBuilder:
//                                                 (
//                                                   context,
//                                                   error,
//                                                   stackTrace,
//                                                 ) => Container(
//                                                   width: 60,
//                                                   height: 60,
//                                                   color: Colors.grey[300],
//                                                   child: const Icon(
//                                                     Icons.image_not_supported,
//                                                   ),
//                                                 ),
//                                           ),
//                                         ),
//                                         title: Text(
//                                           product.productName,
//                                           style: const TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                         ),
//                                         subtitle: Column(
//                                           crossAxisAlignment:
//                                               CrossAxisAlignment.start,
//                                           children: [
//                                             Text(
//                                               'Price: Rs.${product.rate}/${product.unit}',
//                                             ),
//                                             SwitchListTile(
//                                               title: Text(
//                                                 product.isActive
//                                                     ? 'Active'
//                                                     : 'Inactive',
//                                                 style: TextStyle(
//                                                   color:
//                                                       product.isActive
//                                                           ? Colors.green
//                                                           : Colors.red,
//                                                 ),
//                                               ),
//                                               value: product.isActive,
//                                               onChanged: (value) {
//                                                 controller
//                                                     .updateProductActiveStatus(
//                                                       product.id,
//                                                       value,
//                                                     );
//                                               },
//                                               contentPadding: EdgeInsets.zero,
//                                               dense: true,
//                                             ),
//                                           ],
//                                         ),
//                                         children: [
//                                           Padding(
//                                             padding: const EdgeInsets.all(16.0),
//                                             child: Column(
//                                               crossAxisAlignment:
//                                                   CrossAxisAlignment.start,
//                                               children: [
//                                                 Text(
//                                                   'Category: ${product.category}',
//                                                 ),
//                                                 Text(
//                                                   'Quantity: ${product.availableQuantity} ${product.unit}',
//                                                 ),
//                                                 if (product
//                                                     .location!
//                                                     .isNotEmpty)
//                                                   Text(
//                                                     'Location: ${product.location}',
//                                                   ),
//                                                 if (product
//                                                         .description
//                                                         .isNotEmpty &&
//                                                     product.description !=
//                                                         'No description')
//                                                   Text(
//                                                     'Description: ${product.description}',
//                                                   ),
//                                                 if (product
//                                                     .farmerName!
//                                                     .isNotEmpty)
//                                                   Text(
//                                                     'Farmer: ${product.farmerName}',
//                                                   ),
//                                                 const SizedBox(height: 16),
//                                                 Row(
//                                                   mainAxisAlignment:
//                                                       MainAxisAlignment
//                                                           .spaceEvenly,
//                                                   children: [
//                                                     ElevatedButton.icon(
//                                                       onPressed:
//                                                           () =>
//                                                               _showProductDialog(
//                                                                 context,
//                                                                 product:
//                                                                     product,
//                                                               ),
//                                                       icon: const Icon(
//                                                         Icons.edit,
//                                                       ),
//                                                       label: Text('edit'.tr),
//                                                       style: ElevatedButton.styleFrom(
//                                                         backgroundColor:
//                                                             Colors.blue,
//                                                         shape: RoundedRectangleBorder(
//                                                           borderRadius:
//                                                               BorderRadius.circular(
//                                                                 8,
//                                                               ),
//                                                         ),
//                                                       ),
//                                                     ),
//                                                     ElevatedButton.icon(
//                                                       onPressed:
//                                                           () => _confirmDelete(
//                                                             context,
//                                                             controller,
//                                                             product,
//                                                           ),
//                                                       icon: const Icon(
//                                                         Icons.delete,
//                                                       ),
//                                                       label: Text('delete'.tr),
//                                                       style: ElevatedButton.styleFrom(
//                                                         backgroundColor:
//                                                             Colors.red,
//                                                         shape: RoundedRectangleBorder(
//                                                           borderRadius:
//                                                               BorderRadius.circular(
//                                                                 8,
//                                                               ),
//                                                         ),
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ],
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     );
//                                   },
//                                 ),
//                       ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showProductDialog(BuildContext context, {Product? product}) {
//     Get.dialog(ProductFormDialog(product: product));
//   }

//   void _confirmDelete(
//     BuildContext context,
//     AdminProductController controller,
//     Product product,
//   ) {
//     Get.dialog(
//       AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Text(
//           'delete_product'.tr,
//           style: TextStyle(color: Theme.of(context).primaryColor),
//         ),
//         content: Text('confirm_delete_product'.trArgs([product.productName])),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(),
//             child: Text(
//               'cancel'.tr,
//               style: TextStyle(color: Colors.grey.shade700),
//             ),
//           ),
//           TextButton(
//             onPressed: () {
//               controller.deleteProduct(product.id);
//               Get.back();
//             },
//             child: Text(
//               'delete'.tr,
//               style: TextStyle(color: Theme.of(context).colorScheme.error),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
