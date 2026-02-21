// =============================================================================
// YemenChat - Screen Protection Mixin
// =============================================================================
// Mixin to prevent screenshots and screen recording on specific screens.
// Add this mixin to any screen State that needs protection.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:screen_protector/screen_protector.dart';

/// Mixin that enables screenshot/screen recording protection.
///
/// Usage:
/// ```dart
/// class _MyScreenState extends State<MyScreen> with ScreenProtectionMixin {
///   @override
///   void initState() {
///     super.initState();
///     enableProtection();
///   }
///
///   @override
///   void dispose() {
///     disableProtection();
///     super.dispose();
///   }
/// }
/// ```
mixin ScreenProtectionMixin<T extends StatefulWidget> on State<T> {
  /// Enable screenshot and screen recording protection
  Future<void> enableProtection() async {
    try {
      await ScreenProtector.preventScreenshotOn();
    } catch (e) {
      debugPrint('Screen protection enable error: $e');
    }
  }

  /// Disable screenshot and screen recording protection
  Future<void> disableProtection() async {
    try {
      await ScreenProtector.preventScreenshotOff();
    } catch (e) {
      debugPrint('Screen protection disable error: $e');
    }
  }
}
