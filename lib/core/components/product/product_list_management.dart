import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/features/admin/models/product_model.dart';

class ProductListManagement extends StatelessWidget {
  final Product product;
  final bool isAdmin;
  final bool isFarmer;
  final bool showActiveToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(bool)? onToggleActive;
  final RxMap<String, bool> toggleLoading;

  const ProductListManagement({
    super.key,
    required this.product,
    required this.isAdmin,
    required this.isFarmer,
    required this.showActiveToggle,
    required this.onEdit,
    required this.onDelete,
    this.onToggleActive,
    required this.toggleLoading,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final toggleKey = product.id;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ExpansionTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            product.image,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder:
                (_, _, _) => Container(
                  width: 0,
                  height: 60,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported),
                ),
          ),
        ),
        title: Text(
          product.productName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price: Rs.${product.rate}/${product.unit}'),
            Text('Category: ${product.category}'),
            if (product.location != null && product.location!.isNotEmpty)
              Text('Location: ${product.location}'),
            if (isAdmin && product.farmerName != null)
              Text('Farmer: ${product.farmerName}'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showActiveToggle && onToggleActive != null)
                  Obx(
                    () => SwitchListTile(
                      title: Row(
                        children: [
                          Text(
                            product.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color:
                                  product.isActive ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (toggleLoading[toggleKey] == true)
                            const Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                        ],
                      ),
                      value: product.isActive,
                      onChanged:
                          toggleLoading[toggleKey] == true
                              ? null
                              : onToggleActive,
                      activeColor: colorScheme.primary,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                Text('Quantity: ${product.availableQuantity} ${product.unit}'),
                if (product.description.isNotEmpty &&
                    product.description != 'No description')
                  Text('Description: ${product.description}'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 20),
                      label: Text('edit'.tr),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, size: 20),
                      label: Text('delete'.tr),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
