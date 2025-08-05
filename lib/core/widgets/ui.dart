// lib/core/widgets/ui.dart
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import '../constants/app_spacing.dart';

/// General UI components for consistent styling
class UI {
  /// Modern TextField with consistent styling
  static Widget textField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    ColorScheme? colorScheme,
    ValueChanged<String>? onChanged,
    FormFieldValidator<String>? validator,
    int? maxLines = 1,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
  }) {
    colorScheme ??= ThemeData().colorScheme.copyWith(
      surface: Colors.green.shade100,
      surfaceContainerHighest: Colors.green.shade50,
      primary: Colors.green.shade700,
    );
    debugPrint(
      'UI.textField - Surface: ${colorScheme.surface}, Primary: ${colorScheme.primary}',
    );
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      validator: validator,
      maxLines: maxLines,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            icon != null ? Icon(icon, color: colorScheme.primary) : null,
        filled: true,
        fillColor: colorScheme.surface.withValues(
          alpha: 0.7,
        ), // Increased alpha
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }

  /// Modern Card with shadow and rounded corners
  static Widget card({
    required Widget child,
    String? title,
    IconData? icon,
    Color? iconColor,
    ColorScheme? colorScheme,
  }) {
    debugPrint(
      'UI.card - Surface: ${colorScheme?.surface}, Primary: ${colorScheme?.primary}',
    );
    return Container(
      decoration: BoxDecoration(
        color: colorScheme?.surface, // Ensure green shade
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme!.shadow.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color:
                          iconColor?.withValues(alpha: 0.1) ??
                          colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon ?? Icons.info,
                      color: iconColor ?? colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            child,
          ],
        ),
      ),
    );
  }

  /// Modern Dropdown with consistent styling
  static Widget dropdown({
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String label,
    IconData? icon,
    ColorScheme? colorScheme,
    String? errorText,
  }) {
    colorScheme ??= ThemeData().colorScheme.copyWith(
      surface: Colors.green.shade100,
      surfaceContainerHighest: Colors.green.shade50,
      primary: Colors.green.shade700,
    );
    debugPrint(
      'UI.dropdown - Surface: ${colorScheme.surface}, Primary: ${colorScheme.primary}',
    );
    return DropdownButtonFormField<String>(
      value: value,
      items:
          items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(color: colorScheme?.onSurface, fontSize: 16),
              ),
            );
          }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            icon != null ? Icon(icon, color: colorScheme.primary) : null,
        errorText: errorText,
        filled: true,
        fillColor: colorScheme.surface.withValues(
          alpha: 0.7,
        ), // Increased alpha
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
      dropdownColor: colorScheme.surface,
      icon: Icon(Icons.arrow_drop_down, color: colorScheme.primary),
    );
  }
}
