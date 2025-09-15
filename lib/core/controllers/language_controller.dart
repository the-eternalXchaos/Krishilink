// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class LanguageController extends GetxController {
//   final RxString currentLanguage = 'en_US'.obs;
//   static const String _langKey = 'language';

//   Locale get currentLocale {
//     final parts = currentLanguage.value.split('_');
//     return Locale(parts[0], parts.length > 1 ? parts[1] : 'US');
//   }

//   @override
//   void onInit() {
//     super.onInit();
//     loadSavedLanguage();
//   }

//   Future<void> loadSavedLanguage() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final savedLang = prefs.getString(_langKey) ?? 'en_US';
//       currentLanguage.value = savedLang;
//       await updateLocale(savedLang);
//     } catch (e) {
//       debugPrint('Error loading language: $e');
//     }
//   }

//   Future<void> switchLanguage() async {
//     final newLang = currentLanguage.value.startsWith('en') ? 'ne_NP' : 'en_US';
//     await changeLanguage(newLang.split('_')[0]);
//   }

//   Future<void> changeLanguage(String langCode) async {
//     final fullCode = langCode == 'en' ? 'en_US' : 'ne_NP';
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_langKey, fullCode);
//     currentLanguage.value = fullCode;
//     await updateLocale(fullCode);
//   }

