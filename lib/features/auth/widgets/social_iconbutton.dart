import 'package:flutter/material.dart';

class SocialIconButton extends StatelessWidget {
  final String iconPath;
  final VoidCallback onTap;
  final double size;
  final Color?
  borderColor; // Kept for flexibility, but won't be used for black border

  const SocialIconButton({
    super.key,
    required this.iconPath,
    required this.onTap,
    this.size = 60.0,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10, // Set elevation to 10
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white, // Background color
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: Image.asset(
            iconPath,
            fit: BoxFit.contain,
            width: size * 0.6,
            height: size * 0.6,
          ),
        ),
      ),
    );
  }
}
