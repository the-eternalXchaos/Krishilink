import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/src/core/services/connectivity_service.dart';

class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivityService = ConnectivityService.I;

    return Obx(() {
      // If online, don't render anything
      if (!connectivityService.isOffline.value) {
        return const SizedBox.shrink();
      }

      // If offline, show banner
      return Container(
        width: double.infinity,
        color: Colors.red.shade700,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: const Text(
          '⚠️ You are offline. Some features may be unavailable.',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
      );
    });
  }
}
