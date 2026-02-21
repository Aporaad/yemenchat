// =============================================================================
// YemenChat - Security Service
// =============================================================================
// Handles security checks: Root/Jailbreak, Debug Mode, Emulator detection.
// =============================================================================

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:jailbreak_root_detection/jailbreak_root_detection.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Result of security checks
class SecurityCheckResult {
  final bool isSafe;
  final String? violationType;

  const SecurityCheckResult({required this.isSafe, this.violationType});

  /// Safe result (no violations)
  static const safe = SecurityCheckResult(isSafe: true);
}

/// Service for running security checks at app startup
class SecurityService {
  /// Run all security checks
  ///
  /// Returns [SecurityCheckResult] indicating if the app is safe to run.
  /// In debug mode, checks are skipped to allow development.
  static Future<SecurityCheckResult> runSecurityChecks() async {
    // Skip all checks in debug mode to allow development/testing
    if (kDebugMode) {
      return SecurityCheckResult.safe;
    }

    // Skip on web — security checks are mobile-only
    if (kIsWeb) {
      return SecurityCheckResult.safe;
    }

    // ① Check for Root / Jailbreak
    try {
      final bool isJailBroken =
          await JailbreakRootDetection.instance.isJailBroken;
      if (isJailBroken) {
        return const SecurityCheckResult(
          isSafe: false,
          violationType: 'Root/Jailbreak Detected',
        );
      }
    } catch (e) {
      // If detection fails, continue with other checks
      debugPrint('Jailbreak detection error: $e');
    }

    // ② Check for Emulator
    try {
      final bool isEmulator = await _isEmulator();
      if (isEmulator) {
        return const SecurityCheckResult(
          isSafe: false,
          violationType: 'Emulator Detected',
        );
      }
    } catch (e) {
      debugPrint('Emulator detection error: $e');
    }

    // All checks passed
    return SecurityCheckResult.safe;
  }

  /// Check if running on an emulator
  static Future<bool> _isEmulator() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      return !info.isPhysicalDevice;
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      return !info.isPhysicalDevice;
    }

    return false;
  }
}
