import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/src/features/settings/presentation/controllers/settings_controller.dart';
import 'package:krishi_link/core/theme/app_theme.dart';
import 'package:krishi_link/core/translations/app_translations.dart';
import 'package:krishi_link/core/utils/translations.dart';

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsController>();

    return Obx(
      () => GetMaterialApp(
        translations: AppTranslations(),
        locale: Locale(
          settingsController.currentLanguage.value,
          settingsController.currentLanguage.value == 'en' ? 'US' : 'NP',
        ),
        fallbackLocale: const Locale('en', 'US'),
        initialBinding: BindingsBuilder(() {
          Get.put(settingsController);
        }),
        navigatorKey: Get.key,
        title: 'Krishi Link',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode:
            settingsController.isDarkMode.value
                ? ThemeMode.dark
                : ThemeMode.light,
        initialRoute: initialRoute,
        defaultTransition: Transition.fadeIn,
        // ... existing getPages configuration
      ),
    );
  }
}
