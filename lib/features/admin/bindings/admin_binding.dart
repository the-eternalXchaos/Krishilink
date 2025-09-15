import 'package:get/get.dart';
import 'package:krishi_link/src/features/product/presentation/controllers/product_controller.dart';
import 'package:krishi_link/core/components/product/management/unified_product_api_services.dart';
import 'package:krishi_link/core/components/product/management/unified_product_controller.dart';
import 'package:krishi_link/features/admin/controllers/admin_analytics_controler.dart';
import 'package:krishi_link/features/admin/controllers/admin_category_controller.dart';
import 'package:krishi_link/features/admin/controllers/admin_order_controller.dart';
import 'package:krishi_link/features/admin/controllers/admin_user_controller.dart';
import 'package:krishi_link/features/admin/controllers/component_animation_controller.dart';
import 'package:krishi_link/features/admin/controllers/quick_stats_controller.dart';
import 'package:krishi_link/features/admin/controllers/sales_chart_controller.dart';
import 'package:krishi_link/features/admin/controllers/admin_notification_controller.dart';
import 'package:krishi_link/features/admin/controllers/admin_report_controller.dart';
import 'package:krishi_link/features/admin/controllers/admin_moderation_controller.dart';
import 'package:krishi_link/features/admin/controllers/admin_settings_controller.dart';

/// Admin dashboard binding
class AdminBinding extends Bindings {
  @override
  void dependencies() {
    // Page-specific controllers for admin dashboard
    Get.create<ProductController>(() => ProductController());

    // Admin-specific controllers with fenix for recreation after disposal
    Get.lazyPut(() => AdminUserController(), fenix: true);
    Get.lazyPut(() => UnifiedProductController(), fenix: true);
    Get.lazyPut(() => UnifiedProductApiServices(), fenix: true);
    Get.lazyPut(() => AdminOrderController(), fenix: true);
    Get.lazyPut(() => AdminCategoryController(), fenix: true);
    Get.lazyPut(() => AdminAnalyticsController(), fenix: true);
    Get.lazyPut(() => AdminNotificationController(), fenix: true);
    Get.lazyPut(() => AdminReportController(), fenix: true);
    Get.lazyPut(() => AdminModerationController(), fenix: true);
    Get.lazyPut(() => AdminSettingsController(), fenix: true);

    // Animation controllers with tags - recreate after disposal
    Get.lazyPut(
      () => ComponentAnimationController(),
      tag: 'dashboard_metrics',
      fenix: true,
    );
    Get.lazyPut(
      () => ComponentAnimationController(),
      tag: 'header',
      fenix: true,
    );
    Get.lazyPut(
      () => ComponentAnimationController(),
      tag: 'sales_chart',
      fenix: true,
    );
    Get.lazyPut(
      () => ComponentAnimationController(),
      tag: 'quick_stats',
      fenix: true,
    );
    Get.lazyPut(
      () => ComponentAnimationController(),
      tag: 'quick_actions',
      fenix: true,
    );
    Get.lazyPut(
      () => ComponentAnimationController(),
      tag: 'recent_activities',
      fenix: true,
    );
    Get.lazyPut(
      () => ComponentAnimationController(),
      tag: 'profile_card',
      fenix: true,
    );
  }
}
