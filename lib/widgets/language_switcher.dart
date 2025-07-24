import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/controllers/language_controller.dart';

class LanguageSwitcher extends StatelessWidget {
  final Color? backgroundColor;

  const LanguageSwitcher({super.key, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final langController = Get.find<LanguageController>();
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.language),
        tooltip: 'Change Language',
        onSelected: (langCode) {
          langController.changeLanguage(langCode);
        },
        itemBuilder:
            (context) => [
              PopupMenuItem(
                value: 'en',
                child: Row(children: const [Text('🇬🇧 English')]),
              ),
              PopupMenuItem(
                value: 'ne',
                child: Row(children: const [Text('🇳🇵 नेपाली')]),
              ),
            ],
      ),
    );
  }
}
