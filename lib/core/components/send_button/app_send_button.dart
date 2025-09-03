import 'package:flutter/material.dart';

/// Reusable send button:
/// - shows spinner when [isLoading] is true
/// - enables only if [hasText] is true
/// - [inline] = true makes it fit nicely in TextField.suffixIcon
class AppSendButton extends StatelessWidget {
  final bool isLoading;
  final bool hasText;
  final VoidCallback onSend;

  final bool inline; // use true when placed inside a TextField
  final double iconSize; // adjust if needed

  const AppSendButton({
    super.key,
    required this.isLoading,
    required this.hasText,
    required this.onSend,
    this.inline = true,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (isLoading) {
      return Container(
        margin: inline ? EdgeInsets.zero : const EdgeInsets.only(bottom: 4),
        padding: EdgeInsets.all(inline ? 8 : 12),
        decoration: BoxDecoration(
          color: cs.outlineVariant,
          shape: BoxShape.circle,
        ),
        child: SizedBox(
          width: inline ? 18 : 20,
          height: inline ? 18 : 20,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final bg = hasText ? cs.primary : cs.surfaceContainerHigh;
    final fg = hasText ? cs.onPrimary : cs.onSurface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: inline ? EdgeInsets.zero : const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow:
            hasText
                ? [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                : [],
      ),
      child: IconButton(
        icon: Icon(Icons.send_rounded, color: fg, size: iconSize),
        onPressed: hasText && !isLoading ? onSend : null,
        tooltip: 'Send message',
        padding: EdgeInsets.all(inline ? 6 : 8),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );
  }
}
