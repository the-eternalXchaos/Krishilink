import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/features/farmer/controller/farmer_controller.dart';

class WeatherWidget extends StatelessWidget {
  const WeatherWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FarmerController>();
    final theme = Theme.of(context);

    return Obx(
      () => Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                (controller.weather.value?.condition ?? '').contains('Clear')
                    ? Icons.wb_sunny
                    : Icons.cloud,
                size: 40,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.weather.value?.temperature != null
                        ? '${controller.weather.value!.temperature.toStringAsFixed(1)}°C'
                        : '--',
                    style: theme.textTheme.headlineMedium,
                  ),
                  Text(
                    controller.weather.value?.condition ?? '--',
                    style: theme.textTheme.bodyLarge,
                  ),
                  Text(
                    controller.weather.value?.latitude.toString() ?? '--',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
