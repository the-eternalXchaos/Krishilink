// lib/core/widgets/app_widgets.dart
import 'package:flutter/material.dart';
import 'package:krishi_link/core/constants/app_spacing.dart';
import 'dart:async';
import 'ui.dart';
import 'buttons.dart';

/// Main collection of reusable UI widgets
class AppWidgets {
  static Widget textField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    required ColorScheme colorScheme,
    ValueChanged<String>? onChanged,
    FormFieldValidator<String>? validator,
    int? maxLines,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
  }) => UI.textField(
    controller: controller,
    label: label,
    icon: icon,
    colorScheme: colorScheme,
    onChanged: onChanged,
    validator: validator,
    maxLines: maxLines,
    obscureText: obscureText,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
  );

  static Widget card({
    required Widget child,
    String? title,
    IconData? icon,
    Color? iconColor,
    required ColorScheme colorScheme,
  }) => UI.card(
    child: child,
    title: title,
    icon: icon,
    iconColor: iconColor,
    colorScheme: colorScheme,
  );

  static Widget button({
    required String text,
    required VoidCallback? onPressed,
    bool loading = false,
    IconData? icon,
    ColorScheme? colorScheme,
  }) {
    colorScheme ??= ThemeData().colorScheme;
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, color: colorScheme.onPrimary) : null,
      label:
          loading
              ? CircularProgressIndicator(
                color: colorScheme.onPrimary,
                strokeWidth: 2,
              )
              : Text(text, style: TextStyle(color: colorScheme.onPrimary)),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // static Widget card({
  //   required Widget child,
  //   String? title,
  //   IconData? icon,
  //   Color? iconColor,
  //   ColorScheme? colorScheme,
  // }) => UI.card(
  //   child: child,
  //   title: title,
  //   icon: icon,
  //   iconColor: iconColor,
  //   colorScheme: colorScheme,
  // );

  // static Widget button({
  //   required String text,
  //   required VoidCallback onPressed,
  //   bool loading = false,
  //   IconData? icon,
  //   ColorScheme? colorScheme,
  // }) => Buttons.primary(
  //   text: text,
  //   onPressed: onPressed,
  //   loading: loading,
  //   icon: icon,
  //   colorScheme: colorScheme,
  // );

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
    String? errorText, // Added for validation
    Duration debounceDuration = const Duration(
      milliseconds: 300,
    ), // Added for debouncing
  }) {
    Timer? debounceTimer;
    return UI.dropdown(
      value: value,
      items: items,
      onChanged: (value) {
        debounceTimer?.cancel();
        debounceTimer = Timer(debounceDuration, () => onChanged(value));
      },
      label: label,
      icon: icon,
      colorScheme: colorScheme,
      errorText: errorText,
    );
  }
}
