import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/src/features/notification/presentation/controllers/notification_controller.dart';
import 'package:krishi_link/src/features/notification/presentation/widgets/notification_tile.dart';
import 'package:krishi_link/src/features/notification/presentation/widgets/notification_state_views.dart';
import 'package:krishi_link/src/features/notification/presentation/utils/notification_utils.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final ScrollController _scrollController;
  late final NotificationController controller;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    controller =
        Get.isRegistered<NotificationController>()
            ? Get.find<NotificationController>()
            : Get.put(NotificationController());

    // Setup pagination
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        controller.hasMorePages.value &&
        !controller.isLoadingMore.value) {
      controller.loadMoreNotifications();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Obx(() {
        // Loading state for initial load
        if (controller.isLoading.value && !controller.hasNotifications) {
          return const NotificationLoadingView();
        }

        // Error state with no notifications
        if (controller.hasError.value && !controller.hasNotifications) {
          return NotificationErrorView(
            message: controller.errorMessage.value,
            onRetry: controller.retry,
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchNotifications(isRefresh: true),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildAppBar(theme),

              // Empty state
              if (!controller.hasNotifications && !controller.hasError.value)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: NotificationEmptyView(),
                )
              else
                _buildNotificationsList(),

              // Load more indicator
              if (controller.isLoadingMore.value)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  SliverAppBar _buildAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('notifications'.tr),
            Obx(() {
              if (controller.unreadNotificationCount > 0) {
                return Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${controller.unreadNotificationCount}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onError,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primaryContainer,
                theme.colorScheme.secondaryContainer,
              ],
            ),
          ),
        ),
      ),
      actions: [
        Obx(() {
          if (controller.hasNotifications &&
              controller.unreadNotificationCount > 0) {
            return PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface),
              onSelected: (value) {
                switch (value) {
                  case 'mark_all_read':
                    controller.markAllAsRead();
                    break;
                  case 'clear_all':
                    NotificationUtils.showClearAllDialog(
                      controller.clearAllNotifications,
                    );
                    break;
                }
              },
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      value: 'mark_all_read',
                      child: Row(
                        children: [
                          Icon(
                            Icons.mark_email_read,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text('mark_all_read'.tr),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'clear_all',
                      child: Row(
                        children: [
                          Icon(Icons.clear_all, color: theme.colorScheme.error),
                          const SizedBox(width: 8),
                          Text('clear_all'.tr),
                        ],
                      ),
                    ),
                  ],
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  SliverPadding _buildNotificationsList() {
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final notification = controller.notifications[index];
          return NotificationTile(
            notification: notification,
            index: index,
            onTap: () {
              if (!notification.isRead) {
                controller.markNotificationAsRead(notification.id);
              }
              NotificationUtils.handleNotificationTap(notification);
            },
            onMarkRead:
                () => controller.markNotificationAsRead(notification.id),
            onDelete:
                () => NotificationUtils.showDeleteDialog(
                  notification,
                  () => controller.deleteNotification(notification.id),
                ),
          );
        }, childCount: controller.notifications.length),
      ),
    );
  }
}
