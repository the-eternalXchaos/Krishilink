import 'package:get/get.dart';
import 'package:krishi_link/src/core/components/product/management/unified_product_api_services.dart';
import 'package:krishi_link/src/core/components/product/management/unified_product_controller.dart';
import 'package:krishi_link/features/admin/controllers/admin_analytics_controler.dart';
import 'package:krishi_link/features/admin/controllers/admin_category_controller.dart';
import 'package:krishi_link/features/admin/controllers/admin_order_controller.dart';
import 'package:krishi_link/features/admin/controllers/admin_user_controller.dart';
import 'package:krishi_link/features/admin/controllers/component_animation_controller.dart';
import 'package:krishi_link/features/admin/controllers/quick_stats_controller.dart';
import 'package:krishi_link/features/admin/controllers/sales_chart_controller.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';

import 'package:krishi_link/features/admin/controllers/admin_notification_controller.dart';
import 'package:krishi_link/features/admin/controllers/admin_report_controller.dart';
import 'package:krishi_link/features/admin/controllers/admin_moderation_controller.dart';
import 'package:krishi_link/features/admin/controllers/admin_settings_controller.dart';

class AdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AuthController());
    Get.lazyPut(() => AdminUserController());
    Get.lazyPut(() => UnifiedProductController());
    Get.lazyPut(() => UnifiedProductApiServices());
    Get.lazyPut(
      () => ComponentAnimationController(),
      tag: 'dsashboard_metrics',
    );
    Get.lazyPut(() => AdminOrderController());
    Get.lazyPut(() => AdminCategoryController());
    Get.lazyPut(() => AdminAnalyticsController());
    Get.lazyPut(() => AdminNotificationController());
    Get.lazyPut(() => AdminReportController());
    Get.lazyPut(() => AdminModerationController());
    Get.lazyPut(() => AdminSettingsController());
    Get.lazyPut(() => ComponentAnimationController(), tag: 'header');
    Get.lazyPut(() => ComponentAnimationController(), tag: 'sales_chart');
    Get.lazyPut(() => ComponentAnimationController(), tag: 'quick_stats');
    Get.lazyPut(() => ComponentAnimationController(), tag: 'dashboard_metrics');
    Get.lazyPut(() => ComponentAnimationController(), tag: 'quick_actions');
    Get.lazyPut(() => ComponentAnimationController(), tag: 'recent_activities');
    Get.lazyPut(() => ComponentAnimationController(), tag: 'profile_card');
  }
}


// WidgetsBinding.instance.addPostFrameCallback((_) {
//   Future.microtask(() {
//     Get.find<ComponentAnimationController>(sAnimationController>(tag: 'header').animate();
//     Future.delayed(Duration(milliseconds: 100), () => Get.find<ComponentAnimationController>(tag: 'sales_chart').animate());
//     Future.delayed(Duration(milliseconds: 200), () => Get.find<ComponentAnimationController>(sAnimationController>(tag: 'quick_stats').animate());