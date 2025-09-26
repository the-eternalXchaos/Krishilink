// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class ComponentAnimationController extends GetxController
//     with GetSingleTickerProviderStateMixin {
//   var isVisible = false.obs;
//   late AnimationController _controller;
//   late Animation<double> animation;
//   // final Offset beginOffset;
//   bool _isDisposed = false;

//   // ComponentAnimationController({
//   //   this.beginOffset = const Offset(-0.5, 0),
//   // }); // Default: slide from left
//   ComponentAnimationController();

//   @override
//   void onInit() {
//     super.onInit();
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
//     animation = Tween<double>(
//       begin: 0.5,
//       end: 1.0,
//     ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
//   }

//   void animate() {
//     if (_isDisposed || !isVisible.value) {
//       isVisible.value = true;
//       _controller.forward(from: 0);
//     }
//   }

//   void reset() {
//     if (_isDisposed || isVisible.value) {
//       isVisible.value = false;
//       _controller.reset();
//     }
//   }

//   @override
//   void onClose() {
//     _controller.dispose();
//     super.onClose();
//   }
// }
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ComponentAnimationController extends GetxController
    with GetSingleTickerProviderStateMixin {
  var isVisible = false.obs;
  late AnimationController _controller;
  late Animation<double> animation;
  bool _isDisposed = false;

  ComponentAnimationController();

  @override
  void onInit() {
    super.onInit();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    animation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
  }

  void animate() {
    if (_isDisposed || isVisible.value) return;
    isVisible.value = true;
    _controller.forward(from: 0);
  }

  void reset() {
    if (_isDisposed || !isVisible.value) return;
    isVisible.value = false;
    _controller.reset();
  }

  @override
  void onClose() {
    _isDisposed = true; // Set flag first
    _controller.dispose();
    super.onClose();
  }
}
