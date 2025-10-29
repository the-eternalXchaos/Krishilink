import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';

/// Wrap any top-level page (home/root) with this to enable double-back-to-exit.
/// First back within the page shows a hint; second back within [interval]
/// exits the app (Android). On iOS, it just ignores the exit behavior (no-op).
class DoubleBackExit extends StatefulWidget {
  const DoubleBackExit({super.key, required this.child, this.interval});

  final Widget child;
  final Duration? interval;

  @override
  State<DoubleBackExit> createState() => _DoubleBackExitState();
}

class _DoubleBackExitState extends State<DoubleBackExit> {
  DateTime? _lastBackPress;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true, // allow normal pops in nested navigators if any
      onPopInvoked: (didPop) async {
        if (didPop) return; // a nested route handled the pop

        // Only apply the double-back exit behavior on Android at root level
        if (!Platform.isAndroid) return; // don't exit on iOS

        final now = DateTime.now();
        final interval = widget.interval ?? const Duration(seconds: 2);
        if (_lastBackPress == null ||
            now.difference(_lastBackPress!) > interval) {
          _lastBackPress = now;
          PopupService.showSnackbar(
            title: 'exit'.tr,
            message: 'press_back_again_to_exit'.tr,
          );
          return; // swallow first back
        }

        // Second back within interval: actually exit app
        Get.back(); // Let Navigator handle final pop if possible
        await Future.delayed(const Duration(milliseconds: 100));
        // If still at root, request system exit
        // ignore: use_build_context_synchronously
        Future.microtask(() => Get.close(0));
      },
      child: widget.child,
    );
  }
}
