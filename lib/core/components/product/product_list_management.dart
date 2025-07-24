import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/features/admin/models/product_model.dart';

class ProductListManagement extends StatelessWidget {
  final Product product;
  final bool isAdmin;
  final bool isFarmer;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onToggleActive;
  final bool showActiveToggle;

  const ProductListManagement({
    super.key,
    required this.product,
    this.isAdmin = false,
    this.isFarmer = false,
    this.onEdit,
    this.onDelete,
    this.onToggleActive,
    this.showActiveToggle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network( 
            product.image,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 60,
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
            if (showActiveToggle && onToggleActive != null)
              SwitchListTile(
                title: Text(
                  product.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: product.isActive ? Colors.green : Colors.red,
                  ),
                ),
                value: product.isActive,
                onChanged: onToggleActive,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Category', product.category),
                _buildInfoRow('Quantity', '${product.availableQuantity} ${product.unit}'),
                if (product.location?.isNotEmpty == true)
                  _buildInfoRow('Location', product.location!),
                if (product.description.isNotEmpty && product.description != 'No description')
                  _buildInfoRow('Description', product.description),
                if (isAdmin && product.farmerName?.isNotEmpty == true)
                  _buildInfoRow('Farmer', product.farmerName!),
                if (product.createdAt != null)
                  _buildInfoRow('Created', _formatDate(product.createdAt!)),
                const SizedBox(height: 16),
                _buildActionButtons(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final buttons = <Widget>[];

    if (onEdit != null) {
      buttons.add(
        ElevatedButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit),
          label: Text('edit'.tr),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }

    if (onDelete != null) {
      buttons.add(
        ElevatedButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete),
          label: Text('delete'.tr),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: buttons,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}