// =============================================================================
// YemenChat - Custom Button Widget
// =============================================================================
// Reusable button components with various styles.
// =============================================================================

import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Primary action button
class CustomButton extends StatelessWidget {
  /// Button text
  final String text;

  /// Button click callback
  final VoidCallback? onPressed;

  /// Whether button is in loading state
  final bool isLoading;

  /// Button width (defaults to full width)
  final double? width;

  /// Button height
  final double height;

  /// Button icon (optional)
  final IconData? icon;

  /// Background color
  final Color? backgroundColor;

  /// Text color
  final Color? textColor;

  /// Whether this is an outlined button
  final bool isOutlined;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 52,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? kPrimaryColor;
    final txtColor = textColor ?? Colors.white;

    if (isOutlined) {
      return SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: bgColor, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kRadiusMD),
            ),
          ),
          child: _buildChild(bgColor),
        ),
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: txtColor,
          disabledBackgroundColor: bgColor.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusMD),
          ),
          elevation: 2,
        ),
        child: _buildChild(txtColor),
      ),
    );
  }

  Widget _buildChild(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            isOutlined ? kPrimaryColor : Colors.white,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isOutlined ? color : null,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isOutlined ? color : null,
      ),
    );
  }
}

/// Secondary/text button
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: color ?? kPrimaryColor),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: TextStyle(
              color: color ?? kPrimaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon button with tooltip
class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;
  final Color? backgroundColor;

  const CustomIconButton({
    super.key,
    required this.icon,
    this.tooltip,
    this.onPressed,
    this.color,
    this.size = 24,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      icon: Icon(icon),
      iconSize: size,
      color: color,
      onPressed: onPressed,
      style:
          backgroundColor != null
              ? IconButton.styleFrom(backgroundColor: backgroundColor)
              : null,
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}

/// Floating action button
class CustomFAB extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool isExtended;
  final String? label;

  const CustomFAB({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.isExtended = false,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (isExtended && label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label!),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        tooltip: tooltip,
      );
    }

    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      tooltip: tooltip,
      child: Icon(icon),
    );
  }
}
