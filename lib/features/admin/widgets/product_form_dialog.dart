// // // import 'dart:io';

// // // import 'package:flutter/material.dart';
// // // import 'package:get/get.dart';
// // // import 'package:krishi_link/features/admin/models/product_model.dart';
// // // import 'package:krishi_link/features/admin/widgets/prouct_input_field.dart';

// // // class ProductFormDialog extends StatefulWidget {
// // //   final Product? product;
// // //   const ProductFormDialog({super.key, this.product});

// // //   @override
// // //   State<ProductFormDialog> createState() => _ProductFormDialogState();
// // // }

// // // class _ProductFormDialogState extends State<ProductFormDialog> {
// // //   late final TextEditingController nameController;
// // //   late final TextEditingController rateController;
// // //   late final TextEditingController quantityController;
// // //   late final TextEditingController categoryController;
// // //   late final TextEditingController locationController;
// // //   late final TextEditingController descriptionController;
// // //   late final TextEditingController phoneController;

// // //   File? selectedImage;

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     final product = widget.product;
// // //     nameController = TextEditingController(text: product?.productName ?? '');
// // //     rateController = TextEditingController(text: product?.rate ?? '');
// // //     quantityController = TextEditingController(
// // //       text: product?.availableQuantity.toString() ?? '',
// // //     );
// // //     categoryController = TextEditingController(text: product?.category ?? '');
// // //     locationController = TextEditingController(text: product?.location ?? '');
// // //     descriptionController = TextEditingController(
// // //       text: product?.description ?? '',
// // //     );
// // //     phoneController = TextEditingController(text: product?.farmerPhone ?? '');
// // //     // selectedImage = product?.image; // if using File, handle decoding from path
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Dialog(
// // //       child: SingleChildScrollView(
// // //         padding: const EdgeInsets.all(16),
// // //         child: Column(
// // //           mainAxisSize: MainAxisSize.min,
// // //           children: [
// // //             Text(
// // //               widget.product == null ? 'add_product'.tr : 'edit_product'.tr,
// // //               style: Theme.of(context).textTheme.titleLarge,
// // //             ),

// // //             const SizedBox(height: 12),

// // //             ProductInputField(
// // //               label: 'product_name',
// // //               controller: nameController,
// // //             ),
// // //             ProductInputField(
// // //               label: 'rate',
// // //               controller: rateController,
// // //               keyboardType: TextInputType.number,
// // //             ),
// // //             ProductInputField(
// // //               label: 'quantity',
// // //               controller: quantityController,
// // //               keyboardType: TextInputType.number,
// // //             ),
// // //             ProductInputField(
// // //               label: 'category',
// // //               controller: categoryController,
// // //             ),
// // //             ProductInputField(
// // //               label: 'location',
// // //               controller: locationController,
// // //             ),
// // //             ProductInputField(
// // //               label: 'description',
// // //               controller: descriptionController,
// // //               maxLines: 3,
// // //             ),
// // //             ProductInputField(
// // //               label: 'phone',
// // //               controller: phoneController,
// // //               keyboardType: TextInputType.phone,
// // //             ),

// // //             const SizedBox(height: 16),

// // //             selectedImage != null
// // //                 ? Image.file(selectedImage!, height: 120)
// // //                 : const Text('no_image_selected'),

// // //             const SizedBox(height: 12),

// // //             ElevatedButton(
// // //               onPressed: _submitForm,
// // //               child: Text(widget.product == null ? 'submit'.tr : 'update'.tr),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }

// // //   void _submitForm() {
// // //     final farmerName = nameController.text.trim();
// // //     final rate = rateController.text.trim();
// // //     final quantity = quantityController.text.trim();
// // //     final category = categoryController.text.trim();
// // //     final location = locationController.text.trim();
// // //     final description = descriptionController.text.trim();
// // //     final phone = phoneController.text.trim();

// // //     if ([
// // //       farmerName,
// // //       rate,
// // //       quantity,
// // //       category,
// // //       location,
// // //       phone,
// // //     ].any((v) => v.isEmpty)) {
// // //       Get.snackbar('error'.tr, 'please_fill_all_fields'.tr);
// // //       return;
// // //     }

// // //     final product = Product(
// // //       productName: farmerName,
// // //       rate: rate,
// // //       availableQuantity: quantity,
// // //       category: category,
// // //       location: location,
// // //       description: description,
// // //       farmerPhone: phone,
// // //       image: selectedImage,
// // //       id: '',
// // //       unit: '',
// // //       soldedQuantity: '',
// // //       farmerId: '',
// // //       farmerName: '',
// // //     );

// // //     if (widget.product == null) {
// // //       // TODO: Add product via controller
// // //     } else {
// // //       // TODO: Update product via controller
// // //     }

// // //     Navigator.of(context).pop(); // Close dialog
// // //   }
// // // }
// // import 'dart:io';
// // import 'package:file_picker/file_picker.dart';
// // import 'package:flutter/material.dart';
// // import 'package:get/get.dart';
// // import 'package:krishi_link/features/admin/controllers/admin_product_controller.dart';
// // import 'package:krishi_link/features/admin/models/product_model.dart';
// // import 'package:krishi_link/features/admin/widgets/prouct_input_field.dart';

// // class ProductFormDialog extends StatefulWidget {
// //   final Product? product;
// //   const ProductFormDialog({super.key, this.product});

// //   @override
// //   State<ProductFormDialog> createState() => _ProductFormDialogState();
// // }

// // class _ProductFormDialogState extends State<ProductFormDialog> {
// //   final formKey = GlobalKey<FormState>();
// //   late final TextEditingController nameController;
// //   late final TextEditingController rateController;
// //   late final TextEditingController quantityController;
// //   late final TextEditingController categoryController;
// //   late final TextEditingController locationController;
// //   late final TextEditingController descriptionController;
// //   late final TextEditingController phoneController;
// //   final AdminProductController controller = Get.find<AdminProductController>();
// //   File? selectedImage;
// //   RxString selectedCategory = 'Vegetable'.obs;
// //   RxString farmerName = ''.obs;
// //   RxString farmerId = ''.obs;
// //   RxBool isFetchingFarmer = false.obs;

// //   @override
// //   void initState() {
// //     super.initState();
// //     final product = widget.product;
// //     nameController = TextEditingController(text: product?.productName ?? '');
// //     rateController = TextEditingController(text: product?.rate.toString() ??'' );
// //     quantityController = TextEditingController(
// //       text: product?.availableQuantity.toString() ?? '',
// //     );
// //     categoryController = TextEditingController(
// //       text: product?.category ?? 'Vegetable',
// //     );
// //     selectedCategory.value = product?.category ?? 'Vegetable';
// //     locationController = TextEditingController(text: product?.location ?? '');
// //     descriptionController = TextEditingController(
// //       text: product?.description ?? '',
// //     );
// //     phoneController = TextEditingController(text: product?.farmerPhone ?? '');
// //     farmerName.value = product?.farmerName ?? '';
// //     farmerId.value = product?.farmerId ?? '';
// //     // Do not load image as File for editing, rely on API URL
// //     phoneController.addListener(() {
// //       if (phoneController.text.length >= 10) {
// //         _fetchFarmerDetails(phoneController.text);
// //       }
// //     });
// //   }

// //   Future<void> _fetchFarmerDetails(String phone) async {
// //     isFetchingFarmer.value = true;
// //     try {
// //       final response = await controller.fetchFarmerDetails(phone);
// //       farmerName.value = response['farmerName'] ?? '';
// //       farmerId.value = response['farmerId'] ?? '';
// //       if (farmerName.value.isEmpty) {
// //         Get.snackbar('warning'.tr, 'farmer_not_found'.tr);
// //       }
// //     } catch (e) {
// //       Get.snackbar('error'.tr, 'failed_to_fetch_farmer'.tr);
// //     } finally {
// //       isFetchingFarmer.value = false;
// //     }
// //   }

// //   @override
// //   void dispose() {
// //     nameController.dispose();
// //     rateController.dispose();
// //     quantityController.dispose();
// //     categoryController.dispose();
// //     locationController.dispose();
// //     descriptionController.dispose();
// //     phoneController.dispose();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Dialog(
// //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
// //       child: Container(
// //         padding: const EdgeInsets.all(20),
// //         decoration: BoxDecoration(
// //           color: Theme.of(context).scaffoldBackgroundColor,
// //           borderRadius: BorderRadius.circular(16),
// //         ),
// //         child: Form(
// //           key: formKey,
// //           child: SingleChildScrollView(
// //             child: Column(
// //               mainAxisSize: MainAxisSize.min,
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(
// //                   widget.product == null ? 'add_product'.tr : 'edit_product'.tr,
// //                   style: Theme.of(context).textTheme.headlineSmall?.copyWith(
// //                     fontWeight: FontWeight.bold,
// //                     color: Theme.of(context).primaryColor,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 20),
// //                 ProductInputField(
// //                   label: 'product_name',
// //                   controller: nameController,
// //                   validator: (value) => value!.isEmpty ? 'required'.tr : null,
// //                 ),
// //                 ProductInputField(
// //                   label: 'rate',
// //                   controller: rateController,
// //                   keyboardType: TextInputType.number,
// //                   validator: (value) => value!.isEmpty ? 'required'.tr : null,
// //                 ),
// //                 ProductInputField(
// //                   label: 'quantity',
// //                   controller: quantityController,
// //                   keyboardType: TextInputType.number,
// //                   validator: (value) => value!.isEmpty ? 'required'.tr : null,
// //                 ),
// //                 Obx(
// //                   () => DropdownButtonFormField<String>(
// //                     value: selectedCategory.value,
// //                     items:
// //                         ['Vegetable', 'Seeds', 'Fruit']
// //                             .map(
// //                               (category) => DropdownMenuItem(
// //                                 value: category,
// //                                 child: Text(category.tr),
// //                               ),
// //                             )
// //                             .toList(),
// //                     onChanged: (value) {
// //                       if (value != null) {
// //                         selectedCategory.value = value;
// //                         categoryController.text = value;
// //                       }
// //                     },
// //                     decoration: InputDecoration(
// //                       labelText: 'category'.tr,
// //                       border: OutlineInputBorder(
// //                         borderRadius: BorderRadius.circular(12),
// //                       ),
// //                       prefixIcon: Icon(
// //                         Icons.category,
// //                         color: Theme.of(context).primaryColor,
// //                       ),
// //                       filled: true,
// //                       fillColor: Theme.of(
// //                         context,
// //                       ).colorScheme.surface.withValues(alpha: 30),
// //                     ),
// //                     validator: (value) => value == null ? 'required'.tr : null,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 16),
// //                 ProductInputField(
// //                   label: 'location',
// //                   controller: locationController,
// //                   validator: (value) => value!.isEmpty ? 'required'.tr : null,
// //                 ),
// //                 ProductInputField(
// //                   label: 'farmer_phone',
// //                   controller: phoneController,
// //                   keyboardType: TextInputType.phone,
// //                   validator: (value) => value!.isEmpty ? 'required'.tr : null,
// //                 ),
// //                 ProductInputField(
// //                   label: 'description',
// //                   controller: descriptionController,
// //                   maxLines: 3,
// //                 ),
// //                 Obx(
// //                   () =>
// //                       isFetchingFarmer.value
// //                           ? const Padding(
// //                             padding: EdgeInsets.symmetric(vertical: 8),
// //                             child: CircularProgressIndicator(),
// //                           )
// //                           : farmerName.value.isNotEmpty
// //                           ? Padding(
// //                             padding: const EdgeInsets.symmetric(vertical: 8),
// //                             child: Text(
// //                               'Farmer: ${farmerName.value}',
// //                               style: TextStyle(
// //                                 color: Colors.green.shade700,
// //                                 fontWeight: FontWeight.bold,
// //                               ),
// //                             ),
// //                           )
// //                           : const SizedBox.shrink(),
// //                 ),
// //                 const SizedBox(height: 20),
// //                 ElevatedButton.icon(
// //                   onPressed: () async {
// //                     final result = await FilePicker.platform.pickFiles(
// //                       type: FileType.image,
// //                     );
// //                     if (result != null && result.files.single.path != null) {
// //                       setState(() {
// //                         selectedImage = File(result.files.single.path!);
// //                       });
// //                       Get.snackbar('success'.tr, 'image_selected'.tr);
// //                     }
// //                   },
// //                   icon: const Icon(Icons.image),
// //                   label: Text('select_image'.tr),
// //                   style: ElevatedButton.styleFrom(
// //                     backgroundColor: Theme.of(context).primaryColor,
// //                     foregroundColor: Colors.white,
// //                     shape: RoundedRectangleBorder(
// //                       borderRadius: BorderRadius.circular(8),
// //                     ),
// //                     padding: const EdgeInsets.symmetric(
// //                       vertical: 12,
// //                       horizontal: 16,
// //                     ),
// //                   ),
// //                 ),
// //                 if (selectedImage != null)
// //                   Padding(
// //                     padding: const EdgeInsets.only(top: 10),
// //                     child: Image.file(
// //                       selectedImage!,
// //                       height: 120,
// //                       fit: BoxFit.cover,
// //                     ),
// //                   )
// //                 else if (widget.product != null &&
// //                     widget.product!.image.isNotEmpty)
// //                   Padding(
// //                     padding: const EdgeInsets.only(top: 10),
// //                     child: Image.network(
// //                       widget.product!.image,
// //                       height: 120,
// //                       fit: BoxFit.cover,
// //                       errorBuilder:
// //                           (context, error, stackTrace) =>
// //                               const Icon(Icons.image_not_supported),
// //                     ),
// //                   ),
// //                 const SizedBox(height: 20),
// //                 Row(
// //                   mainAxisAlignment: MainAxisAlignment.end,
// //                   children: [
// //                     TextButton(
// //                       onPressed: () => Get.back(),
// //                       child: Text(
// //                         'cancel'.tr,
// //                         style: TextStyle(
// //                           color: Theme.of(context).colorScheme.error,
// //                         ),
// //                       ),
// //                     ),
// //                     const SizedBox(width: 10),
// //                     ElevatedButton(
// //                       onPressed: _submitForm,
// //                       style: ElevatedButton.styleFrom(
// //                         backgroundColor: Theme.of(context).primaryColor,
// //                         shape: RoundedRectangleBorder(
// //                           borderRadius: BorderRadius.circular(8),
// //                         ),
// //                         padding: const EdgeInsets.symmetric(
// //                           horizontal: 20,
// //                           vertical: 12,
// //                         ),
// //                       ),
// //                       child: Text(
// //                         widget.product == null ? 'add'.tr : 'save'.tr,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   void _submitForm() {
// //     if (formKey.currentState!.validate() &&
// //         (selectedImage != null || widget.product!.image.isNotEmpty)) {
// //       if (phoneController.text.isNotEmpty &&
// //           farmerName.value.isEmpty &&
// //           farmerId.value.isEmpty) {
// //         Get.snackbar('error'.tr, 'farmer_not_found'.tr);
// //         return;
// //       }
// //       final productData = Product(
// //         id: widget.product?.id ?? '',
// //         productName: nameController.text.trim(),
// //         rate: rateController.text.toString() .trim(),
// //         availableQuantity: quantityController.text.toString().trim(),
// //         category: selectedCategory.value,
// //         location: locationController.text.trim(),
// //         description:
// //             descriptionController.text.trim().isEmpty
// //                 ? 'No description'
// //                 : descriptionController.text.trim(),
// //         farmerPhone: phoneController.text.trim(),
// //         farmerName: farmerName.value,
// //         farmerId: farmerId.value,
// //         image: selectedImage?.path ?? widget.product?.image ?? '',
// //         unit: widget.product?.unit ?? 'kg',
// //         soldedQuantity: widget.product?.soldedQuantity ?? 0,
// //         createdAt: widget.product?.createdAt ?? DateTime.now(),
// //         updatedAt: DateTime.now(),
// //         isActive: widget.product?.isActive ?? true,
// //       );

// //       if (widget.product == null) {
// //         controller.createProduct(
// //           productName: productData.productName,
// //           rate: productData.rate,
// //           availableQuantity: productData.availableQuantity,
// //           category: productData.category,
// //           location: productData.location,
// //           image: selectedImage!,
// //           description:
// //               productData.description == 'No description'
// //                   ? null
// //                   : productData.description,
// //           farmerPhoneOrEmail: productData.farmerPhone,
// //           farmerName: productData.farmerName,
// //           farmerId: productData.farmerId,
// //         );
// //       } else {
// //         controller.updateProduct(
// //           productData.id,
// //           productName: productData.productName,
// //           rate: productData.rate,
// //           availableQuantity: productData.availableQuantity,
// //           category: productData.category,
// //           location: productData.location,
// //           image: selectedImage,
// //           description:
// //               productData.description == 'No description'
// //                   ? null
// //                   : productData.description,
// //           farmerPhone: productData.farmerPhone,
// //           farmerName: productData.farmerName,
// //           farmerId: productData.farmerId,
// //           isActive: productData.isActive,
// //         );
// //       }
// //       Get.back();
// //     } else {
// //       Get.snackbar('error'.tr, 'required_fields_missing'.tr);
// //     }
// //   }
// // }
// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:krishi_link/core/components/product/examples/unified_product_controller.dart';
// import 'package:krishi_link/features/admin/controllers/admin_product_controller.dart';
// import 'package:krishi_link/features/admin/controllers/admin_user_controller.dart';
// import 'package:krishi_link/features/admin/models/product_model.dart';
// import 'package:krishi_link/features/admin/widgets/prouct_input_field.dart';
// import 'package:krishi_link/core/lottie/popup_service.dart';

// class ProductFormDialog extends StatefulWidget {
//   final Product? product;
//   const ProductFormDialog({super.key, this.product});

//   @override
//   State<ProductFormDialog> createState() => _ProductFormDialogState();
// }

// class _ProductFormDialogState extends State<ProductFormDialog> {
//   final formKey = GlobalKey<FormState>();
//   late final TextEditingController nameController;
//   late final TextEditingController rateController;
//   late final TextEditingController quantityController;
//   late final TextEditingController categoryController;
//   late final TextEditingController locationController;
//   late final TextEditingController descriptionController;
//   late final TextEditingController phoneController;
//   final AdminUserController adminUserController =
//       Get.isRegistered<AdminUserController>()
//           ? Get.find<AdminUserController>()
//           : Get.put(AdminUserController());
//   final UnifiedProductController controller =
//       Get.isRegistered<UnifiedProductController>()
//           ? Get.find<UnifiedProductController>()
//           : Get.put(UnifiedProductController());
//   File? selectedImage;
//   RxString selectedCategory = 'Vegetable'.obs;
//   RxString farmerName = ''.obs;
//   RxString farmerId = ''.obs;
//   RxBool isFetchingFarmer = false.obs;

//   @override
//   void initState() {
//     super.initState();
//     final product = widget.product;
//     nameController = TextEditingController(text: product?.productName ?? '');
//     rateController = TextEditingController(
//       text: product?.rate != null ? product!.rate.toStringAsFixed(2) : '',
//     );
//     quantityController = TextEditingController(
//       text:
//           product?.availableQuantity != null
//               ? product!.availableQuantity.toStringAsFixed(2)
//               : '',
//     );
//     categoryController = TextEditingController(
//       text: product?.category ?? 'Vegetable',
//     );
//     selectedCategory.value = product?.category ?? 'Vegetable';
//     locationController = TextEditingController(text: product?.location ?? '');
//     descriptionController = TextEditingController(
//       text: product?.description ?? '',
//     );
//     phoneController = TextEditingController(text: product?.farmerPhone ?? '');
//     farmerName.value = product?.farmerName ?? '';
//     farmerId.value = product?.farmerId ?? '';
//     phoneController.addListener(() {
//       if (phoneController.text.length >= 10) {
//         _fetchFarmerDetails(phoneController.text);
//       }
//     });
//   }

//   // at the form if the number is not found then show  show the email  so
//   // and if the email is not found then show the number

//   // this is for  adding the product by the admin by using the phone number or email

//   Future<void> _fetchFarmerDetails(String phone) async {
//     isFetchingFarmer.value = true;
//     try {
//       final response = await adminUserController.fetchFarmerDetails(phone);
//       farmerName.value = response['farmerName'] ?? '';
//       farmerId.value = response['farmerId'] ?? '';
//       if (farmerName.value.isEmpty) {
//         PopupService.warning('farmer_not_found'.tr);
//       }
//     } catch (e) {
//       PopupService.error('failed_to_fetch_farmer'.tr);
//     } finally {
//       isFetchingFarmer.value = false;
//     }
//   }

//   @override
//   void dispose() {
//     nameController.dispose();
//     rateController.dispose();
//     quantityController.dispose();
//     categoryController.dispose();
//     locationController.dispose();
//     descriptionController.dispose();
//     phoneController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Container(
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: Theme.of(context).scaffoldBackgroundColor,
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Form(
//           key: formKey,
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   widget.product == null ? 'add_product'.tr : 'edit_product'.tr,
//                   style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                     fontWeight: FontWeight.bold,
//                     color: Theme.of(context).primaryColor,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 ProductInputField(
//                   label: 'product_name',
//                   controller: nameController,
//                   validator: (value) => value!.isEmpty ? 'required'.tr : null,
//                 ),
//                 ProductInputField(
//                   label: 'rate',
//                   controller: rateController,
//                   keyboardType: TextInputType.number,
//                   validator: (value) {
//                     if (value!.isEmpty) return 'required'.tr;
//                     if (double.tryParse(value) == null ||
//                         double.parse(value) <= 0) {
//                       return 'invalid_rate'.tr;
//                     }
//                     return null;
//                   },
//                 ),
//                 ProductInputField(
//                   label: 'quantity',
//                   controller: quantityController,
//                   keyboardType: TextInputType.number,
//                   validator: (value) {
//                     if (value!.isEmpty) return 'required'.tr;
//                     if (double.tryParse(value) == null ||
//                         double.parse(value) <= 0) {
//                       return 'invalid_quantity'.tr;
//                     }
//                     return null;
//                   },
//                 ),
//                 Obx(
//                   () => DropdownButtonFormField<String>(
//                     value: selectedCategory.value,
//                     items:
//                         ['Vegetable', 'Seeds', 'Fruit']
//                             .map(
//                               (category) => DropdownMenuItem(
//                                 value: category,
//                                 child: Text(category.tr),
//                               ),
//                             )
//                             .toList(),
//                     onChanged: (value) {
//                       if (value != null) {
//                         selectedCategory.value = value;
//                         categoryController.text = value;
//                       }
//                     },
//                     decoration: InputDecoration(
//                       labelText: 'category'.tr,
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       prefixIcon: Icon(
//                         Icons.category,
//                         color: Theme.of(context).primaryColor,
//                       ),
//                       filled: true,
//                       fillColor: Theme.of(
//                         context,
//                       ).colorScheme.surface.withValues(alpha: 30),
//                     ),
//                     validator: (value) => value == null ? 'required'.tr : null,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 ProductInputField(
//                   label: 'location',
//                   controller: locationController,
//                   validator: (value) => value!.isEmpty ? 'required'.tr : null,
//                 ),
//                 ProductInputField(
//                   label: 'farmer_phone',
//                   controller: phoneController,
//                   keyboardType: TextInputType.phone,
//                   validator: (value) => value!.isEmpty ? 'required'.tr : null,
//                 ),
//                 ProductInputField(
//                   label: 'description',
//                   controller: descriptionController,
//                   maxLines: 3,
//                 ),
//                 Obx(
//                   () =>
//                       isFetchingFarmer.value
//                           ? const Padding(
//                             padding: EdgeInsets.symmetric(vertical: 8),
//                             child: CircularProgressIndicator(),
//                           )
//                           : farmerName.value.isNotEmpty
//                           ? Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 8),
//                             child: Text(
//                               'Farmer: ${farmerName.value}',
//                               style: TextStyle(
//                                 color: Colors.green.shade700,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           )
//                           : const SizedBox.shrink(),
//                 ),
//                 const SizedBox(height: 20),
//                 ElevatedButton.icon(
//                   onPressed: () async {
//                     final result = await FilePicker.platform.pickFiles(
//                       type: FileType.image,
//                     );
//                     if (result != null && result.files.single.path != null) {
//                       setState(() {
//                         selectedImage = File(result.files.single.path!);
//                       });
//                       PopupService.success('image_selected'.tr);
//                     }
//                   },
//                   icon: const Icon(Icons.image),
//                   label: Text('select_image'.tr),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Theme.of(context).primaryColor,
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     padding: const EdgeInsets.symmetric(
//                       vertical: 12,
//                       horizontal: 16,
//                     ),
//                   ),
//                 ),
//                 if (selectedImage != null)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 10),
//                     child: Image.file(
//                       selectedImage!,
//                       height: 120,
//                       fit: BoxFit.cover,
//                     ),
//                   )
//                 else if (widget.product != null &&
//                     widget.product!.image.isNotEmpty)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 10),
//                     child: Image.network(
//                       widget.product!.image,
//                       height: 120,
//                       fit: BoxFit.cover,
//                       errorBuilder:
//                           (context, error, stackTrace) =>
//                               const Icon(Icons.image_not_supported),
//                     ),
//                   ),
//                 const SizedBox(height: 20),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     TextButton(
//                       onPressed: () => Get.back(),
//                       child: Text(
//                         'cancel'.tr,
//                         style: TextStyle(
//                           color: Theme.of(context).colorScheme.error,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     ElevatedButton(
//                       onPressed: _submitForm,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Theme.of(context).primaryColor,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 20,
//                           vertical: 12,
//                         ),
//                       ),
//                       child: Text(
//                         widget.product == null ? 'add'.tr : 'save'.tr,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   void _submitForm() {
//     if (formKey.currentState!.validate()) {
//       final rate = double.tryParse(rateController.text.trim());
//       final quantity = double.tryParse(quantityController.text.trim());

//       if (rate == null || rate <= 0) {
//         PopupService.error('invalid_rate'.tr);
//         return;
//       }
//       if (quantity == null || quantity <= 0) {
//         PopupService.error('invalid_quantity'.tr);
//         return;
//       }
//       if (phoneController.text.isNotEmpty &&
//           farmerName.value.isEmpty &&
//           farmerId.value.isEmpty) {
//         PopupService.error('farmer_not_found'.tr);
//         return;
//       }
//       if (selectedImage == null &&
//           (widget.product == null || widget.product!.image.isEmpty)) {
//         PopupService.error('image_required'.tr);
//         return;
//       }

//       final productData = Product(
//         id: widget.product?.id ?? '',
//         productName: nameController.text.trim(),
//         rate: rate,
//         availableQuantity: quantity,
//         category: selectedCategory.value,
//         location: locationController.text.trim(),
//         description:
//             descriptionController.text.trim().isEmpty
//                 ? 'No description'
//                 : descriptionController.text.trim(),
//         farmerPhone: phoneController.text.trim(),
//         farmerName: farmerName.value,
//         farmerId: farmerId.value,
//         image: selectedImage?.path ?? widget.product?.image ?? '',
//         unit: widget.product?.unit ?? 'kg',
//         soldedQuantity: widget.product?.soldedQuantity ?? 0.0,
//         createdAt: widget.product?.createdAt ?? DateTime.now(),
//         updatedAt: DateTime.now(),
//         isActive: widget.product?.isActive ?? true,
//         latitude: 0,
//         longitude: 0,
//       );

//       if (widget.product == null) {
//         controller.createProduct(
//           productName: productData.productName,
//           rate: productData.rate.toString(),
//           availableQuantity: productData.availableQuantity.toString(),
//           category: productData.category,
//           location: productData.location as String,
//           image: selectedImage!,
//           description:
//               productData.description == 'No description'
//                   ? null
//                   : productData.description,
//           farmerPhoneOrEmail: productData.farmerPhone,
//           // farmerName: productData.farmerName,
//           // farmerId: productData.farmerId,
//         );
//       } else {
//         controller.updateProduct(
//           productData.id,
//           productName: productData.productName,
//           rate: productData.rate.toString(),
//           availableQuantity: productData.availableQuantity.toString(),
//           category: productData.category,
//           location: productData.location,
//           image: selectedImage,
//           description:
//               productData.description == 'No description'
//                   ? null
//                   : productData.description,
//           farmerPhone: productData.farmerPhone,
//           farmerName: productData.farmerName,
//           farmerId: productData.farmerId,
//           isActive: productData.isActive,
//         );
//       }
//       Get.back();
//     } else {
//       PopupService.error('required_fields_missing'.tr);
//     }
//   }
// }
