import 'package:flutter/material.dart';

class AuthButton extends StatelessWidget {
  final String baseText; // e.g., "Register"
  final String? inputMethod; // "email" or "phone"
  final VoidCallback onPressed;
  final bool isLoading;

  const AuthButton({
    super.key,
    required this.baseText,
    this.inputMethod,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine button text based on inputMethod
    String displayText = baseText;
    if (inputMethod != null) {
      displayText = '$baseText with ${inputMethod == 'email' ? 'Email' : 'Phone'}';
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                displayText,
                style: const TextStyle(fontSize: 16),
              ),
      ),
    );
  }
}