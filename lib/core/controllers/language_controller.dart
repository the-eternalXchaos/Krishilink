import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends GetxController {
  final RxString currentLanguage = 'en_US'.obs;
  static const String _langKey = 'language';

  Locale get currentLocale {
    final parts = currentLanguage.value.split('_');
    return Locale(parts[0], parts.length > 1 ? parts[1] : 'US');
  }

  @override
  void onInit() {
    super.onInit();
    loadSavedLanguage();
  }

  Future<void> loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString(_langKey) ?? 'en_US';
      currentLanguage.value = savedLang;
      await updateLocale(savedLang);
    } catch (e) {
      debugPrint('Error loading language: $e');
    }
  }

  Future<void> switchLanguage() async {
    final newLang = currentLanguage.value.startsWith('en') ? 'ne_NP' : 'en_US';
    await changeLanguage(newLang.split('_')[0]);
  }

  Future<void> changeLanguage(String langCode) async {
    final fullCode = langCode == 'en' ? 'en_US' : 'ne_NP';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, fullCode);
    currentLanguage.value = fullCode;
    await updateLocale(fullCode);
  }

  Future<void> updateLocale(String langCode) async {
    final parts = langCode.split('_');
    final locale = Locale(parts[0], parts.length > 1 ? parts[1] : 'US');
    Get.updateLocale(locale);
  }
}
