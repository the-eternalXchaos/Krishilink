import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextInputField extends StatefulWidget {
  // Core
  final TextEditingController? controller;
  final FocusNode? focusNode;

  // Text/config
  final String? label;
  final String? hint;
  final String? helperText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final bool enableSuggestions;
  final bool autocorrect;
  final int? minLines;
  final int? maxLines; // set null for expanding multiline
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  // State
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onTap;

  // Decoration / layout
  final IconData? icon; // prefix icon convenience
  final Widget? prefix;
  final Widget? suffix;
  final Widget? suffixIcon;
  final EdgeInsetsGeometry? contentPadding;
  final double borderRadius;
  final Color? fillColor;
  final bool dense;

  // Extras (opt-in)
  final bool showClearButton;
  final bool showSendButton;
  final VoidCallback? onSend;
  final bool showObscureToggle;

  const AppTextInputField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helperText,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.sentences,
    this.obscureText = false,
    this.enableSuggestions = true,
    this.autocorrect = true,
    this.minLines = 1,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.icon,
    this.prefix,
    this.suffix,
    this.suffixIcon,
    this.contentPadding,
    this.borderRadius = 30,
    this.fillColor,
    this.dense = true,
    this.showClearButton = false,
    this.showSendButton = false,
    this.onSend,
    this.showObscureToggle = false,
  });

  @override
  State<AppTextInputField> createState() => _AppTextInputFieldState();
}

class _AppTextInputFieldState extends State<AppTextInputField> {
  late final TextEditingController _internalController;
  late bool _ownsController;
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
    _ownsController = widget.controller == null;
    _internalController = widget.controller ?? TextEditingController();

    // Rebuild to show/hide clear/send when text changes
    _internalController.addListener(_onTextChange);
  }

  void _onTextChange() {
    if (widget.showClearButton || widget.showSendButton) {
      // Cheap rebuild; lightweight for a single field
      setState(() {});
    }
    widget.onChanged?.call(_internalController.text);
  }

  @override
  void dispose() {
    _internalController.removeListener(_onTextChange);
    if (_ownsController) _internalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final isEmpty = _internalController.text.isEmpty;
    final canSend = widget.showSendButton && !isEmpty && widget.onSend != null;
    final canClear =
        widget.showClearButton &&
        !isEmpty &&
        widget.enabled &&
        !widget.readOnly;

    // Compose suffix actions (clear / send / custom suffixIcon)
    final List<Widget> trailing = [
      if (widget.showObscureToggle && widget.obscureText)
        IconButton(
          tooltip: _obscure ? 'Show' : 'Hide',
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      if (canClear)
        IconButton(
          tooltip: 'Clear',
          icon: const Icon(Icons.close),
          onPressed: () {
            _internalController.clear();
            // onChanged gets triggered by listener
          },
        ),
      if (canSend)
        IconButton(
          tooltip: 'Send',
          icon: const Icon(Icons.send_rounded),
          onPressed: widget.onSend,
        ),
      if (widget.suffixIcon != null) widget.suffixIcon!,
    ];

    // NOTE: suffixIcon has tight constraints by default; widen it a bit for multiple buttons
    final suffixIconConstraints =
        trailing.isEmpty
            ? const BoxConstraints()
            : const BoxConstraints(minHeight: 48, minWidth: 48, maxWidth: 132);

    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.6)),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      borderSide: BorderSide(color: cs.primary, width: 2),
    );

    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      borderSide: BorderSide(color: cs.error),
    );

    return TextFormField(
      controller: _internalController,
      focusNode: widget.focusNode,
      obscureText: _obscure,
      enableSuggestions: widget.enableSuggestions,
      autocorrect: widget.autocorrect,
      textCapitalization: widget.textCapitalization,
      keyboardType:
          widget.keyboardType ??
          (widget.maxLines == null || (widget.maxLines ?? 1) > 1
              ? TextInputType.multiline
              : TextInputType.text),
      textInputAction:
          widget.textInputAction ??
          ((widget.maxLines == null || (widget.maxLines ?? 1) > 1)
              ? TextInputAction.newline
              : TextInputAction.send),
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      inputFormatters: widget.inputFormatters,
      validator: widget.validator,
      onFieldSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      decoration: InputDecoration(
        isDense: widget.dense,
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helperText,
        counterText:
            widget.maxLength != null
                ? null
                : '', // hide default counter if not using maxLength
        prefixIcon: widget.icon != null ? Icon(widget.icon) : null,
        prefix: widget.prefix,
        suffix:
            widget
                .suffix, // placed inside the field but after input; ok for small labels
        suffixIcon:
            trailing.isNotEmpty
                ? Row(mainAxisSize: MainAxisSize.min, children: trailing)
                : null,
        suffixIconConstraints: suffixIconConstraints,
        filled: true,
        fillColor: widget.fillColor ?? cs.surfaceContainerHighest,
        contentPadding:
            widget.contentPadding ??
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: baseBorder,
        enabledBorder: baseBorder,
        focusedBorder: focusedBorder,
        errorBorder: errorBorder,
        focusedErrorBorder: errorBorder.copyWith(
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
      ),
    );
  }
}
