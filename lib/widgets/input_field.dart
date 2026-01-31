// =============================================================================
// YemenChat - Input Field Widget
// =============================================================================
// Reusable text input components with validation.
// =============================================================================

import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Custom text input field
class InputField extends StatefulWidget {
  /// Text controller
  final TextEditingController? controller;

  /// Field label
  final String label;

  /// Hint text
  final String? hint;

  /// Prefix icon
  final IconData? prefixIcon;

  /// Suffix widget
  final Widget? suffix;

  /// Whether this is a password field
  final bool isPassword;

  /// Keyboard type
  final TextInputType? keyboardType;

  /// Text input action
  final TextInputAction? textInputAction;

  /// Validator function
  final String? Function(String?)? validator;

  /// On changed callback
  final void Function(String)? onChanged;

  /// On submitted callback
  final void Function(String)? onSubmitted;

  /// Whether field is enabled
  final bool enabled;

  /// Max lines (defaults to 1)
  final int maxLines;

  /// Auto focus
  final bool autofocus;

  /// Focus node
  final FocusNode? focusNode;

  const InputField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffix,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.maxLines = 1,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword && _obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      enabled: widget.enabled,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon:
            widget.prefixIcon != null
                ? Icon(widget.prefixIcon, color: kPrimaryColor)
                : null,
        suffixIcon:
            widget.isPassword
                ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
                : widget.suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusMD),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusMD),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusMD),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusMD),
          borderSide: const BorderSide(color: kErrorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusMD),
          borderSide: const BorderSide(color: kErrorColor, width: 2),
        ),
        filled: true,
        fillColor: widget.enabled ? Colors.grey.shade50 : Colors.grey.shade200,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

/// Search input field
class SearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final void Function(String)? onChanged;
  final VoidCallback? onClear;
  final bool autofocus;

  const SearchField({
    super.key,
    this.controller,
    this.hint = 'Search...',
    this.onChanged,
    this.onClear,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(kRadiusFull),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        autofocus: autofocus,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
          suffixIcon:
              controller?.text.isNotEmpty == true
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controller?.clear();
                      onClear?.call();
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}

/// Chat message input field with image upload support
class MessageInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSend;
  final VoidCallback? onImagePick;
  final FocusNode? focusNode;
  final bool isSending;

  const MessageInputField({
    super.key,
    required this.controller,
    this.onSend,
    this.onImagePick,
    this.focusNode,
    this.isSending = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Image picker button
            if (onImagePick != null)
              IconButton(
                icon: const Icon(Icons.image),
                color: kPrimaryColor,
                onPressed: isSending ? null : onImagePick,
                tooltip: 'Send image',
              ),

            // Text input
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onSubmitted: (_) => onSend?.call(),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send button
            Container(
              decoration: const BoxDecoration(
                color: kPrimaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon:
                    isSending
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Icon(Icons.send),
                color: Colors.white,
                onPressed: isSending ? null : onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
