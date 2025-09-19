import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppBottomSheet {
  static Future<T?> show<T>({
    required Widget child,
    double initialChildSize = 0.6,
    double minChildSize = 0.4,
    double maxChildSize = 0.95,
    bool isDismissible = true,
    bool enableDrag = true,
    bool useSafeArea = true,
    Color backgroundColor = Colors.transparent,
  }) {
    return showModalBottomSheet<T>(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return DraggableScrollableSheet(
          initialChildSize: initialChildSize,
          minChildSize: minChildSize,
          maxChildSize: maxChildSize,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child:
                        useSafeArea
                            ? SafeArea(
                              top: false,
                              child: SingleChildScrollView(
                                controller: scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: child,
                              ),
                            )
                            : SingleChildScrollView(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: child,
                            ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