//   Future<void> updateLocale(String langCode) async {
//     final parts = langCode.split('_');
//     final locale = Locale(parts[0], parts.length > 1 ? parts[1] : 'US');
//     Get.updateLocale(locale);
//   }
// }
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends GetxController {
  final RxString currentLanguage = 'en_US'.obs;
  final RxBool isChangingLanguage = false.obs;
  final RxBool hasLanguageChanged = false.obs;

  static const String _langKey = 'language';
  static const String _firstLaunchKey = 'first_language_setup';

  // Supported languages with their details
  final Map<String, LanguageModel> supportedLanguages = {
    'en': LanguageModel(
      code: 'en',
      fullCode: 'en_US',
      name: 'English',
      nativeName: 'English',
      flag: '🇺🇸',
      rtl: false,
    ),
    'ne': LanguageModel(
      code: 'ne',
      fullCode: 'ne_NP',
      name: 'Nepali',
      nativeName: 'नेपाली',
      flag: '🇳🇵',
      rtl: false,
    ),
  };

  // Getters
  Locale get currentLocale {
    final parts = currentLanguage.value.split('_');
    return Locale(parts[0], parts.length > 1 ? parts[1] : 'US');
  }

  String get currentLanguageCode => currentLanguage.value.split('_')[0];

  LanguageModel get currentLanguageModel =>
      supportedLanguages[currentLanguageCode] ?? supportedLanguages['en']!;

  bool get isFirstLaunch =>
      !Get.find<SharedPreferences>().containsKey(_firstLaunchKey);

  @override
  void onInit() {
    super.onInit();
    _initializeLanguageController();
  }

  Future<void> _initializeLanguageController() async {
    try {
      await Get.putAsync(() => SharedPreferences.getInstance());
      await loadSavedLanguage();
    } catch (e) {
      debugPrint('❌ Error initializing language controller: $e');
      // Fallback to default language
      currentLanguage.value = 'en_US';
      await updateLocale('en_US');
    }
  }

  /// Load the saved language preference
  Future<void> loadSavedLanguage() async {
    try {
      final prefs = Get.find<SharedPreferences>();
      final savedLang = prefs.getString(_langKey) ?? _detectSystemLanguage();

      debugPrint('🌐 Loading saved language: $savedLang');

      currentLanguage.value = savedLang;
      await updateLocale(savedLang);

      // Mark first launch as complete if not already done
      if (isFirstLaunch) {
        await prefs.setBool(_firstLaunchKey, true);
      }
    } catch (e) {
      debugPrint('❌ Error loading language: $e');
      await _setDefaultLanguage();
    }
  }

  /// Detect system language and return appropriate language code
  String _detectSystemLanguage() {
    final systemLocale = Get.deviceLocale;
    final systemLangCode = systemLocale?.languageCode ?? 'en';

    // Check if system language is supported
    if (supportedLanguages.containsKey(systemLangCode)) {
      return supportedLanguages[systemLangCode]!.fullCode;
    }

    return 'en_US'; // Default fallback
  }

  /// Set default language with error handling
  Future<void> _setDefaultLanguage() async {
    try {
      currentLanguage.value = 'en_US';
      await updateLocale('en_US');
      await _saveLanguagePreference('en_US');
    } catch (e) {
      debugPrint('❌ Error setting default language: $e');
    }
  }

  /// Switch between available languages (for toggle functionality)
  Future<void> switchLanguage() async {
    if (isChangingLanguage.value) return;

    final newLang = currentLanguageCode == 'en' ? 'ne_NP' : 'en_US';
    await changeLanguage(newLang.split('_')[0]);
  }

  /// Change to specific language with enhanced feedback
  Future<void> changeLanguage(String langCode) async {
    if (isChangingLanguage.value || langCode == currentLanguageCode) return;

    try {
      isChangingLanguage.value = true;

      // Validate language code
      if (!supportedLanguages.containsKey(langCode)) {
        throw Exception('Unsupported language code: $langCode');
      }

      final fullCode = supportedLanguages[langCode]!.fullCode;

      debugPrint(
        '🌐 Changing language from ${currentLanguage.value} to $fullCode',
      );

      // Save preference first
      await _saveLanguagePreference(fullCode);

      // Update reactive variable
      currentLanguage.value = fullCode;

      // Update GetX locale
      await updateLocale(fullCode);

      // Mark that language has changed
      hasLanguageChanged.value = true;

      // Show success feedback
      _showLanguageChangeSuccess(supportedLanguages[langCode]!);

      // Reset the flag after a delay
      Future.delayed(const Duration(seconds: 2), () {
        hasLanguageChanged.value = false;
      });
    } catch (e) {
      debugPrint('❌ Error changing language: $e');
      _showLanguageChangeError();
    } finally {
      isChangingLanguage.value = false;
    }
  }

  /// Save language preference to SharedPreferences
  Future<void> _saveLanguagePreference(String fullCode) async {
    try {
      final prefs = Get.find<SharedPreferences>();
      await prefs.setString(_langKey, fullCode);
      debugPrint('💾 Language preference saved: $fullCode');
    } catch (e) {
      debugPrint('❌ Error saving language preference: $e');
      rethrow;
    }
  }

  /// Update GetX locale with error handling
  Future<void> updateLocale(String langCode) async {
    try {
      final parts = langCode.split('_');
      final locale = Locale(parts[0], parts.length > 1 ? parts[1] : null);

      debugPrint('🔄 Updating locale to: $locale');
      Get.updateLocale(locale);
    } catch (e) {
      debugPrint('❌ Error updating locale: $e');
      rethrow;
    }
  }

  /// Show success feedback when language changes
  void _showLanguageChangeSuccess(LanguageModel language) {
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();

    Get.snackbar(
      'language_changed'.tr,
      '${'language_changed_to'.tr} ${language.nativeName}',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.primaryContainer,
      colorText: Get.theme.colorScheme.onPrimaryContainer,
      icon: Icon(Icons.language, color: Get.theme.colorScheme.primary),
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
    );
  }

  /// Show error feedback when language change fails
  void _showLanguageChangeError() {
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();

    Get.snackbar(
      'error'.tr,
      'language_change_failed'.tr,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.errorContainer,
      colorText: Get.theme.colorScheme.onErrorContainer,
      icon: Icon(Icons.error_outline, color: Get.theme.colorScheme.error),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  /// Get all supported languages list
  List<LanguageModel> get allLanguages => supportedLanguages.values.toList();

  /// Check if a language is currently selected
  bool isLanguageSelected(String langCode) => langCode == currentLanguageCode;

  /// Reset to system language
  Future<void> resetToSystemLanguage() async {
    final systemLang = _detectSystemLanguage();
    if (systemLang != currentLanguage.value) {
      await changeLanguage(systemLang.split('_')[0]);
    }
  }

  /// Clear language preferences (for testing/debugging)
  Future<void> clearLanguagePreferences() async {
    try {
      final prefs = Get.find<SharedPreferences>();
      await prefs.remove(_langKey);
      await prefs.remove(_firstLaunchKey);
      debugPrint('🗑️ Language preferences cleared');
    } catch (e) {
      debugPrint('❌ Error clearing language preferences: $e');
    }
  }

  @override
  void onClose() {
    // Clean up if needed
    super.onClose();
  }
}

/// Language model to hold language information
class LanguageModel {
  final String code; // e.g., 'en'
  final String fullCode; // e.g., 'en_US'
  final String name; // e.g., 'English'
  final String nativeName; // e.g., 'English' or 'नेपाली'
  final String flag; // e.g., '🇺🇸'
  final bool rtl; // Right-to-left text direction

  const LanguageModel({
    required this.code,
    required this.fullCode,
    required this.name,
    required this.nativeName,
    required this.flag,
    this.rtl = false,
  });

  @override
  String toString() =>
      'LanguageModel(code: $code, name: $name, nativeName: $nativeName)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LanguageModel && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;
}
