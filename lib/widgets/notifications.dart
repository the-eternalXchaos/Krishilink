import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:krishi_link/core/theme/app_theme.dart';
import 'package:krishi_link/features/farmer/controller/farmer_controller.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FarmerController controller = Get.find<FarmerController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'.tr, style: theme.textTheme.titleLarge),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(
        () =>
            controller.notifications.isEmpty
                ? Center(
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
                      ],
                    ),
                  ),
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.notifications.length,
                  itemBuilder: (context, index) {
                    final notification = controller.notifications[index];
                    final isRead = notification.isRead;
                    return FadeInUp(
                      delay: Duration(milliseconds: 100 * index),
                      child: Card(
                        elevation: isRead ? 1 : 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color:
                            isRead
                                ? theme.colorScheme.surface
                                : theme.colorScheme.primaryContainer,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            notification.type == 'order'
                                ? Icons.shopping_basket
                                : Icons.warning,
                            color: theme.colorScheme.primary,
                          ),
                          title: Text(
                            notification.title?.tr ?? notification.message.tr,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight:
                                  isRead ? FontWeight.normal : FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat(
                              'MMM dd, yyyy HH:mm',
                            ).format(notification.timestamp),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(150),
                            ),
                          ),
                          trailing:
                              !isRead
                                  ? IconButton(
                                    icon: Icon(
                                      Icons.mark_email_read,
                                      color: theme.colorScheme.primary,
                                    ),
                                    onPressed: () {
                                      controller.markNotificationAsRead(
                                        notification.id,
                                      );
                                    },
                                    tooltip: 'mark_as_read'.tr,
                                  )
                                  : null,
                          onTap: () {
                            if (!isRead) {
                              controller.markNotificationAsRead(
                                notification.id,
                              );
                            }
                            // Navigate to relevant screen based on notification type
                            if (notification.type == 'order') {
                              Get.toNamed('/orders');
                            } else if (notification.type == 'product' &&
                                notification.relatedId != null) {
                              Get.toNamed(
                                '/product-details',
                                arguments: notification.relatedId,
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
