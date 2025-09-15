// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:krishi_link/core/controllers/language_controller.dart';

// class LanguageSwitcher extends StatelessWidget {
//   final Color? backgroundColor;

//   const LanguageSwitcher({super.key, this.backgroundColor});

//   @override
//   Widget build(BuildContext context) {
//     final langController = Get.find<LanguageController>();
//     final theme = Theme.of(context);

//     return Container(
//       decoration: BoxDecoration(
//         color: backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       padding: const EdgeInsets.symmetric(horizontal: 4),
//       child: PopupMenuButton<String>(
//         icon: const Icon(Icons.language),
//         tooltip: 'change_language'.tr,
//         onSelected: (langCode) {
//           langController.changeLanguage(langCode);
//         },
//         itemBuilder: (context) => [
//           PopupMenuItem(
//             value: 'en',
//             child: Row(children: [Text('english'.tr)]),
//           ),
//           PopupMenuItem(
//             value: 'ne',
//             child: Row(children: [Text('nepali'.tr)]),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:krishi_link/core/controllers/language_controller.dart';

class LanguageSwitcher extends StatelessWidget {
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool showLabel;
  final bool showFlag;
  final LanguageSwitcherStyle style;

  const LanguageSwitcher({
    super.key,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
    this.borderRadius,
    this.padding,
    this.showLabel = false,
    this.showFlag = true,
    this.style = LanguageSwitcherStyle.dropdown,
  });

  @override
  Widget build(BuildContext context) {
    final langController = Get.find<LanguageController>();

    switch (style) {
      case LanguageSwitcherStyle.toggle:
        return _buildToggleStyle(context, langController);
      case LanguageSwitcherStyle.segmented:
        return _buildSegmentedStyle(context, langController);
      case LanguageSwitcherStyle.chips:
        return _buildChipsStyle(context, langController);
      case LanguageSwitcherStyle.dropdown:
        return _buildDropdownStyle(context, langController);
    }
  }

  /// Dropdown style (original enhanced)
  Widget _buildDropdownStyle(
    BuildContext context,
    LanguageController langController,
  ) {
    final theme = Theme.of(context);

    return Obx(() {
      final currentLang = langController.currentLanguageModel;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color:
              backgroundColor ??
              (theme.brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(borderRadius ?? 12),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 4),
        child: PopupMenuButton<String>(
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showFlag) ...[
                Text(currentLang.flag, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
              ],
              Icon(
                Icons.language,
                color: iconColor ?? theme.colorScheme.onSurface,
                size: 20,
              ),
              if (showLabel) ...[
                const SizedBox(width: 6),
                Text(
                  currentLang.code.toUpperCase(),
                  style: TextStyle(
                    color: textColor ?? theme.colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                color: iconColor ?? theme.colorScheme.onSurface,
                size: 16,
              ),
            ],
          ),
          tooltip: 'change_language'.tr,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
          onSelected: (langCode) {
            langController.changeLanguage(langCode);
          },
          itemBuilder:
              (context) =>
                  langController.allLanguages
                      .map(
                        (lang) => PopupMenuItem<String>(
                          value: lang.code,
                          child: FadeInRight(
                            duration: const Duration(milliseconds: 200),
                            child: Row(
                              children: [
                                Text(
                                  lang.flag,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        lang.nativeName,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight:
                                                  langController
                                                          .isLanguageSelected(
                                                            lang.code,
                                                          )
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                            ),
                                      ),
                                      Text(
                                        lang.name,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.6),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (langController.isLanguageSelected(
                                  lang.code,
                                ))
                                  Pulse(
                                    infinite: true,
                                    child: Icon(
                                      Icons.check_circle,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
        ),
      );
    });
  }

  /// Toggle style (switch between languages)
  Widget _buildToggleStyle(
    BuildContext context,
    LanguageController langController,
  ) {
    final theme = Theme.of(context);

    return Obx(() {
      final currentLang = langController.currentLanguageModel;
      final isChanging = langController.isChangingLanguage.value;

      return GestureDetector(
        onTap: isChanging ? null : () => langController.switchLanguage(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor ?? theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(borderRadius ?? 20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isChanging)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                )
              else
                Text(currentLang.flag, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                currentLang.nativeName,
                style: TextStyle(
                  color: textColor ?? theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// Segmented control style
  Widget _buildSegmentedStyle(
    BuildContext context,
    LanguageController langController,
  ) {
    final theme = Theme.of(context);

    return Obx(() {
      return Container(
        decoration: BoxDecoration(
          color:
              backgroundColor ??
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(borderRadius ?? 12),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children:
              langController.allLanguages.map((lang) {
                final isSelected = langController.isLanguageSelected(lang.code);

                return GestureDetector(
                  onTap: () => langController.changeLanguage(lang.code),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(lang.flag, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          lang.code.toUpperCase(),
                          style: TextStyle(
                            color:
                                isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      );
    });
  }

  /// Chips style (horizontal list)
  Widget _buildChipsStyle(
    BuildContext context,
    LanguageController langController,
  ) {
    final theme = Theme.of(context);

    return Obx(() {
      return Wrap(
        spacing: 8,
        children:
            langController.allLanguages.map((lang) {
              final isSelected = langController.isLanguageSelected(lang.code);

              return FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(lang.flag),
                    const SizedBox(width: 6),
                    Text(lang.nativeName, style: const TextStyle(fontSize: 12)),
                  ],
                ),
                onSelected: (_) => langController.changeLanguage(lang.code),
                selectedColor: theme.colorScheme.primaryContainer,
                checkmarkColor: theme.colorScheme.primary,
                backgroundColor: backgroundColor,
                side: BorderSide(
                  color:
                      isSelected
                          ? theme.colorScheme.primary
                          : theme.dividerColor.withValues(alpha: 0.2),
                ),
              );
            }).toList(),
      );
    });
  }
}

/// Language switcher styles
enum LanguageSwitcherStyle {
  dropdown, // Original popup menu style
  toggle, // Toggle between languages
  segmented, // Segmented control style
  chips, // Filter chips style
}

/// Compact language switcher for app bars
class CompactLanguageSwitcher extends StatelessWidget {
  final Color? iconColor;

  const CompactLanguageSwitcher({super.key, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return LanguageSwitcher(
      style: LanguageSwitcherStyle.toggle,
      showLabel: false,
      showFlag: true,
      backgroundColor: Colors.transparent,
      iconColor: iconColor,
      borderRadius: 16,
    );
  }
}

/// Language selection dialog for settings
class LanguageSelectionDialog extends StatelessWidget {
  const LanguageSelectionDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const LanguageSelectionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langController = Get.find<LanguageController>();
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.language, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text('select_language'.tr),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children:
            langController.allLanguages.map((lang) {
              return Obx(() {
                final isSelected = langController.isLanguageSelected(lang.code);
                final isChanging = langController.isChangingLanguage.value;

                return ListTile(
                  leading: Text(
                    lang.flag,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    lang.nativeName,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(lang.name),
                  trailing:
                      isChanging && isSelected
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : isSelected
                          ? Icon(
                            Icons.check_circle,
                            color: theme.colorScheme.primary,
                          )
                          : null,
                  onTap:
                      isChanging
                          ? null
                          : () {
                            langController.changeLanguage(lang.code);
                            Navigator.of(context).pop();
                          },
                );
              });
            }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('close'.tr),
        ),
      ],
    );
  }
}
