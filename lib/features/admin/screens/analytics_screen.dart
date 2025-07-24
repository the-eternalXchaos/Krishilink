// lib/features/admin/screens/analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/features/admin/controllers/admin_analytics_controler.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminAnalyticsController controller = Get.find<AdminAnalyticsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.green.shade900,
      ),
      body: Obx(() => controller.isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Card(
                    child: ListTile(
                      title: const Text('Total Sales'),
                      subtitle: Text('NPR ${controller.totalSales.value.toStringAsFixed(2)}'),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: const Text('User Growth'),
                      subtitle: Text('${controller.userGrowth.value} new users'),
                    ),
                  ),
                ],
              ),
            )),
    );
  }
}