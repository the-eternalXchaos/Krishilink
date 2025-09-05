// lib/features/farmer/screens/crop_card.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/constants/app_spacing.dart';
import 'package:krishi_link/core/theme/app_theme.dart';
import 'package:krishi_link/core/widgets/app_widgets.dart';
import 'package:krishi_link/features/farmer/models/crop_model.dart';

class CropCard extends StatelessWidget {
  final CropModel crop;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CropCard({
    super.key,
    required this.crop,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppWidgets.card(
      colorScheme: colorScheme,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.surface,
                child: Text(
                  crop.name[0],
                  style: TextStyle(color: colorScheme.primary),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(crop.name, style: theme.textTheme.titleLarge),
                    Text(
                      (crop.status ?? 'unknown').tr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            crop.status == 'Healthy'
                                ? Colors.green
                                : crop.status == 'At Risk'
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                    if (crop.suggestions != null &&
                        crop.suggestions!.isNotEmpty)
                      Text(
                        crop.suggestions!,
                        style: theme.textTheme.bodyMedium,
                      ),
                  ],
                ),
              ),
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                  itemBuilder:
                      (context) => [
                        if (onEdit != null)
                          PopupMenuItem(value: 'edit', child: Text('edit'.tr)),
                        if (onDelete != null)
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('delete'.tr),
                          ),
                      ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
