// lib/features/admin/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/src/features/admin/presentation/controllers/admin_report_controller.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminReportController controller = Get.find<AdminReportController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Colors.green.shade900,
      ),
      body: Obx(() => controller.isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: controller.reports.length,
              itemBuilder: (context, index) {
                final report = controller.reports[index];
                return Card(
                  child: ListTile(
                    title: Text(report['type']),
                    subtitle: Text('NPR ${report['value'].toStringAsFixed(2)}'),
                    trailing: Text(report['date'].toString()),
                  ),
                );
              },
            )),
    );
  }
}