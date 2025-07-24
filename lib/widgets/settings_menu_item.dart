import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsMenuItem extends StatelessWidget {
  const SettingsMenuItem({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.settings),
      title: Text('settings'.tr),
      onTap: () => Get.toNamed('/settings'),
    );
  }
}
