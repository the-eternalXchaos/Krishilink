// lib/features/admin/controller/admin_report_controller.dart
import 'package:get/get.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';

class AdminReportController extends GetxController {
  final reports = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchReports();
  }

  Future<void> fetchReports() async {
    try {
      isLoading(true);
      // Mock; replace with API
      reports.assignAll([
        {'id': '1', 'type': 'Sales', 'date': DateTime.now(), 'value': 50000.0},
      ]);
    } catch (e) {
      PopupService.error('Failed to load reports: $e');
    } finally {
      isLoading(false);
    }
  }
}
