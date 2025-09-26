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

    // Cache weather theme to avoid repeated computation
    final weatherTheme = _getWeatherTheme(weather.condition, colorScheme);

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
                // Background pattern with RepaintBoundary for optimization
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: WeatherPatternPainter(
                        condition: weather.condition,
                        color: weatherTheme.patternColor,
                      ),
                    ),
                  ),
                ),
                // Main content
                _WeatherContent(
                  weather: weather,
                  weatherTheme: weatherTheme,
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Optimized weather theme with better condition matching
  WeatherTheme _getWeatherTheme(String condition, ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final conditionLower = condition.toLowerCase();

    // Use switch expression for better performance
    return switch (conditionLower) {
      String c when c.contains('clear') || c.contains('sunny') => _sunnyTheme(
        colorScheme,
        isDark,
      ),
      String c when c.contains('cloud') || c.contains('overcast') =>
        _cloudyTheme(colorScheme, isDark),
      String c
          when c.contains('rain') ||
              c.contains('drizzle') ||
              c.contains('shower') =>
        _rainyTheme(colorScheme, isDark),
      String c when c.contains('snow') || c.contains('blizzard') => _snowyTheme(
        colorScheme,
        isDark,
      ),
      String c when c.contains('thunder') || c.contains('storm') =>
        _stormyTheme(colorScheme, isDark),
      String c
          when c.contains('fog') || c.contains('mist') || c.contains('haze') =>
        _foggyTheme(colorScheme, isDark),
      _ => _defaultTheme(colorScheme, isDark),
    };
  }

  WeatherTheme _sunnyTheme(ColorScheme colorScheme, bool isDark) {
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
  }

  WeatherTheme _cloudyTheme(ColorScheme colorScheme, bool isDark) {
    return WeatherTheme(
      primaryColor: colorScheme.surface,
      secondaryColor: colorScheme.surfaceContainerHighest,
      accentColor: colorScheme.outline.withValues(alpha: 0.1),
      icon: Icons.cloud_outlined,
      iconColor: colorScheme.onSurfaceVariant,
      iconBackgroundColor: colorScheme.outline.withValues(alpha: 0.1),
      patternColor: colorScheme.outline.withValues(alpha: 0.06),
    );
  }

  WeatherTheme _rainyTheme(ColorScheme colorScheme, bool isDark) {
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
  }

  WeatherTheme _snowyTheme(ColorScheme colorScheme, bool isDark) {
    return WeatherTheme(
      primaryColor: colorScheme.surface,
      secondaryColor: colorScheme.surfaceContainerHighest,
      accentColor:
          isDark
              ? Colors.cyan.shade800.withValues(alpha: 0.2)
              : Colors.cyan.shade50.withValues(alpha: 0.8),
      icon: Icons.ac_unit,
      iconColor: isDark ? Colors.cyan.shade400 : Colors.cyan.shade700,
      iconBackgroundColor:
          isDark
              ? Colors.cyan.shade900.withValues(alpha: 0.2)
              : Colors.cyan.shade50,
      patternColor: Colors.cyan.withValues(alpha: 0.08),
    );
  }

  WeatherTheme _stormyTheme(ColorScheme colorScheme, bool isDark) {
    return WeatherTheme(
      primaryColor: colorScheme.surface,
      secondaryColor: colorScheme.surfaceContainerHighest,
      accentColor:
          isDark
              ? Colors.purple.shade800.withValues(alpha: 0.2)
              : Colors.purple.shade50.withValues(alpha: 0.8),
      icon: Icons.flash_on,
      iconColor: isDark ? Colors.purple.shade400 : Colors.purple.shade700,
      iconBackgroundColor:
          isDark
              ? Colors.purple.shade900.withValues(alpha: 0.2)
              : Colors.purple.shade50,
      patternColor: Colors.purple.withValues(alpha: 0.08),
    );
  }

  WeatherTheme _foggyTheme(ColorScheme colorScheme, bool isDark) {
    return WeatherTheme(
      primaryColor: colorScheme.surface,
      secondaryColor: colorScheme.surfaceContainerHighest,
      accentColor: Colors.grey.withValues(alpha: 0.1),
      icon: Icons.foggy,
      iconColor: Colors.grey.shade600,
      iconBackgroundColor: Colors.grey.withValues(alpha: 0.1),
      patternColor: Colors.grey.withValues(alpha: 0.06),
    );
  }

  WeatherTheme _defaultTheme(ColorScheme colorScheme, bool isDark) {
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

// Extracted content widget for better organization
class _WeatherContent extends StatelessWidget {
  final Weather weather;
  final WeatherTheme weatherTheme;
  final ColorScheme colorScheme;

  const _WeatherContent({
    required this.weather,
    required this.weatherTheme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // Main weather info
          _MainWeatherRow(
            weather: weather,
            weatherTheme: weatherTheme,
            theme: theme,
            colorScheme: colorScheme,
          ),

          const SizedBox(height: AppSpacing.lg),

          // Weather details with optimized layout
          SlideInUp(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 300),
            child: _WeatherDetailsRow(
              weather: weather,
              colorScheme: colorScheme,
            ),
          ),
        ],
      ),
    );
  }
}

// Extracted main weather row for better maintainability
class _MainWeatherRow extends StatelessWidget {
  final Weather weather;
  final WeatherTheme weatherTheme;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _MainWeatherRow({
    required this.weather,
    required this.weatherTheme,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Temperature section
        Expanded(
          flex: 2,
          child: _TemperatureSection(
            weather: weather,
            theme: theme,
            colorScheme: colorScheme,
          ),
        ),
        // Weather icon
        SlideInRight(
          duration: const Duration(milliseconds: 500),
          child: _WeatherIcon(weatherTheme: weatherTheme),
        ),
      ],
    );
  }
}

