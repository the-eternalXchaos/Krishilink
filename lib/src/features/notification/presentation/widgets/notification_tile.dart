import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:krishi_link/core/constants/app_spacing.dart';
import 'package:krishi_link/features/admin/models/notification_model.dart';

/// Enhanced notification tile with better UI and interactions
class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.index,
    required this.onTap,
    required this.onMarkRead,
    required this.onDelete,
  });

  IconData _getNotificationIcon() {
    switch (notification.type) {
      case 'order':
        return Icons.shopping_cart;
      case 'product':
        return Icons.inventory_2;
      case 'message':
        return Icons.message;
      case 'promotion':
        return Icons.local_offer;
      case 'system':
        return Icons.settings;
      case 'warning':
        return Icons.warning;
      case 'success':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(ThemeData theme) {
    switch (notification.type) {
      case 'warning':
        return theme.colorScheme.error;
      case 'success':
        return Colors.green;
      case 'promotion':
        return Colors.orange;
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRead = notification.isRead;

    return FadeInUp(
      delay: Duration(milliseconds: 100 * (index % 5)),
      child: Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.error.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.delete_outline,
            color: theme.colorScheme.error,
            size: 28,
          ),
        ),
        onDismissed: (_) => onDelete(),
        child: Container(
          margin: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.md,
          ),
          child: Material(
            elevation: isRead ? 1 : 4,
            shadowColor: theme.colorScheme.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            color:
                isRead
                    ? theme.colorScheme.surface
                    : theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border:
                      isRead
                          ? null
                          : Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.3,
                            ),
                            width: 1,
                          ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon with notification indicator
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getIconColor(theme).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getNotificationIcon(),
                            color: _getIconColor(theme),
                            size: 24,
                          ),
                        ),
                        if (!isRead)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Pulse(
                              infinite: true,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.error,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: theme.colorScheme.surface,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight:
                                  isRead ? FontWeight.w500 : FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.message,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            notification.timeAgo,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Actions
                    if (!isRead)
                      GestureDetector(
                        onTap: onMarkRead,
                        child: BounceInDown(
                          delay: Duration(milliseconds: 200 + (100 * index)),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.mark_email_read,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
