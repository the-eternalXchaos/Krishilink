import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:krishi_link/src/features/weather/data/weather_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/features/weather/weather_model.dart';

class WeatherController extends GetxController {
  // Observable properties with better typing
  final Rx<Weather?> weather = Rx<Weather?>(null);
  final RxString errorMessage = ''.obs;
  final RxDouble latitude = 28.1994.obs;
  final RxDouble longitude = 83.9784.obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;

  // Cached preferences instance to avoid repeated async calls
  SharedPreferences? _prefs;

  // API service with lazy initialization
  WeatherApiService? _apiService;
  WeatherApiService get _apiServices {
    return _apiService ??=
        Get.isRegistered<WeatherApiService>()
            ? Get.find<WeatherApiService>()
            : WeatherApiService();
  }

  // Constants
  static const String _weatherKey = 'saved_weather';
  static const String _latitudeKey = 'last_latitude';
  static const String _longitudeKey = 'last_longitude';
  static const Duration _cacheExpiration = Duration(hours: 1);
  static const String _lastUpdateKey = 'last_weather_update';

  @override
  void onInit() {
    super.onInit();
    _initializeController();
  }

  @override
  void onClose() {
    // Clean up resources
    _apiService = null;
    super.onClose();
  }

  /// Initialize controller with cached data
  Future<void> _initializeController() async {
    await _initPreferences();
    await _loadSavedWeather();
  }

  /// Initialize SharedPreferences once
  Future<void> _initPreferences() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Optimized loading state management
  Future<void> _updateLoading(bool value) async {
    if (isLoading.value != value) {
      isLoading.value = value;
    }
  }

  /// Optimized refreshing state management
  Future<void> _updateRefreshing(bool value) async {
    if (isRefreshing.value != value) {
      isRefreshing.value = value;
    }
  }

  /// Main method to fetch weather with improved error handling and caching
  Future<void> fetchWeather({
    required double latitude,
    required double longitude,
    bool forceRefresh = false,
  }) async {
    try {
      // Check if we need to fetch new data
      if (!forceRefresh && await _isCacheValid()) {
        debugPrint('📱 Using cached weather data');
        return;
      }

      await _updateLoading(true);
      errorMessage.value = '';

      debugPrint('🌤️ Fetching weather for: $latitude, $longitude');

      final weatherData = await _apiServices.fetchWeatherByCoordinates(
        latitude: latitude,
        longitude: longitude,
      );

      // Update state
      weather.value = weatherData;
      this.latitude.value = weatherData.latitude;
      this.longitude.value = weatherData.longitude;

      // Save to cache
      await _saveWeatherData(weatherData);
      await _saveLastUpdate();
      await _saveCoordinates(latitude, longitude);

      debugPrint('✅ Weather data updated successfully');
    } catch (e) {
      await _handleWeatherError(e);
    } finally {
      await _updateLoading(false);
    }
  }

  /// Refresh weather data with visual feedback
  Future<void> refreshWeather() async {
    if (weather.value == null) return;

    try {
      await _updateRefreshing(true);
      await fetchWeather(
        latitude: latitude.value,
        longitude: longitude.value,
        forceRefresh: true,
      );
    } finally {
      await _updateRefreshing(false);
    }
  }

  /// Handle weather fetch errors with better user feedback
  Future<void> _handleWeatherError(dynamic error) async {
    final errorMsg = 'failed_to_fetch_weather'.trParams({
      'error': _getReadableError(error),
    });

    errorMessage.value = errorMsg;
    PopupService.error(errorMsg);

    debugPrint('❌ Weather fetch error: $error');

    // Keep existing weather data if available
    if (weather.value == null) {
      weather.value = Weather.empty();
    }
  }

