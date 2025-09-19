import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/lottie/pop_up.dart';
import 'package:krishi_link/core/theme/app_theme.dart';
import 'package:krishi_link/src/core/constants/constants.dart';
import 'package:lottie/lottie.dart';

class PopupService {
  /// Show loading popup with custom Lottie animation
  /// Displays a loading dialog with a Lottie animation and a message.
  ///
  /// The dialog is centered on the screen and contains a loading animation
  /// along with a "Please wait..." message. The dialog can be configured
  /// to be dismissible by tapping outside of it.
  ///
  /// Parameters:
  /// - [barrierDismissible]: A boolean value that determines whether the
  ///   dialog can be dismissed by tapping on the barrier (the area outside
  ///   the dialog). Defaults to false.
  static void lottieLoading({bool barrierDismissible = false}) {
    // final themeColor  = Theme.of(context).colorScheme.surface;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isDialogOpen != true) {
        Get.dialog(
          Container(
            width: 150,
            height: 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      }
    });
  }

  /// Close the popup
  static void close() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  static void show({
    required PopupType type,
    required String title,
    required String message,
    bool autoDismiss = false,
    Duration? duration,
    bool repeat = true,
  }) {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (Get.isDialogOpen != true) {
        Get.dialog(
          Popup(
            type: type,
            title: title,
            message: message,
            autoDismiss: autoDismiss,
            // duration: duration,
          ),
          barrierDismissible: true,
        );
      }
    });
  }

  /// 🎯 UNIFIED FEEDBACK SYSTEM
  /// Intelligently decides between popup and snackbar based on message type and urgency
  ///
  /// Usage Examples:
  /// - handleFeedback(title: 'Success', message: 'Product added to cart', type: PopupType.addedToCart)
  /// - handleFeedback(title: 'Error', message: 'Failed to place order', type: PopupType.error)
  /// - handleFeedback(title: 'Info', message: 'Order processing in background', type: PopupType.info)
  static void handleFeedback({
    required String title,
    required String message,
    required PopupType type,
    bool forcePopup = false,
    Duration? duration,
    required bool autoDismiss,
  }) {
    // 🎭 Decide: use popup or snackbar?
    final popupTypes = {
      PopupType.success,
      PopupType.error,
      PopupType.warning,
      PopupType.orderPlaced,
      PopupType.party,
    };

    final shouldShowPopup = forcePopup || popupTypes.contains(type);

    if (shouldShowPopup) {
      // 🎪 Show popup for critical or visual types
      show(
        type: type,
        title: title,
        message: message,
        autoDismiss: true,
        duration: duration,
      );
    } else {
      // 🍿 Show snackbar for lightweight ones like info, addedToCart
      showSnackbar(
        title: title,
        message: message,
        type: type,
        duration: duration,
      );
    }
  }

  /// 🍿 Enhanced Snackbar with consistent styling
  static void showSnackbar({
    required String title,
    required String message,
    PopupType type = PopupType.info,
    Duration? duration,
    SnackPosition position = SnackPosition.TOP,
  }) {
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
      margin: EdgeInsets.all(8),
      borderRadius: 8,
      dismissDirection: DismissDirection.horizontal,
    );
  }

  /// 🚀 QUICK FEEDBACK METHODS for common use cases

  /// Success feedback
  static void success(String message, {String title = 'Success'}) {
    handleFeedback(
      title: title,
      message: message,
      type: PopupType.success,
      autoDismiss: true,
    );
  }

  /// Error feedback
  static void error(String message, {String title = 'Error'}) {
    handleFeedback(
      title: title,
      message: message,
      type: PopupType.error,
      autoDismiss: true,
    );
  }

  /// Warning feedback
  static void warning(String message, {String title = 'Warning'}) {
    handleFeedback(
      title: title,
      message: message,
      type: PopupType.warning,
      autoDismiss: true,
    );
  }

  /// Info feedback
  static void info(String message, {String title = 'Info'}) {
    handleFeedback(
      title: title,
      message: message,
      type: PopupType.info,
      autoDismiss: true,
    );
  }

  /// Added to cart feedback
  static void addedToCart(String message, {String title = 'Added to Cart'}) {
    handleFeedback(
      title: title,
      message: message,
      type: PopupType.addedToCart,
      autoDismiss: true,
    );
  }

  /// Order placed feedback
  static void orderPlaced(String message, {String title = 'Order Placed'}) {
    handleFeedback(
      title: title,
      message: message,
      type: PopupType.orderPlaced,
      autoDismiss: true,
    );
  }

  /// Party/celebration feedback
  static void party(String message, {String title = 'Congratulations'}) {
    handleFeedback(
      title: title,
      message: message,
      type: PopupType.party,
      autoDismiss: true,
    );
  }

  /// 🎯 NATURAL LANGUAGE FEEDBACK  (AI-friendly)
  /// Parse natural language and show appropriate feedback
  static void showFeedback(String naturalText) {
    final text = naturalText.toLowerCase();

    if (text.contains('success') ||
        text.contains('successfully') ||
        text.contains('done')) {
      success(naturalText);
    } else if (text.contains('error') ||
        text.contains('failed') ||
        text.contains('wrong')) {
      error(naturalText);
    } else if (text.contains('warning') ||
        text.contains('attention') ||
        text.contains('careful')) {
      warning(naturalText);
    } else if (text.contains('cart') || text.contains('added')) {
      addedToCart(naturalText);
    } else if (text.contains('order') ||
        text.contains('placed') ||
        text.contains('confirmed')) {
      orderPlaced(naturalText);
    } else if (text.contains('congratulations') ||
        text.contains('celebration') ||
        text.contains('party')) {
      party(naturalText);
    } else {
      info(naturalText);
    }
  }
}
