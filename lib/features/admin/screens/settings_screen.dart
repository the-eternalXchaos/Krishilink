// lib/features/admin/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/features/admin/controllers/admin_settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminSettingsController controller = Get.find<AdminSettingsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.green.shade900,
      ),
      body: Obx(() => controller.isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: controller.adminProfile.value == null
                  ? const Text('No profile data')
                  : Column(
                      children: [
                        ListTile(
                          title: const Text('Name'),
                          subtitle: Text(controller.adminProfile.value!.fullName),
                        ),
                        ListTile(
                          title: const Text('Email'),
                          subtitle: Text(controller.adminProfile.value!.email ?? '-'),
                          // subtitle: Text(controller.adminProfile.value!.email ?? '-'),
                        ),
                        ListTile(
                          title: const Text('Role'),
                          subtitle: Text(controller.adminProfile.value!.role),
                        ),
                      ],
                    ),
            )),
    );
  }
}