  /// Convert technical errors to user-friendly messages
  String _getReadableError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'network_error'.tr;
    } else if (errorString.contains('timeout')) {
      return 'timeout_error'.tr;
    } else if (errorString.contains('server')) {
      return 'server_error'.tr;
    }

    return 'unknown_error'.tr;
  }

  /// Check if cached data is still valid
  Future<bool> _isCacheValid() async {
    if (weather.value == null) return false;

    await _initPreferences();
    final lastUpdateString = _prefs!.getString(_lastUpdateKey);

    if (lastUpdateString == null) return false;

    final lastUpdate = DateTime.tryParse(lastUpdateString);
    if (lastUpdate == null) return false;

    final now = DateTime.now();
    final timeDifference = now.difference(lastUpdate);

    return timeDifference < _cacheExpiration;
  }

  /// Save last update timestamp
  Future<void> _saveLastUpdate() async {
    await _initPreferences();
    await _prefs!.setString(_lastUpdateKey, DateTime.now().toIso8601String());
  }

  /// Load saved weather data with improved error handling
  Future<void> _loadSavedWeather() async {
    try {
      await _initPreferences();

      // Load weather data
      final weatherJson = _prefs!.getString(_weatherKey);
      if (weatherJson != null) {
        final weatherData = Weather.fromJson(jsonDecode(weatherJson));
        weather.value = weatherData;

        // Update coordinates from weather data
        latitude.value = weatherData.latitude;
        longitude.value = weatherData.longitude;

        debugPrint('📱 Loaded cached weather data for ${weatherData.location}');
      } else {
        // Load last known coordinates
        await _loadSavedCoordinates();
      }

      // Try to refresh with latest data (non-blocking)
      _refreshIfNeeded();
    } catch (e) {
      debugPrint('⚠️ Error loading saved weather: $e');
      await _loadSavedCoordinates();
      _refreshIfNeeded();
    }
  }

  /// Load saved coordinates
  Future<void> _loadSavedCoordinates() async {
    await _initPreferences();

    final savedLat = _prefs!.getDouble(_latitudeKey);
    final savedLon = _prefs!.getDouble(_longitudeKey);

    if (savedLat != null && savedLon != null) {
      latitude.value = savedLat;
      longitude.value = savedLon;
      debugPrint('📍 Loaded saved coordinates: $savedLat, $savedLon');
    }
  }

  /// Save coordinates for persistence
  Future<void> _saveCoordinates(double lat, double lon) async {
    await _initPreferences();
    await _prefs!.setDouble(_latitudeKey, lat);
    await _prefs!.setDouble(_longitudeKey, lon);
  }

  /// Refresh weather data if cache is expired (non-blocking)
  void _refreshIfNeeded() {
    _isCacheValid().then((isValid) {
      if (!isValid) {
        fetchWeather(latitude: latitude.value, longitude: longitude.value);
      }
    });
  }

  /// Save weather data to cache with error handling
  Future<void> _saveWeatherData(Weather weatherData) async {
    try {
      await _initPreferences();
      final weatherJson = jsonEncode(weatherData.toJson());
      await _prefs!.setString(_weatherKey, weatherJson);
      debugPrint('💾 Weather data saved to cache');
    } catch (e) {
      debugPrint('⚠️ Error saving weather data: $e');
    }
  }

  /// Public method to manually load saved weather
  void loadSavedWeather() {
    _loadSavedWeather();
  }

  /// Clear cached weather data
  Future<void> clearWeatherCache() async {
    try {
      await _initPreferences();
      await _prefs!.remove(_weatherKey);
      await _prefs!.remove(_lastUpdateKey);

      weather.value = null;
      errorMessage.value = '';

      debugPrint('🗑️ Weather cache cleared');
      PopupService.info('weather_cache_cleared'.tr);
    } catch (e) {
      debugPrint('⚠️ Error clearing cache: $e');
    }
  }

  /// Get cache age for debugging
  Future<Duration?> getCacheAge() async {
    await _initPreferences();
    final lastUpdateString = _prefs!.getString(_lastUpdateKey);

    if (lastUpdateString == null) return null;

    final lastUpdate = DateTime.tryParse(lastUpdateString);
    if (lastUpdate == null) return null;

    return DateTime.now().difference(lastUpdate);
  }

  /// Check if weather data is available
  bool get hasWeatherData =>
      weather.value != null && weather.value != Weather.empty();

  /// Check if current location matches weather data location
  bool get isLocationSync {
    if (weather.value == null) return false;

    const tolerance = 0.001; // ~100m tolerance
    return (latitude.value - weather.value!.latitude).abs() < tolerance &&
        (longitude.value - weather.value!.longitude).abs() < tolerance;
  }

  /// Update location and fetch weather
  Future<void> updateLocation(double lat, double lon) async {
    latitude.value = lat;
    longitude.value = lon;

    await _saveCoordinates(lat, lon);
    await fetchWeather(latitude: lat, longitude: lon, forceRefresh: true);
  }
}
