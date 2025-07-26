// lib/core/widgets/app_widgets.dart
import 'package:flutter/material.dart';
import 'ui.dart';
import 'buttons.dart';

/// Main collection of reusable UI widgets
class AppWidgets {
  static Widget textField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    ColorScheme? colorScheme,
  }) => UI.textField(
    controller: controller,
    label: label,
    icon: icon,
    colorScheme: colorScheme,
  );

  static Widget card({
    required Widget child,
    String? title,
    IconData? icon,
    Color? iconColor,
    ColorScheme? colorScheme,
  }) => UI.card(
    child: child,
    title: title,
    icon: icon,
    iconColor: iconColor,
    colorScheme: colorScheme,
  );

  static Widget button({
    required String text,
    required VoidCallback onPressed,
    bool loading = false,
    IconData? icon,
    ColorScheme? colorScheme,
  }) => Buttons.primary(
    text: text,
    onPressed: onPressed,
    loading: loading,
    icon: icon,
    colorScheme: colorScheme,
  );

  static Widget secondaryButton({
    required String text,
    required VoidCallback onPressed,
    ColorScheme? colorScheme,
  }) => Buttons.secondary(
    text: text,
    onPressed: onPressed,
    colorScheme: colorScheme,
  );

  static Widget dropdown({
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String label,
    IconData? icon,
    ColorScheme? colorScheme,
  }) => UI.dropdown(
    value: value,
    items: items,
    onChanged: onChanged,
    label: label,
    icon: icon,
    colorScheme: colorScheme,
  );
}
