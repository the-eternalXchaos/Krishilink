import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:krishi_link/src/features/weather/data/weather_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/features/weather/weather_model.dart';

class WeatherController extends GetxController {
  final Rx<Weather?> weather = Rx<Weather?>(null);
  final RxString errorMessage = ''.obs;
  final RxDouble latitude = 28.1994.obs;
  final RxDouble longitude = 83.9784.obs;
  final RxBool isLoading = false.obs;

  final WeatherApiService _apiServices =
      Get.isRegistered<WeatherApiService>()
          ? Get.find<WeatherApiService>()
          : WeatherApiService();

  static const String _weatherKey = 'saved_weather';

  @override
  void onInit() {
    super.onInit();
    _loadSavedWeather();
  }

  Future<void> _updateLoading(bool value) async {
    isLoading.value = value;
  }

  Future<void> fetchWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _updateLoading(true);
      errorMessage.value = '';

      final weatherData = await _apiServices.fetchWeatherByCoordinates(
        latitude: latitude,
        longitude: longitude,
      );

      weather.value = weatherData;

      // Save latest values for persistence
      await _saveWeather(weatherData);

      // Update local lat/long state
      this.latitude.value = weatherData.latitude;
      this.longitude.value = weatherData.longitude;
    } catch (e) {
      errorMessage.value = 'failed_to_fetch_weather'.trParams({
        'error': e.toString(),
      });
      PopupService.error(errorMessage.value);

      if (weather.value == null) {
        weather.value = Weather.empty();
      }
    } finally {
      await _updateLoading(false);
    }
  }

  void loadSavedWeather() {
    _loadSavedWeather();
  }

  Future<void> _loadSavedWeather() async {
    final prefs = await SharedPreferences.getInstance();
    final weatherJson = prefs.getString(_weatherKey);

    if (weatherJson != null) {
      final weatherData = Weather.fromJson(jsonDecode(weatherJson));
      weather.value = weatherData;

      // Update lat/lon state as well
      latitude.value = weatherData.latitude;
      debugPrint(latitude.value.toString());
      longitude.value = weatherData.longitude;
    }

    // Always try to refresh latest
    fetchWeather(latitude: latitude.value, longitude: longitude.value);
  }

  Future<void> _saveWeather(Weather weatherData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_weatherKey, jsonEncode(weatherData.toJson()));
  }
}
