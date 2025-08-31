import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:krishi_link/core/components/product/location_picker.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/features/weather/controller/weather_controller.dart';
import 'package:krishi_link/features/weather/weather_model.dart';
import 'package:krishi_link/features/weather/weather_widget.dart';

class WeatherDetailsPage extends StatelessWidget {
  WeatherDetailsPage({super.key});

  final WeatherController controller =
      Get.isRegistered<WeatherController>()
          ? Get.find<WeatherController>()
          : Get.put(WeatherController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('weather_details'.tr),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'loading_weather'.tr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          );
        }

        if (controller.weather.value == null) {
          return FadeIn(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 64,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'no_weather_data'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final Weather weather = controller.weather.value!;

        return RefreshIndicator(
          onRefresh: () async {
            await controller.fetchWeather(
              latitude: weather.latitude,
              longitude: weather.longitude,
            );
          },
          color: colorScheme.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weather Summary Widget
                FadeInUp(
                  duration: const Duration(milliseconds: 400),
                  child: WeatherWidget(weather: weather),
                ),

                const SizedBox(height: 32),

                // Location Picker Section
                FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 100),
                  child: _buildSection(
                    context: context,
                    title: 'select_location'.tr,
                    icon: Icons.location_on_outlined,
                    child: LocationPicker(
                      initialLatitude: weather.latitude,
                      initialLongitude: weather.longitude,
                      initialAddress: weather.location,
                      onLocationSelected: (lat, lon, address) {
                        debugPrint('Selected location: $address $lat, $lon');
                        // controller.fetchWeather(latitude: lat, longitude: lon);
                        controller.fetchWeather(latitude: lat, longitude: lon);

                        PopupService.success('fetching_weather_for $address');
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Detailed Weather Information
                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  delay: const Duration(milliseconds: 200),
                  child: _buildSection(
                    context: context,
                    title: 'weather_details'.tr,
                    icon: Icons.info_outline,
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        _buildDetailGrid(context, weather),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          // Section content
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildDetailGrid(BuildContext context, Weather weather) {
    final details = [
      _WeatherDetail(
        'Temperature',
        '${weather.temperature.toStringAsFixed(1)}°C',
        Icons.thermostat_outlined,
      ),
      _WeatherDetail(
        'Feels Like',
        '${weather.feelsLike.toStringAsFixed(1)}°C',
        Icons.device_thermostat,
      ),
      _WeatherDetail('Condition', weather.condition, Icons.wb_cloudy_outlined),
      _WeatherDetail(
        'Description',
        weather.description,
        Icons.description_outlined,
      ),
      _WeatherDetail(
        'Humidity',
        '${weather.humidity}%',
        Icons.water_drop_outlined,
      ),
      _WeatherDetail(
        'Wind Speed',
        '${weather.windSpeed.toStringAsFixed(1)} m/s',
        Icons.air,
      ),
      _WeatherDetail(
        'Observation Time',
        weather.observationTime != null
            ? _formatDateTime(weather.observationTime!)
            : '-',
        Icons.access_time,
      ),
      _WeatherDetail(
        'Daytime',
        weather.isDaytime ? 'Yes' : 'No',
        weather.isDaytime ? Icons.wb_sunny : Icons.nights_stay,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: details.length,
      itemBuilder: (context, index) {
        return SlideInUp(
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: 50 * index),
          child: _WeatherDetailGridItem(detail: details[index]),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

class _WeatherDetail {
  final String title;
  final String value;
  final IconData icon;

  _WeatherDetail(this.title, this.value, this.icon);
}

class _WeatherDetailGridItem extends StatelessWidget {
  final _WeatherDetail detail;

  const _WeatherDetailGridItem({required this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    detail.icon,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    detail.title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Value
            Text(
              detail.value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