// Temperature section component
class _TemperatureSection extends StatelessWidget {
  final Weather weather;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _TemperatureSection({
    required this.weather,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SlideInLeft(
          duration: const Duration(milliseconds: 500),
          child: Text(
            '${weather.temperature.toStringAsFixed(1)}°',
            style: theme.textTheme.displayLarge?.copyWith(
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
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SlideInLeft(
          duration: const Duration(milliseconds: 700),
          delay: const Duration(milliseconds: 200),
          child: _LocationRow(
            location: weather.location,
            theme: theme,
            colorScheme: colorScheme,
          ),
        ),
      ],
    );
  }
}

// Location row component
class _LocationRow extends StatelessWidget {
  final String location;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _LocationRow({
    required this.location,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.location_on_outlined,
          size: 16,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            location,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// Weather icon component
class _WeatherIcon extends StatelessWidget {
  final WeatherTheme weatherTheme;

  const _WeatherIcon({required this.weatherTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            weatherTheme.iconBackgroundColor,
            weatherTheme.iconBackgroundColor.withValues(alpha: 0.3),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(weatherTheme.icon, size: 42, color: weatherTheme.iconColor),
    );
  }
}

// Weather details row component
class _WeatherDetailsRow extends StatelessWidget {
  final Weather weather;
  final ColorScheme colorScheme;

  const _WeatherDetailsRow({required this.weather, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Row(
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
            value: '${weather.windSpeed.toStringAsFixed(1)} m/s',
            colorScheme: colorScheme,
            accentColor: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

// Optimized detail card with const constructor
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

// Weather theme data class
class WeatherTheme {
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Color patternColor;

  const WeatherTheme({
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.patternColor,
  });
}

// Optimized custom painter with better performance
class WeatherPatternPainter extends CustomPainter {
  final String condition;
  final Color color;

  // Cache the condition type to avoid repeated string operations
  late final WeatherPatternType _patternType;

  WeatherPatternPainter({required this.condition, required this.color}) {
    _patternType = _getPatternType(condition.toLowerCase());
  }

  WeatherPatternType _getPatternType(String conditionLower) {
    if (conditionLower.contains('clear') || conditionLower.contains('sunny')) {
      return WeatherPatternType.sunny;
    } else if (conditionLower.contains('cloud')) {
      return WeatherPatternType.cloudy;
    } else if (conditionLower.contains('rain')) {
      return WeatherPatternType.rainy;
    } else if (conditionLower.contains('snow')) {
      return WeatherPatternType.snowy;
    }
    return WeatherPatternType.cloudy;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    switch (_patternType) {
      case WeatherPatternType.sunny:
        _drawSunRays(canvas, size, paint);
      case WeatherPatternType.cloudy:
        _drawCloudPattern(canvas, size, paint);
      case WeatherPatternType.rainy:
        _drawRainPattern(canvas, size, paint);
      case WeatherPatternType.snowy:
        _drawSnowPattern(canvas, size, paint);
    }
  }

  void _drawSunRays(Canvas canvas, Size size, Paint paint) {
    final center = Offset(size.width * 0.8, size.height * 0.2);
    const rayLength = 30.0;
    const rayCount = 8;

    for (int i = 0; i < rayCount; i++) {
      final angle = (i * 45) * (math.pi / 180);
      final startRadius = rayLength * 0.7;

      final start = Offset(
        center.dx + startRadius * math.cos(angle),
        center.dy + startRadius * math.sin(angle),
      );

      final end = Offset(
        center.dx + rayLength * math.cos(angle),
        center.dy + rayLength * math.sin(angle),
      );

      canvas.drawLine(start, end, paint..strokeWidth = 2);
    }
  }

  void _drawCloudPattern(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    const curves = 3;

    for (int i = 0; i < curves; i++) {
      final y = size.height * (0.2 + i * 0.3);
      final startX = size.width * 0.6;

      path.moveTo(startX, y);
      path.quadraticBezierTo(size.width * 0.8, y - 10, size.width, y + 5);
    }

    canvas.drawPath(path, paint);
  }

  void _drawRainPattern(Canvas canvas, Size size, Paint paint) {
    const dropCount = 12;
    const dropLength = 12.0;
    const dropSpacing = 15.0;

    for (int i = 0; i < dropCount; i++) {
      final row = i ~/ 4;
      final col = i % 4;

      final x = size.width * 0.6 + col * dropSpacing;
      final y = row * 20.0 + 10;

      canvas.drawLine(Offset(x, y), Offset(x + 5, y + dropLength), paint);
    }
  }

  void _drawSnowPattern(Canvas canvas, Size size, Paint paint) {
    const flakeCount = 8;
    final flakeSize = 4.0;

    for (int i = 0; i < flakeCount; i++) {
      final x = size.width * 0.6 + (i % 3) * 25.0;
      final y = (i ~/ 3) * 30.0 + 15;

      final center = Offset(x, y);

      // Draw simple snowflake pattern
      for (int j = 0; j < 6; j++) {
        final angle = (j * 60) * (math.pi / 180);
        final end = Offset(
          center.dx + flakeSize * math.cos(angle),
          center.dy + flakeSize * math.sin(angle),
        );
        canvas.drawLine(center, end, paint);
      }
    }
  }

  @override
  bool shouldRepaint(WeatherPatternPainter oldDelegate) {
    return oldDelegate.condition != condition || oldDelegate.color != color;
  }
}

// Enum for pattern types
enum WeatherPatternType { sunny, cloudy, rainy, snowy }
