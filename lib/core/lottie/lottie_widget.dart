import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieWidget extends StatelessWidget {
  final String path;
  final double height;
  final bool repeat;
  final bool reverse;

  const LottieWidget({
    super.key,
    required this.path,
    this.height = 100,
    this.repeat = true,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      path,
      height: height,
      repeat: repeat,
      reverse: reverse,
      fit: BoxFit.contain,
      // fit: BoxFit.cover,
    );
  }
}
