// lib/features/weather/weather_widget.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:krishi_link/src/core/constants/app_spacing.dart';
import 'package:krishi_link/core/widgets/app_widgets.dart';
import 'package:krishi_link/features/weather/weather_model.dart';

class WeatherWidget extends StatelessWidget {
  final Weather weather;

  const WeatherWidget({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    debugPrint(
      'WeatherWidget - Surface: ${colorScheme.surface}, Primary: ${colorScheme.primary}',
    );

    // Enhanced weather-specific colors and gradients
    WeatherTheme weatherTheme = _getWeatherTheme(
      weather.condition,
      colorScheme,
    );

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: AppWidgets.card(
        colorScheme: colorScheme,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                weatherTheme.primaryColor,
                weatherTheme.secondaryColor,
                weatherTheme.accentColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.6, 1.0],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: weatherTheme.primaryColor.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Background pattern
                Positioned.fill(
                  child: CustomPaint(
                    painter: WeatherPatternPainter(
                      condition: weather.condition,
                      color: weatherTheme.patternColor,
                    ),
                  ),
                ),
                // Main content
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      // Main weather info
                      Row(
                        children: [
                          // Temperature section
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SlideInLeft(
                                  duration: const Duration(milliseconds: 500),
                                  child: Text(
                                    '${weather.temperature.toStringAsFixed(1)}°',
                                    style: theme.textTheme.displayLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w300,
                                          color: colorScheme.onSurface,
                                          fontSize: 48,
                                          height: 1.0,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                SlideInLeft(
                                  duration: const Duration(milliseconds: 600),
                                  delay: const Duration(milliseconds: 100),
                                  child: Text(
                                    weather.condition,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.9),
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                SlideInLeft(
                                  duration: const Duration(milliseconds: 700),
                                  delay: const Duration(milliseconds: 200),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 16,
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Flexible(
                                        child: Text(
                                          weather.location,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colorScheme.onSurface
                                                    .withValues(alpha: 0.6),
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Weather icon
                          SlideInRight(
                            duration: const Duration(milliseconds: 500),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    weatherTheme.iconBackgroundColor,
                                    weatherTheme.iconBackgroundColor.withValues(
                                      alpha: 0.3,
                                    ),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                weatherTheme.icon,
                                size: 42,
                                color: weatherTheme.iconColor,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Weather details
                      SlideInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 300),
                        child: Row(
                          children: [
                            Expanded(
                              child: _WeatherDetailCard(
                                icon: Icons.water_drop_outlined,
                                label: 'humidity'.tr,
                                value: '${weather.humidity}%',
                                colorScheme: colorScheme,
                                accentColor: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _WeatherDetailCard(
                                icon: Icons.air,
                                label: 'wind_speed'.tr,
                                value:
                                    '${weather.windSpeed.toStringAsFixed(1)} m/s',
                                colorScheme: colorScheme,
                                accentColor: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  WeatherTheme _getWeatherTheme(String condition, ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;

    if (condition.contains('Clear')) {
      return WeatherTheme(
        primaryColor: colorScheme.surface,
        secondaryColor: colorScheme.surfaceContainerHighest,
        accentColor:
            isDark
                ? Colors.orange.shade800.withValues(alpha: 0.2)
                : Colors.amber.shade100.withValues(alpha: 0.6),
        icon: Icons.wb_sunny_outlined,
        iconColor: isDark ? Colors.orange.shade400 : Colors.orange.shade700,
        iconBackgroundColor:
            isDark
                ? Colors.orange.shade900.withValues(alpha: 0.2)
                : Colors.orange.shade50,
        patternColor: Colors.orange.withValues(alpha: 0.08),
      );
    } else if (condition.contains('Cloud')) {
      return WeatherTheme(
        primaryColor: colorScheme.surface,
        secondaryColor: colorScheme.surfaceContainerHighest,
        accentColor: colorScheme.outline.withValues(alpha: 0.1),
        icon: Icons.cloud_outlined,
        iconColor: colorScheme.onSurfaceVariant,
        iconBackgroundColor: colorScheme.outline.withValues(alpha: 0.1),
        patternColor: colorScheme.outline.withValues(alpha: 0.06),
      );
    } else if (condition.contains('Rain')) {
      return WeatherTheme(
        primaryColor: colorScheme.surface,
        secondaryColor: colorScheme.surfaceContainerHighest,
        accentColor:
            isDark
                ? Colors.blue.shade800.withValues(alpha: 0.2)
                : Colors.blue.shade50.withValues(alpha: 0.8),
        icon: Icons.grain,
        iconColor: isDark ? Colors.blue.shade400 : Colors.blue.shade700,
        iconBackgroundColor:
            isDark
                ? Colors.blue.shade900.withValues(alpha: 0.2)
                : Colors.blue.shade50,
        patternColor: Colors.blue.withValues(alpha: 0.08),
      );
    } else {
      return WeatherTheme(
        primaryColor: colorScheme.surface,
        secondaryColor: colorScheme.surfaceContainerHighest,
        accentColor: colorScheme.primary.withValues(alpha: 0.1),
        icon: Icons.wb_cloudy_outlined,
        iconColor: colorScheme.primary,
        iconBackgroundColor: colorScheme.primary.withValues(alpha: 0.1),
        patternColor: colorScheme.primary.withValues(alpha: 0.06),
      );
    }
  }
}

class _WeatherDetailCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;
  final Color accentColor;

  const _WeatherDetailCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 24,
              color: accentColor.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class WeatherTheme {
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Color patternColor;

  WeatherTheme({
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.patternColor,
  });
}

class WeatherPatternPainter extends CustomPainter {
  final String condition;
  final Color color;

  WeatherPatternPainter({required this.condition, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    if (condition.contains('Clear')) {
      // Draw subtle sun rays
      _drawSunRays(canvas, size, paint);
    } else if (condition.contains('Cloud')) {
      // Draw cloud-like curves
      _drawCloudPattern(canvas, size, paint);
    } else if (condition.contains('Rain')) {
      // Draw rain drops
      _drawRainPattern(canvas, size, paint);
    }
  }

  void _drawSunRays(Canvas canvas, Size size, Paint paint) {
    final center = Offset(size.width * 0.8, size.height * 0.2);
    final rayLength = 30.0;

    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * (3.14159 / 180);
      final startX = center.dx + (rayLength * 0.7) * cos(angle);
      final startY = center.dy + (rayLength * 0.7) * sin(angle);
      final endX = center.dx + rayLength * cos(angle);
      final endY = center.dy + rayLength * sin(angle);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint..strokeWidth = 2,
      );
    }
  }

  void _drawCloudPattern(Canvas canvas, Size size, Paint paint) {
    final path = Path();

    // Draw wavy cloud-like patterns
    for (int i = 0; i < 3; i++) {
      final y = size.height * (0.2 + i * 0.3);
      path.moveTo(size.width * 0.6, y);
      path.quadraticBezierTo(size.width * 0.8, y - 10, size.width, y + 5);
    }

    canvas.drawPath(path, paint);
  }

  void _drawRainPattern(Canvas canvas, Size size, Paint paint) {
    // Draw diagonal rain drops
    for (int i = 0; i < 12; i++) {
      final x = size.width * 0.6 + (i % 4) * 15.0;
      final y = (i ~/ 4) * 20.0 + 10;

      canvas.drawLine(
        Offset(x, y),
        Offset(x + 5, y + 12),
        paint..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Helper function for trigonometric calculations
double cos(double angle) => math.cos(angle);
double sin(double angle) => math.sin(angle);

// Add this import at the top of the file
