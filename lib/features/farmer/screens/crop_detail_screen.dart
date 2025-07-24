import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:krishi_link/core/theme/app_theme.dart';
import 'package:krishi_link/features/farmer/controller/farmer_controller.dart';
import 'package:krishi_link/features/farmer/models/crop_model.dart';
import 'package:krishi_link/features/farmer/screens/add_crop_screen.dart';
import 'package:intl/intl.dart';

class CropDetailScreen extends StatelessWidget {
  final CropModel crop;

  const CropDetailScreen({super.key, required this.crop});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<FarmerController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(crop.name.tr, style: theme.textTheme.titleLarge),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: theme.colorScheme.primary),
            onPressed: () => Get.to(() => AddCropScreen(crop: crop)),
            tooltip: 'Edit Crop'.tr,
          ),
          IconButton(
            icon: Icon(Icons.camera_alt, color: theme.colorScheme.primary),
            onPressed:
                () => Get.toNamed('/disease-detection'), // Stubbed ML screen
            tooltip: 'Scan Leaf'.tr,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Crop Overview'.tr,
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        context,
                        icon: Icons.tag,
                        label: 'Status'.tr,
                        value: crop.status!.tr,
                        valueColor:
                            crop.status == 'Healthy'
                                ? Colors.green
                                : crop.status == 'At Risk'
                                ? Colors.orange
                                : Colors.red,
                      ),
                      _buildDetailRow(
                        context,
                        icon: Icons.calendar_today,
                        label: 'Planting Date'.tr,
                        value: DateFormat(
                          'MMM dd, yyyy',
                        ).format(crop.plantedAt as DateTime),

                        // value:

                        //  '${crop.plantedAt}',
                      ),
                      // value: DateFormat('MMM dd, yyyy').format(crop.plantingDate),
                      if (crop.note!.isNotEmpty)
                        _buildDetailRow(
                          context,
                          icon: Icons.note,
                          label: 'Notes'.tr,
                          value: '${crop.note}',
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Disease Detection'.tr,
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      if (crop.disease != null && crop.disease!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow(
                              context,
                              icon: Icons.warning,
                              label: 'Detected Disease'.tr,
                              value: crop.disease!.tr,
                            ),
                            if (crop.careInstructions != null &&
                                crop.careInstructions!.isNotEmpty)
                              _buildDetailRow(
                                context,
                                icon: Icons.healing,
                                label: 'Care Instructions'.tr,
                                value: crop.careInstructions!.tr,
                              ),
                          ],
                        )
                      else
                        Text(
                          'No disease detected. Scan leaves to check health.'
                              .tr,
                          style: theme.textTheme.bodyLarge,
                        ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => Get.toNamed('/disease-detection'),
                        icon: const Icon(Icons.camera_alt),
                        label: Text('Scan Leaf Again'.tr),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Health History'.tr,
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Health history graph coming soon!'.tr,
                        style: theme.textTheme.bodyLarge,
                      ),
                      // Placeholder for future graph implementation
                      Container(
                        height: 150,
                        color: theme.colorScheme.primaryContainer,
                        child: Center(
                          child: Text(
                            'Graph Placeholder'.tr,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: valueColor ?? theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
