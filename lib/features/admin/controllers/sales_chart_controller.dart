// Controller for sales chart animations
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SalesChartController extends GetxController
    with GetSingleTickerProviderStateMixin {
  var isVisible = false.obs;
  late AnimationController _controller;
  late Animation<Offset> animation;

  @override
  void onInit() {
    super.onInit();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    animation = Tween<Offset>(
      begin: const Offset(-0.5, 0), 
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  void animate() {
    if (!isVisible.value) {
      isVisible.value = true;
      _controller.forward(from: 0);
    }
  }

  void reset() {
    if (isVisible.value) {
      isVisible.value = false;
      _controller.reset();
    }
  }

  @override
  void onClose() {
    _controller.dispose();
    super.onClose();
  }
}
