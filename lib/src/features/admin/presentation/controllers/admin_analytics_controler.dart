// lib/features/admin/controller/admin_analytics_controller.dart
import 'package:get/get.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';

class AdminAnalyticsController extends GetxController {
  final totalSales = 0.0.obs;
  final userGrowth = 0.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAnalytics();
  }

  Future<void> fetchAnalytics() async {
    try {
      isLoading(true);
      // Mock; replace with API
      totalSales.value = 150000.0;
      userGrowth.value = 50;
    } catch (e) {
      PopupService.error('Failed to load analytics: $e');
    } finally {
      isLoading(false);
    }
  }
}
