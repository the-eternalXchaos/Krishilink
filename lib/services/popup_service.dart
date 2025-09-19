// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import 'package:krishi_link/core/theme/app_theme.dart';
// import 'package:krishi_link/core/utils/constants.dart';
// import 'package:lottie/lottie.dart';

// class PopupService {
//   /// Show loading popup with custom Lottie animation
//   /// Displays a loading dialog with a Lottie animation and a message.
//   ///
//   /// The dialog is centered on the screen and contains a loading animation
//   /// along with a "Please wait..." message. The dialog can be configured
//   /// to be dismissible by tapping outside of it.
//   ///
//   /// Parameters:
//   /// - [barrierDismissible]: A boolean value that determines whether the
//   ///   dialog can be dismissed by tapping on the barrier (the area outside
//   ///   the dialog). Defaults to false.
//   static lottieLoading({bool barrierDismissible = false}) {
//     // final themeColor  = Theme.of(context).colorScheme.surface;
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (Get.isDialogOpen != true) {
//         Get.dialog(
//           Container(
//             width: 150,
//             height: 250,
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.green.shade100,
//               borderRadius: BorderRadius.circular(20),
//             ),
//           ),
//         );
//       }
//     });
//   }

//   // static void close() {
//   //   if (Get.isDialogOpen ?? false) {
//   //     Get.back();
//   //   }
//   // }

//   static void show({
//     required PopupType type,
//     required String title,
//     required String message,
//     bool autoDismiss = false,
//   }) {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (Get.isDialogOpen != true) {
//         Get.dialog(
//           Popup(
//             type: type,
//             title: title,
//             message: message,
//             autoDismiss: autoDismiss,
//           ),
//           barrierDismissible: true,
//         );

//         if (autoDismiss = false) {
//           Future.delayed(const Duration(seconds: 3), () {
//             if (Get.isDialogOpen ?? false) {
//               Get.back();
//             }
//           });
//         }
//       }
//     });
//   }
// }
