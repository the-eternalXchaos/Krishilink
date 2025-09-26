import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:krishi_link/src/features/language/presentation/controllers/language_controller.dart';
import 'package:krishi_link/src/features/settings/presentation/controllers/settings_controller.dart';

class SettingsController extends GetxController {
  static SettingsController get to => Get.find();

  final RxBool isDarkMode = false.obs;
  final LanguageController languageController = Get.put(LanguageController());
  RxString get currentLanguage => languageController.currentLanguage;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode.value = prefs.getBool('isDarkMode') ?? false;

    // Load persisted theme
    await updateTheme(isDarkMode.value);

    // Language is now loaded in LanguageController.onInit
    // so no need to load it again here
  }

  Future<void> toggleTheme() async {
    isDarkMode.value = !isDarkMode.value;
    await updateTheme(isDarkMode.value);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode.value);
  }

  Future<void> updateTheme(bool darkMode) async {
    Get.changeThemeMode(darkMode ? ThemeMode.dark : ThemeMode.light);
  }

  void toggleLanguage() {
    final newLang = currentLanguage.value == 'en_US' ? 'ne' : 'en';
    languageController.changeLanguage(newLang);
  }
}
