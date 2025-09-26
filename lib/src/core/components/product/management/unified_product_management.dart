import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/src/core/components/product/management/unified_product_api_services.dart';
import 'package:krishi_link/src/core/components/product/management/unified_product_controller.dart';
import 'package:krishi_link/src/core/components/product/product_form.dart';
import 'package:krishi_link/src/core/components/product/product_list_screen.dart';
import 'package:krishi_link/src/features/product/presentation/controllers/filter_controller.dart';
import 'package:krishi_link/src/features/product/data/models/product_model.dart';
import 'package:krishi_link/widgets/search_bar.dart' as custom;
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';

class UnifiedProductManagement extends StatefulWidget {
  const UnifiedProductManagement({super.key});

  @override
  State<UnifiedProductManagement> createState() =>
      _UnifiedProductManagementState();
}

class _UnifiedProductManagementState extends State<UnifiedProductManagement> {
  final UnifiedProductApiServices unifiedProductApiServices =
      Get.isRegistered<UnifiedProductApiServices>()
          ? Get.find<UnifiedProductApiServices>()
          : Get.put(UnifiedProductApiServices());
  final UnifiedProductController controller =
      Get.isRegistered<UnifiedProductController>()
          ? Get.find<UnifiedProductController>()
          : Get.put(UnifiedProductController());
  final FilterController filterController =
      Get.isRegistered<FilterController>()
          ? Get.find<FilterController>()
          : Get.put(FilterController());
  final AuthController authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    controller.fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        authController.currentUser.value?.role.toLowerCase() == 'admin';
    final isFarmer =
        authController.currentUser.value?.role.toLowerCase() == 'farmer';
    return ProductListScreen(
      products: controller.products,
      isLoading: controller.isLoading,
      isAdmin: isAdmin,
      isFarmer: isFarmer,
      showActiveToggle: isAdmin || isFarmer,
      showAddButton: isFarmer,
      title: 'Product Management',
      onEdit: (product) async {
        if (controller.isLoading.value) {
          debugPrint(
            '⚠️ [UnifiedProductManagement] Request still running, skipping edit.',
          );
          PopupService.error('Please wait for the current request to finish.');
          return;
        }
        if (product.id.isEmpty) {
          debugPrint(
            '❌ [UnifiedProductManagement] Invalid product ID: ${product.id}',
          );
          PopupService.error('Invalid product ID');
          return;
        }
        _showProductDialog(context, product: product);
      },
      onDelete: (product) {
        _confirmDelete(context, controller, product);
      },
      onRefresh: () async {
        await controller.fetchProducts(
          searchQuery: filterController.productSearchQuery.value,
          selectedCategories: filterController.selectedCategories.toList(),
          selectedLocations: filterController.selectedLocations.toList(),
          reset: true,
        );
      },
      onAdd: // add the delay
          () async {
        if (controller.isLoading.value) {
          debugPrint(
            '⚠️ [UnifiedProductManagement] Request still running, skipping add.',
          );
          PopupService.error('Please wait for the current request to finish.');
          return;
        }
        _showProductDialog(context, product: null);
      },
      onToggleActive: (product, value) async {
        try {
          debugPrint(
            '🔄 [UnifiedProductManagement] Toggling product ${product.id} to isActive: $value',
          );
          await controller.updateProductActiveStatusApi(product.id, value);
          debugPrint(
            '✅ [UnifiedProductManagement] Toggled product ${product.id} successfully',
          );
        } catch (e) {
          debugPrint(
            '❌ [UnifiedProductManagement] Failed to toggle product ${product.id}: $e',
          );
          PopupService.error('Failed to toggle product status: $e');
          rethrow;
        }
      },
    );
  }

  // Current code in _showProductDialog:
  void _showProductDialog(BuildContext context, {Product? product}) {
    Get.dialog(
      ProductForm(
        product: product,
        onSubmit: (formData, newImagePath) async {
          if (formData.productName.isEmpty ||
              formData.category.isEmpty ||
              formData.farmerContact.isEmpty ||
              formData.rate <= 0 ||
              formData.availableQuantity <= 0 ||
              (product == null && newImagePath == null)) {
            PopupService.error('Please fill all required fields');
            return;
          }
          try {
            controller.isLoading.value = true;
            if (product != null) {
              await controller.updateProduct(
                product.id,
                formData,
                newImagePath,
              );
              PopupService.success('Product updated successfully!');
            } else {
              await controller.addProduct(formData, newImagePath);
              PopupService.success('Product added successfully!');
            }
            // Get.back(); //TODO removed for nowo
          } catch (e) {
            PopupService.error('Failed to save product: $e');
          } finally {
            controller.isLoading.value = false;
          }
        },
      ),
      barrierDismissible: false,
    );
  }
  // void _showProductDialog(BuildContext context, {Product? product}) {
  //   debugPrint(
  //     '🔄 [UnifiedProductManagement] Opening product dialog for: ${product?.productName ?? 'new product'}',
  //   );
  //   Get.dialog(
  //     ProductForm(
  //       product: product,
  //       onSubmit: (formData, newImagePath) async {
  //         debugPrint(
  //           '🔄 [UnifiedProductManagement] onSubmit callback triggered',
  //         );
  //         debugPrint(
  //           '🔄 [UnifiedProductManagement] Form data: ${formData.productName}, ${formData.rate}, ${formData.category}',
  //         );
  //         debugPrint('🔄 [UnifiedProductManagement] Image path: $newImagePath');
  //         try {
  //           // Validate form data
  //           if (newImagePath != null) {
  //             debugPrint(
  //               '🔄 [UnifiedProductManagement] New image path provided: $newImagePath',
  //             );
  //           }
  //           if (formData.productName.isEmpty) {
  //             PopupService.error('Product name cannot be empty');
  //             return;
  //           }
  //           if (formData.rate <= 0) {
  //             PopupService.error('Rate must be greater than 0');
  //             return;
  //           }
  //           if (formData.category.isEmpty) {
  //             PopupService.error('Category cannot be empty');
  //             return;
  //           }

  //           if (product != null) {
  //             debugPrint(
  //               '🔄 [UnifiedProductManagement] Updating product: ${product.id}',
  //             );
  //             debugPrint(
  //               '🔄 [UnifiedProductManagement] Current cooldown status: ${controller.getCooldownStatus()}',
  //             );

  //             // Set loading state before calling controller
  //             controller.isLoading.value = true;
  //             try {
  //               await controller.updateProduct(
  //                 product.id,
  //                 formData,
  //                 newImagePath,
  //               );
  //               debugPrint(
  //                 '✅ [UnifiedProductManagement] Product updated successfully',
  //               );
  //             } finally {
  //               // Ensure loading is set to false after controller operation
  //               controller.isLoading.value = false;
  //               debugPrint(
  //                 '🔄 [UnifiedProductManagement] Loading state cleared after update',
  //               );
  //             }
  //           } else {
  //             debugPrint('🔄 [UnifiedProductManagement] Adding new product');
  //             debugPrint(
  //               '🔄 [UnifiedProductManagement] Current cooldown status: ${controller.getCooldownStatus()}',
  //             );

  //             // Set loading state before calling controller
  //             controller.isLoading.value = true;
  //             try {
  //               await controller.addProduct(formData, newImagePath);
  //               debugPrint(
  //                 '✅ [UnifiedProductManagement] Product added successfully',
  //               );
  //             } finally {
  //               // Ensure loading is set to false after controller operation
  //               controller.isLoading.value = false;
  //               debugPrint(
  //                 '🔄 [UnifiedProductManagement] Loading state cleared after add',
  //               );
  //             }
  //           }
  //           Get.back();
  //         } catch (e) {
  //           debugPrint('❌ [UnifiedProductManagement] Error in onSubmit: $e');
  //           PopupService.error('Failed to save product: $e');
  //           // Ensure loading is set to false on error
  //           controller.isLoading.value = false;
  //         }
  //       },
  //     ),
  //   );
  // }

  void _confirmDelete(
    BuildContext context,
    UnifiedProductController controller,
    Product product,
  ) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'delete_product'.tr,
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
        content: Text('confirm_delete_product'.trArgs([product.productName])),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'cancel'.tr,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                controller.isLoading.value = true;
                await controller.deleteProduct(product.id);
                debugPrint(
                  '✅ [UnifiedProductManagement] Product deleted: ${product.id}',
                );
                Get.back();
              } catch (e) {
                debugPrint(
                  '❌ [UnifiedProductManagement] Failed to delete product ${product.id}: $e',
                );
                PopupService.error('Failed to delete product: $e');
              } finally {
                controller.isLoading.value = false;
              }
            },
            child: Text(
              'delete'.tr,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  // Future<bool> _checkNetworkConnectivity() async {
  //   // Implement your network connectivity check here
  //   // For example, using the connectivity_plus package
  //   return true; // Placeholder, replace with actual check
  // }
}
