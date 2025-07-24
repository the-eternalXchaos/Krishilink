import 'package:flutter/material.dart';
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

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  crop.name[0],
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(crop.name, style: theme.textTheme.titleLarge),
                    Text(
                      ' ${crop.status}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            crop.status == 'Healthy'
                                ? Colors.green
                                : Colors.red,
                      ),
                    ),
                    Text(
                      '${crop.suggestions}',
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
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                        if (onDelete != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
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
