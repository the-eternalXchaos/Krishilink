import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ThemeController extends GetxController {
  Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  void toggleTheme(bool isDark) {
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }
}

// in main.dart
/*
final ThemeController themeController = Get.put(ThemeController());

return Obx(() => MaterialApp(
  title: 'KrishiLink',
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: themeController.themeMode.value,
  home: YourHomePage(),
));
*/




// tohgle button in settings page
/*
SwitchListTile(
  title: Text('Dark Mode'),
  value: themeController.themeMode.value == ThemeMode.dark,
  onChanged: (value) {
    themeController.toggleTheme(value);
  },
),
*/

/*
// button of the switch of dark mode in settings page
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Row(
      children: const [
        Icon(Icons.brightness_6),
        SizedBox(width: 10),
        Text("Dark Mode"),
      ],
    ),
    Obx(() => Switch(
      value: themeController.themeMode.value == ThemeMode.dark,
      onChanged: (value) {
        themeController.toggleTheme(value);
      },
    )),
  ],
)

*/