import 'package:flutter/foundation.dart';
import 'package:krishi_link/features/weather/weather_model.dart';
import 'package:krishi_link/src/core/constants/api_constants.dart';
import 'package:krishi_link/src/core/networking/base_service.dart';

class WeatherRequest {
  final double latitude;
  final double longitude;

  const WeatherRequest({required this.latitude, required this.longitude});

  Map<String, dynamic> toQueryParameters() => {
    'latitude': latitude,
    'longitude': longitude,
  };
}

/// Weather API service for fetching weather information
class WeatherApiService extends BaseService {
  WeatherApiService({super.apiClient});

  /// Fetch weather information for given coordinates
  Future<Weather> fetchWeather(WeatherRequest request) async {
    return executeApiCall(() async {
      debugPrint(
        '🌦️ [API] Fetching weather for: lat=${request.latitude}, lon=${request.longitude}',
      );

      final response = await apiClient.get(
        ApiConstants.getWeatherEndpoint,
        queryParameters: request.toQueryParameters(),
      );

      debugPrint('✅ Weather Response status: ${response.statusCode}');
      debugPrint('📦 Weather Raw: ${response.data}');

      if (response.data is Map) {
        final res = response.data as Map<String, dynamic>;
        final weatherJson = res['data'] ?? response.data;

        debugPrint('🌤️ Weather JSON: $weatherJson');

        if (weatherJson is Map<String, dynamic>) {
          return Weather.fromApiResponse(weatherJson);
        } else {
          debugPrint('⚠️ Unexpected weather data format: $weatherJson');
          throw Exception('Unexpected weather data format');
        }
      }

      throw Exception('Failed to fetch weather: Invalid response format');
    });
  }

  /// Convenience method for direct coordinate input
  Future<Weather> fetchWeatherByCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    return fetchWeather(
      WeatherRequest(latitude: latitude, longitude: longitude),
    );
  }
}
