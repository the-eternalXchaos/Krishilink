// lib/features/farmer/screens/crop_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:krishi_link/core/constants/app_spacing.dart';
import 'package:krishi_link/core/theme/app_theme.dart';
import 'package:krishi_link/core/widgets/app_widgets.dart';
import 'package:krishi_link/features/farmer/controller/farmer_controller.dart';
import 'package:krishi_link/features/farmer/models/crop_model.dart';
import 'package:krishi_link/features/farmer/screens/add_crop_screen.dart';

class CropDetailScreen extends StatelessWidget {
  final CropModel crop;

  const CropDetailScreen({super.key, required this.crop});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final controller = Get.find<FarmerController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(crop.name.tr, style: theme.textTheme.titleLarge),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: colorScheme.onPrimary),
            onPressed: () => Get.to(() => AddCropScreen(crop: crop)),
            tooltip: 'Edit Crop'.tr,
          ),
          IconButton(
            icon: Icon(Icons.camera_alt, color: colorScheme.onPrimary),
            onPressed: () async {
              final res = await Get.toNamed('/disease-detection', arguments: {'returnResult': true, 'cropId': crop.id});
              if (res is Map<String, dynamic>) {
                final status = res['status'] as String?;
                final disease = res['disease'] as String?;
                final care = res['careInstructions'] as String?;
                final suggestion = res['suggestions'] as String?;
                if (status != null && status.isNotEmpty) {
                  await controller.updateCropHealth(crop.id, status: status, disease: disease, careInstructions: care, suggestions: suggestion);
                }
              }
            },
            tooltip: 'Scan Leaf'.tr,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              child: AppWidgets.card(
                colorScheme: colorScheme,
                title: 'Crop Overview'.tr,
                icon: Icons.grass,
                iconColor: colorScheme.primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() {
  final live = controller.crops.firstWhere((c) => c.id == crop.id, orElse: () => crop);
  final status = live.status ?? 'Unknown';
  final color = status == 'Healthy' ? colorScheme.primary : status == 'At Risk' ? colorScheme.secondary : colorScheme.error;
  return _buildDetailRow(
    context,
    icon: Icons.tag,
    label: 'Status'.tr,
    value: status.tr,
    valueColor: color,
  );
                    }),

                    _buildDetailRow(
                      context,
                      icon: Icons.calendar_today,
                      label: 'Planting Date'.tr,
                      value:
                          crop.plantedAt != null
                              ? DateFormat(
                                'MMM dd, yyyy',
                              ).format(crop.plantedAt!)
                              : 'N/A',
                    ),
                    if (crop.note != null && crop.note!.isNotEmpty)
                      _buildDetailRow(
                        context,
                        icon: Icons.note,
                        label: 'Notes'.tr,
                        value: crop.note!,
                      ),
                    if (crop.description != null &&
                        crop.description!.isNotEmpty)
                      _buildDetailRow(
                        context,
                        icon: Icons.description,
                        label: 'Description'.tr,
                        value: crop.description!,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FadeInUp(
              child: AppWidgets.card(
                colorScheme: colorScheme,
                title: 'Disease Detection'.tr,
                icon: Icons.warning,
                iconColor: colorScheme.primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        'No disease detected. Scan leaves to check health.'.tr,
                        style: theme.textTheme.bodyLarge,
                      ),
                    const SizedBox(height: AppSpacing.md),
                    AppWidgets.button(
                      text: 'Scan Leaf Again'.tr,
                      icon: Icons.camera_alt,
                      onPressed: () async {
              final res = await Get.toNamed('/disease-detection', arguments: {'returnResult': true, 'cropId': crop.id});
              if (res is Map<String, dynamic>) {
                final status = res['status'] as String?;
                final disease = res['disease'] as String?;
                final care = res['careInstructions'] as String?;
                final suggestion = res['suggestions'] as String?;
                if (status != null && status.isNotEmpty) {
                  await controller.updateCropHealth(crop.id, status: status, disease: disease, careInstructions: care, suggestions: suggestion);
                }
              }
            },
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: AppWidgets.card(
                colorScheme: colorScheme,
                title: 'Health History'.tr,
                icon: Icons.history,
                iconColor: colorScheme.primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health history graph coming soon!'.tr,
                      style: theme.textTheme.bodyLarge,
                    ),
                    Container(
                      height: 150,
                      color: colorScheme.primaryContainer,
                      child: Center(
                        child: Text(
                          'holder'.tr,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Text(
            '$label:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
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
