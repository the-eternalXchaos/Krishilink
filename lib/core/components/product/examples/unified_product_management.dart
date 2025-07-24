import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/components/product/product_form.dart';
import 'package:krishi_link/core/components/product/product_form_data.dart';
import 'package:krishi_link/core/components/product/product_list_screen.dart';
import 'package:krishi_link/core/components/product/examples/unified_product_controller.dart';
import 'package:krishi_link/features/admin/models/product_model.dart';

/// Comprehensive example showing how to use the unified product management system
/// This example automatically adapts based on user role (Admin vs Farmer)
class UnifiedProductManagement extends StatelessWidget {
  UnifiedProductManagement({super.key});

  final UnifiedProductController controller =
      Get.isRegistered<UnifiedProductController>()
          ? Get.find<UnifiedProductController>()
          : Get.put(UnifiedProductController());

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ProductListScreen(
        products: controller.userProducts,
        isLoading: controller.isLoading,
        isAdmin: controller.currentUserRole.value == 'admin',
        title: _getTitle(),
        showActiveToggle: controller.currentUserRole.value == 'admin',
        showAddButton: true,
        onEdit: _editProduct,
        onDelete: _deleteProduct,
        onRefresh: _refreshProducts,
        onToggleActive:
            controller.currentUserRole.value == 'admin'
                ? _toggleProductActive
                : null,
        onAdd: _addProduct,
      ),
    );
  }

  String _getTitle() {
    return controller.currentUserRole.value == 'admin'
        ? 'manage_products'
        : 'my_products';
  }

  void _addProduct() {
    final controller =
        Get.isRegistered<UnifiedProductController>()
            ? Get.find<UnifiedProductController>()
            : Get.put(UnifiedProductController());
    Get.to(
      () => ProductForm(
        onSubmit: (formData, imagePath) async {
          await _handleProductSubmit(formData, imagePath);
        },
        submitButtonText: 'add_product'.tr,
      ),
    );
  }

  void _editProduct(Product product) {
    final controller =
        Get.isRegistered<UnifiedProductController>()
            ? Get.find<UnifiedProductController>()
            : Get.put(UnifiedProductController());
    // Check if user can edit this product
    if (controller.currentUserRole.value != 'admin' &&
        product.farmerId != controller.currentUserId.value) {
      Get.snackbar('error'.tr, 'cannot_edit_other_products'.tr);
      return;
    }

    Get.to(
      () => ProductForm(
        product: product,
        onSubmit: (formData, imagePath) async {
          await _handleProductUpdate(product, formData, imagePath);
        },
        submitButtonText: 'update_product'.tr,
      ),
    );
  }

  void _deleteProduct(Product product) {
    // Check if user can delete this product
    if (controller.currentUserRole.value != 'admin' &&
        product.farmerId != controller.currentUserId.value) {
      Get.snackbar('error'.tr, 'cannot_delete_other_products'.tr);
      return;
    }

    // Show role-specific confirmation dialog
    _showDeleteConfirmation(product);
  }

  void _showDeleteConfirmation(Product product) {
    final isAdmin = controller.currentUserRole.value == 'admin';

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'delete_product'.tr,
          style: TextStyle(color: Theme.of(Get.context!).primaryColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('confirm_delete_product'.trArgs([product.productName])),
            const SizedBox(height: 8),
            if (isAdmin) ...[
              Text(
                'admin_delete_warning'.tr,
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'farmer_name'.trArgs([product.farmerName ?? 'Unknown']),
                style: const TextStyle(fontSize: 12),
              ),
            ] else ...[
              Text(
                'farmer_delete_warning'.tr,
                style: TextStyle(color: Colors.orange[700], fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'cancel'.tr,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteProduct(product.id);
              _showDeleteSuccessMessage(product.productName);
            },
            child: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _refreshProducts() {
    controller.fetchProducts();
  }

  void _toggleProductActive(Product product, bool isActive) {
    controller.updateProductActiveStatus(product.id, isActive);
  }

  Future<void> _handleProductSubmit(
    ProductFormData formData,
    String? imagePath,
  ) async {
    try {
      await controller.addProduct(formData, imagePath);
      Get.back(); // Close form
      _showSuccessMessage('product_added_successfully'.tr);
    } catch (error) {
      Get.snackbar(
        'error'.tr,
        error.toString(),
        backgroundColor: Colors.red.withAlpha((0.8 * 255).toInt()),
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _handleProductUpdate(
    Product product,
    ProductFormData formData,
    String? imagePath,
  ) async {
    try {
      await controller.updateProduct(product.id, formData, imagePath);
      Get.back(); // Close form
      _showSuccessMessage('product_updated_successfully'.tr);
    } catch (error) {
      Get.snackbar('error'.tr, error.toString());
    }
  }

  void _showSuccessMessage(String message) {
    Get.snackbar(
      'success'.tr,
      message,
      backgroundColor: Colors.green.withAlpha((0.8 * 255).toInt()),
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  }

  void _showDeleteSuccessMessage(String productName) {
    Get.snackbar(
      'success'.tr,
      'product_deleted_successfully'.trArgs([productName]),
      backgroundColor: Colors.green.withAlpha((0.8 * 255).toInt()),
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  }
}

/// Example of how to integrate with your app's navigation
class ProductManagementPage extends StatelessWidget {
  const ProductManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return UnifiedProductManagement();
  }
}

/// Example of how to add to your routes
class ProductManagementRoutes {
  static const String productManagement = '/product-management';

  static List<GetPage> getRoutes() {
    return [
      GetPage(
        name: productManagement,
        page: () => const ProductManagementPage(),
        binding: ProductManagementBinding(),
      ),
    ];
  }
}

/// Example binding for dependency injection
class ProductManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UnifiedProductController>(() => UnifiedProductController());
  }
}

/// Example of how to navigate to product management from other screens
class NavigationExample {
  static void goToProductManagement() {
    Get.toNamed(ProductManagementRoutes.productManagement);
  }

  static void goToAddProduct() {
    final controller = Get.find<UnifiedProductController>();
    Get.to(
      () => ProductForm(
        onSubmit: (formData, imagePath) {
          return controller.addProduct(formData, imagePath).then((_) {
            Get.back();
            Get.snackbar('success'.tr, 'product_added_successfully'.tr);
          });
        },
      ),
    );
  }
}

/// Example of how to use the controller in other parts of your app
class ProductStatsWidget extends StatelessWidget {
  const ProductStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UnifiedProductController>();

    return Obx(() {
      final stats = controller.getProductStats();

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'product_statistics'.tr,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildStatRow('total_products'.tr, stats['total'].toString()),
              _buildStatRow('active_products'.tr, stats['active'].toString()),
              _buildStatRow(
                'inactive_products'.tr,
                stats['inactive'].toString(),
              ),
              _buildStatRow(
                'total_value'.tr,
                'Rs. ${stats['totalValue'].toStringAsFixed(2)}',
              ),
              _buildStatRow('categories'.tr, stats['categories'].toString()),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
