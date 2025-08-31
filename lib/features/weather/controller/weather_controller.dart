import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/features/weather/weather_api_services.dart';
import 'package:krishi_link/features/weather/weather_model.dart';

class WeatherController extends GetxController {
  final Rx<Weather?> weather = Rx<Weather?>(null);
  final RxString errorMessage = ''.obs;
  final RxBool isLoading = false.obs;

  final WeatherApiServices _apiServices =
      Get.isRegistered<WeatherApiServices>()
          ? Get.find<WeatherApiServices>()
          : Get.put(WeatherApiServices());

  static const String _weatherKey = 'saved_weather';

  @override
  void onInit() {
    super.onInit();
    // _loadSavedWeather();
    // fetchWeather(
    //   latitude: weather.value?.latitude ?? 28.0,
    //   longitude: weather.value?.longitude ?? 84.0,
    // );
  }

  Future<void> fetchWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final weatherData = await _apiServices.fetchWeather(
        latitude: latitude,
        longitude: longitude,
      );

      weather.value = weatherData;
      debugPrint(weather.value.toString());
      await _saveWeather(weatherData);
    } catch (e) {
      errorMessage.value = _mapError(e);
      weather.value ??= Weather.empty();
      PopupService.error(errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  /// Load last saved weather
  ///
  /// Expose a getter for loading saved weather
  Future<void> get loadSavedWeather => _loadSavedWeather();

  Future<void> _loadSavedWeather() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_weatherKey);

    if (jsonStr != null) {
      final saved = Weather.fromJson(jsonDecode(jsonStr));
      weather.value = saved;

      // Optionally refresh in background with latest
      fetchWeather(latitude: saved.latitude, longitude: saved.longitude);
    }
  }

  Future<void> refreshWeather(
    // required double latitude,
    // required double longitude,
  ) async {
    if (weather.value != null && weather.value!.latitude != 0) {
      await fetchWeather(
        latitude: weather.value!.latitude,
        longitude: weather.value!.longitude,
      );
    } else {
      // fallback: use GPS or default coords
      await fetchWeather(latitude: 28.2, longitude: 84.0);
    }
  }

  /// Save weather locally
  Future<void> _saveWeather(Weather data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_weatherKey, jsonEncode(data.toJson()));
  }

  /// Map different errors into user-friendly message
  String _mapError(dynamic e) {
    if (e is DioException) {
      return e.response?.data['message'] ?? e.message ?? 'Network error';
    }
    return e.toString();
  }
}
