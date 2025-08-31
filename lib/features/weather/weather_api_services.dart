import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/features/weather/weather_model.dart';
import 'package:krishi_link/services/api_service.dart';

class WeatherApiServices extends ApiService {
  WeatherApiServices() : super();

  Future<Weather> fetchWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      debugPrint(
        '🌦️ [API] Fetching weather for: lat=$latitude, lon=$longitude',
      );

      final opts = await getJsonOptions();

      final response = await dio.get(
        // 'https://w1vqqn7ucvzpndp9xsvdkd15gzcedswvilahs3agd6b3dljo7tg24pbklk4u.shamir.com.np/api/weather/getWeatherDetails?latitude=28.1994&longitude=83.9784',
        '${ApiConstants.getWeatherEndpoint}',
        queryParameters: {'latitude': latitude, 'longitude': longitude},
        options: opts,
      );

      debugPrint('✅ Weather Response status: ${response.statusCode}');
      debugPrint('📦 Weather Raw: ${response.data}');

      if (response.statusCode == 200 && response.data is Map) {
        final res = response.data as Map<String, dynamic>;

        final weatherJson = res['data'] ?? response.data;
        debugPrint('🌤️ Weather JSON: $weatherJson');

        if (weatherJson is Map<String, dynamic>) {
          // return Weather.fromJson(weatherJson);
          return Weather.fromApiResponse(weatherJson);
        } else {
          debugPrint('⚠️ Unexpected weather data format: $weatherJson');
          throw Exception('Unexpected weather data format');
        }
      }

      throw Exception('Failed to fetch weather: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error fetching weather: $e');
      if (e is DioException) {
        debugPrint('Dio error details: ${e.response?.data}');
        throw Exception(
          'Failed to fetch weather: ${e.response?.data['message'] ?? e.message ?? 'Network error'}',
        );
      }
      rethrow;
    }
  }
}
