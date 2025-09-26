import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:krishi_link/src/core/constants/app_spacing.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/features/notification/model/notification_model.dart';
import 'package:krishi_link/src/features/notification/presentation/controllers/notification_controller.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationController>();
    final theme = Theme.of(context);

    void handleNotificationTap(NotificationModel notification) {
      if (!notification.isRead) {
        controller.markNotificationAsRead(notification.id);
      }

      if (notification.type == 'order' && notification.relatedId != null) {
        PopupService.showFeedback('Order tapped');
      } else if (notification.type == 'product' &&
          notification.relatedId != null) {
        Get.toNamed('/product-details', arguments: notification.relatedId);
      }
    }

    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.fetchNotifications,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(title: Text('notification'.tr)),
              ),

              /// Empty state
              if (controller.notifications.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: FadeInUp(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 60,
                          color: theme.colorScheme.primary.withAlpha(125),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'no_notifications_yet'.tr,
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        BounceInUp(
                          child: ElevatedButton.icon(
                            onPressed: controller.fetchNotifications,
                            icon: Icon(
                              Icons.refresh,
                              size: 24,
                              color: theme.colorScheme.onPrimary,
                            ),
                            label: Text(
                              'refresh'.tr,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 72),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final notification = controller.notifications[index];
                      return NotificationTile(
                        notification: notification,
                        index: index,
                        onTap: () => handleNotificationTap(notification),
                        onMarkRead:
                            () => controller.markNotificationAsRead(
                              notification.id,
                            ),
                      );
                    }, childCount: controller.notifications.length),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

/// Extracted clean widget for one tile
class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.index,
    required this.onTap,
    required this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRead = notification.isRead;

    return FadeInUp(
      delay: Duration(milliseconds: 100 * index),
      child: Card(
        elevation: isRead ? 1 : 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color:
            isRead
                ? theme.colorScheme.surface
                : theme.colorScheme.primaryContainer,
        margin: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.md,
        ),
        child: ListTile(
          leading: Stack(
            children: [
              Icon(
                notification.type == 'order'
                    ? Icons.shopping_basket
                    : Icons.notifications,
                color: theme.colorScheme.primary,
              ),
              if (!isRead)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Pulse(
                    infinite: true,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.new_releases,
                        color: theme.colorScheme.onSurface,
                        size: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            notification.title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
            ),
          ),
          subtitle: Text(
            notification.timeAgo,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(150),
            ),
          ),
          trailing:
              !isRead
                  ? GestureDetector(
                    onTap: onMarkRead,
                    child: BounceInDown(
                      child: Icon(
                        Icons.mark_email_read,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  )
                  : null,
          onTap: onTap,
        ),
      ),
    );
  }
}
