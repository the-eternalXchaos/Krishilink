// import 'dart:io';
// import 'package:flutter/material.dart' hide SearchBar;
// import 'package:get/get.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:krishi_link/core/utils/constants.dart';
// import 'package:krishi_link/features/admin/models/product_model.dart';
// import 'package:krishi_link/features/auth/controller/auth_controller.dart';
// import 'package:krishi_link/features/farmer/controller/farmer_controller.dart';
// import 'package:krishi_link/widgets/search_bar.dart';
// import 'package:krishi_link/core/components/product/product_form.dart';
// import 'package:krishi_link/core/components/product/product_form_data.dart';

// class FarmerProductManagementScreen extends StatefulWidget {
//   const FarmerProductManagementScreen({super.key});

//   @override
//   State<FarmerProductManagementScreen> createState() =>
//       _FarmerProductManagementScreenState();
// }

// class _FarmerProductManagementScreenState
//     extends State<FarmerProductManagementScreen> {
//   final FarmerController controller =
//       Get.isRegistered<FarmerController>()
//           ? Get.find<FarmerController>()
//           : Get.put(FarmerController());
//   final TextEditingController searchController = TextEditingController();
//   final RxString filterActiveStatus = 'all'.obs;

//   @override
//   void initState() {
//     super.initState();
//     Future.delayed(Duration.zero, _fetchAndSetProducts);
//     searchController.addListener(_applyFilters);
//   }

//   Future<void> _fetchAndSetProducts() async {
//     await controller.fetchProducts(); //TODO: change to unified product controller
//     _applyFilters();
//   }

//   void _applyFilters() {
//     final query = searchController.text.toLowerCase();
//     final status = filterActiveStatus.value;
//     controller.filteredProducts.assignAll(
//       controller.products.where((p) {
//         final matchesQuery =
//             p.productName.toLowerCase().contains(query) ||
//             p.category.toLowerCase().contains(query) ||
//             (p.location ?? '').toLowerCase().contains(query);
//         final matchesStatus =
//             status == 'all' ||
//             (status == 'active' && p.isActive) ||
//             (status == 'inactive' && !p.isActive);
//         return matchesQuery && matchesStatus;
//       }).toList(),
//     );
//   }

//   void _showProductDialog({Product? product}) {
//     Get.dialog(
//       Dialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         child: SizedBox(
//           width: 500,
//           child: ProductForm(
//             product: product,
//             onSubmit: (formData, imagePath) async {
//               if (product == null) {
//                 await controller.addProductFromForm(formData, imagePath);
//               } else {
//                 
// tFromForm(
//                   product.id,
//                   formData,
//                   imagePath,
//                 );
//               }
//               Get.back();
//               await _fetchAndSetProducts();
//               Get.back();
//             },
//             submitButtonText:
//                 product == null ? 'add_product'.tr : 'update_product'.tr,
//           ),
//         ),
//       ),
//     );
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
//         title: Text('my_products'.tr),
//         backgroundColor: Theme.of(context).primaryColor,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _fetchAndSetProducts,
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _showProductDialog(),
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
//                     onSearch: (value) => _applyFilters(),
//                     searchController: searchController,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Obx(
//                   () => DropdownButton<String>(
//                     value: filterActiveStatus.value,
//                     items: [
//                       DropdownMenuItem(value: 'all', child: Text('All'.tr)),
//                       DropdownMenuItem(
//                         value: 'active',
//                         child: Text('Active'.tr),
//                       ),
//                       DropdownMenuItem(
//                         value: 'inactive',
//                         child: Text('Inactive'.tr),
//                       ),
//                     ],
//                     onChanged: (value) {
//                       if (value != null) {
//                         filterActiveStatus.value = value;
//                         _applyFilters();
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
//                         onRefresh: _fetchAndSetProducts,
//                         child:
//                             controller.filteredProducts.isEmpty
//                                 ? Center(child: Text('no_products_found'.tr))
//                                 : ListView.builder(
//                                   itemCount: controller.filteredProducts.length,
//                                   itemBuilder: (context, index) {
//                                     final product =
//                                         controller.filteredProducts[index];
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
//                                           child:
//                                               product.image.isNotEmpty
//                                                   ? Image.network(
//                                                     product.image,
//                                                     width: 60,
//                                                     height: 60,
//                                                     fit: BoxFit.cover,
//                                                     errorBuilder:
//                                                         (
//                                                           context,
//                                                           error,
//                                                           stackTrace,
//                                                         ) => Container(
//                                                           width: 60,
//                                                           height: 60,
//                                                           color:
//                                                               Colors.grey[300],
//                                                           child: const Icon(
//                                                             Icons
//                                                                 .image_not_supported,
//                                                           ),
//                                                         ),
//                                                   )
//                                                   : Container(
//                                                     width: 60,
//                                                     height: 60,
//                                                     color: Colors.grey[300],
//                                                     child: const Icon(
//                                                       Icons.image,
//                                                     ),
//                                                   ),
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
//                                             Text(
//                                               product.isActive
//                                                   ? 'Active'.tr
//                                                   : 'Inactive'.tr,
//                                               style: TextStyle(
//                                                 color:
//                                                     product.isActive
//                                                         ? Colors.green
//                                                         : Colors.red,
//                                               ),
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
//                                                 if ((product.location ?? '')
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
//                                                 // Add toggle for active/inactive status
//                                                 SwitchListTile(
//                                                   title: Text(
//                                                     product.isActive
//                                                         ? 'Active'.tr
//                                                         : 'Inactive'.tr,
//                                                     style: TextStyle(
//                                                       color:
//                                                           product.isActive
//                                                               ? Colors.green
//                                                               : Colors.red,
//                                                     ),
//                                                   ),
//                                                   value: product.isActive,
//                                                   onChanged: (value) async {
//                                                     await controller
//                                                         .updateProductActiveStatus(
//                                                           product.id,
//                                                           value,
//                                                         );
//                                                     await _fetchAndSetProducts();
//                                                   },
//                                                   contentPadding:
//                                                       EdgeInsets.zero,
//                                                   dense: true,
//                                                 ),
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
//                                                       onPressed: () async {
//                                                         final confirm = await Get.dialog<
//                                                           bool
//                                                         >(
//                                                           AlertDialog(
//                                                             title: Text(
//                                                               'confirm_delete'
//                                                                   .tr,
//                                                             ),
//                                                             content: Text(
//                                                               'delete_product_confirmation'
//                                                                   .trParams({
//                                                                     'name':
//                                                                         product
//                                                                             .productName,
//                                                                   }),
//                                                             ),
//                                                             actions: [
//                                                               TextButton(
//                                                                 onPressed:
//                                                                     () => Get.back(
//                                                                       result:
//                                                                           false,
//                                                                     ),
//                                                                 child: Text(
//                                                                   'cancel'.tr,
//                                                                 ),
//                                                               ),
//                                                               TextButton(
//                                                                 onPressed:
//                                                                     () => Get.back(
//                                                                       result:
//                                                                           true,
//                                                                     ),
//                                                                 child: Text(
//                                                                   'delete'.tr,
//                                                                 ),
//                                                               ),
//                                                             ],
//                                                           ),
//                                                         );
//                                                         if (confirm == true) {
//                                                           await controller
//                                                               .deleteProduct(
//                                                                 product.id,
//                                                               );
//                                                           await _fetchAndSetProducts();
//                                                         }
//                                                       },
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
// }
