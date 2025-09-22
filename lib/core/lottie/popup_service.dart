import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:krishi_link/src/core/components/material_ui/pop_up.dart';

class PopupService {
  /// Show loading popup with custom Lottie animation
  static void lottieLoading({bool barrierDismissible = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isDialogOpen != true) {
        final size = Get.size;
        Get.dialog(
          Center(
            child: Container(
              width: size.width * 0.4,
              height: size.height * 0.25,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/lottie/loading.json',
                    width: 100,
                    height: 100,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Please wait...',
                    style: TextStyle(color: Colors.green.shade900),
                  ),
                ],
              ),
            ),
          ),
          barrierDismissible: barrierDismissible,
          barrierColor: Colors.black.withValues(alpha: 0.3),
        );
      }
    });
  }

  /// Close the popup or dialog
  static void close() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  /// Show a custom popup
  static void show({
    required PopupType type,
    required String title,
    required String message,
    bool autoDismiss = false,
    Duration? duration,
  }) {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (Get.isDialogOpen != true) {
        Get.dialog(
          Popup(
            type: type,
            title: title,
            message: message,
            autoDismiss: autoDismiss,
          ),
          barrierDismissible: true,
        );

        if (autoDismiss) {
          Future.delayed(duration ?? const Duration(seconds: 3), () {
            close();
          });
        }
      }
    });
  }

  /// Unified feedback: decides between popup and snackbar
  static void handleFeedback({
    required String title,
    required String message,
    required PopupType type,
    bool forcePopup = false,
    Duration? duration,
    required bool autoDismiss,
  }) {
    final popupTypes = {
      PopupType.success,
      PopupType.error,
      PopupType.warning,
      PopupType.orderPlaced,
      PopupType.party,
    };

    final shouldShowPopup = forcePopup || popupTypes.contains(type);

    if (shouldShowPopup) {
      show(
        type: type,
        title: title,
        message: message,
        autoDismiss: true,
        duration: duration,
      );
    } else {
      showSnackbar(
        title: title,
        message: message,
        type: type,
        duration: duration,
      );
    }
  }

  /// Show styled snackbar
  static void showSnackbar({
    required String title,
    required String message,
    PopupType type = PopupType.info,
    Duration? duration,
    SnackPosition position = SnackPosition.TOP,
  }) {
    if (Get.isSnackbarOpen) Get.closeAllSnackbars();

    Color bgColor;
    IconData icon;

    switch (type) {
      case PopupType.success:
        bgColor = Colors.green.shade700;
        icon = Icons.check_circle;
        break;
      case PopupType.error:
        bgColor = Colors.red.shade700;
        icon = Icons.error_outline;
        break;
      case PopupType.warning:
        bgColor = Colors.orange.shade700;
        icon = Icons.warning;
        break;
      case PopupType.info:
        bgColor = Colors.blue.shade700;
        icon = Icons.info;
        break;
      case PopupType.addedToCart:
        bgColor = Colors.teal.shade700;
        icon = Icons.shopping_cart;
        break;
      case PopupType.orderPlaced:
        bgColor = Colors.deepPurple.shade700;
        icon = Icons.shopping_bag;
        break;
      case PopupType.userLoading:
        bgColor = Colors.green.shade700;
        icon = Icons.person;
        break;
      case PopupType.party:
        bgColor = Colors.purple.shade700;
        icon = Icons.celebration;
        break;
    }

    Get.snackbar(
      title,
      message,
      snackPosition: position,
      backgroundColor: bgColor,
      colorText: Colors.white,
      duration: duration ?? Duration(seconds: type == PopupType.error ? 5 : 3),
      icon: Icon(icon, color: Colors.white),
      margin: const EdgeInsets.all(8),
      borderRadius: 8,
      dismissDirection: DismissDirection.horizontal,
    );
  }

  /// Quick feedback shortcuts
  static void success(String message, {String title = 'Success'}) =>
      handleFeedback(
        title: title,
        message: message,
        type: PopupType.success,
        autoDismiss: true,
      );

  static void error(String message, {String title = 'Error'}) => handleFeedback(
    title: title,
    message: message,
    type: PopupType.error,
    autoDismiss: true,
  );

  static void warning(String message, {String title = 'Warning'}) =>
      handleFeedback(
        title: title,
        message: message,
        type: PopupType.warning,
        autoDismiss: true,
      );

  static void info(String message, {String title = 'Info'}) => handleFeedback(
    title: title,
    message: message,
    type: PopupType.info,
    autoDismiss: true,
  );

  static void addedToCart(String message, {String title = 'Added to Cart'}) =>
      handleFeedback(
        title: title,
        message: message,
        type: PopupType.addedToCart,
        autoDismiss: true,
      );

  static void orderPlaced(String message, {String title = 'Order Placed'}) =>
      handleFeedback(
        title: title,
        message: message,
        type: PopupType.orderPlaced,
        autoDismiss: true,
      );

  static void party(String message, {String title = 'Congratulations'}) =>
      handleFeedback(
        title: title,
        message: message,
        type: PopupType.party,
        autoDismiss: true,
      );

  /// AI-friendly natural language feedback
  static void showFeedback(String naturalText) {
    final text = naturalText.toLowerCase();

    if (text.contains('success') || text.contains('done')) {
      success(naturalText);
    } else if (text.contains('error') || text.contains('failed')) {
      error(naturalText);
    } else if (text.contains('warning') || text.contains('attention')) {
      warning(naturalText);
    } else if (text.contains('cart') || text.contains('added')) {
      addedToCart(naturalText);
    } else if (text.contains('order') ||
        text.contains('placed') ||
        text.contains('confirmed')) {
      orderPlaced(naturalText);
    } else if (text.contains('congratulations') || text.contains('party')) {
      party(naturalText);
    } else {
      info(naturalText);
    }
  }
}
