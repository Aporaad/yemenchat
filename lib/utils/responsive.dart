// =============================================================================
// YemenChat - Responsive Utilities
// =============================================================================
// Helper class for responsive design across different screen sizes.
// =============================================================================

import 'package:flutter/material.dart';

/// Screen size breakpoints following Material Design guidelines
class ScreenBreakpoints {
  static const double mobileSmall = 360.0;
  static const double mobile = 480.0;
  static const double tablet = 600.0;
  static const double desktop = 1024.0;
}

/// Device type based on screen width
enum DeviceType { mobileSmall, mobile, tablet, desktop }

/// Responsive helper for adaptive layouts
class ResponsiveHelper {
  final BuildContext context;
  late final Size _screenSize;
  late final DeviceType _deviceType;

  ResponsiveHelper(this.context) {
    _screenSize = MediaQuery.of(context).size;
    _deviceType = _getDeviceType();
  }

  /// Get screen width
  double get width => _screenSize.width;

  /// Get screen height
  double get height => _screenSize.height;

  /// Get device type
  DeviceType get deviceType => _deviceType;

  /// Check if mobile small screen
  bool get isMobileSmall => width < ScreenBreakpoints.mobileSmall;

  /// Check if mobile screen
  bool get isMobile => width < ScreenBreakpoints.tablet;

  /// Check if tablet screen
  bool get isTablet =>
      width >= ScreenBreakpoints.tablet && width < ScreenBreakpoints.desktop;

  /// Check if desktop screen
  bool get isDesktop => width >= ScreenBreakpoints.desktop;

  /// Determine device type
  DeviceType _getDeviceType() {
    if (width < ScreenBreakpoints.mobileSmall) return DeviceType.mobileSmall;
    if (width < ScreenBreakpoints.tablet) return DeviceType.mobile;
    if (width < ScreenBreakpoints.desktop) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// Get responsive value based on device type
  T valueByDevice<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? mobileSmall,
  }) {
    switch (_deviceType) {
      case DeviceType.mobileSmall:
        return mobileSmall ?? mobile;
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// Get responsive padding
  EdgeInsets get pagePadding => EdgeInsets.symmetric(
    horizontal: valueByDevice(
      mobileSmall: 12.0,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    ),
    vertical: 16.0,
  );

  /// Get responsive card margin
  EdgeInsets get cardMargin => EdgeInsets.symmetric(
    horizontal: valueByDevice(mobileSmall: 8.0, mobile: 12.0, tablet: 16.0),
    vertical: 8.0,
  );

  /// Get responsive font size multiplier
  double get fontScale =>
      valueByDevice(mobileSmall: 0.9, mobile: 1.0, tablet: 1.1, desktop: 1.2);

  /// Scale font size responsively
  double fontSize(double baseSize) => baseSize * fontScale;

  /// Get responsive icon size
  double get iconSize =>
      valueByDevice(mobileSmall: 20.0, mobile: 24.0, tablet: 28.0);

  /// Get responsive avatar size
  double get avatarSize =>
      valueByDevice(mobileSmall: 40.0, mobile: 48.0, tablet: 56.0);

  /// Get responsive list tile height
  double get listTileHeight =>
      valueByDevice(mobileSmall: 64.0, mobile: 72.0, tablet: 80.0);

  /// Get max content width for large screens
  double get maxContentWidth =>
      valueByDevice(mobile: double.infinity, tablet: 800.0, desktop: 1200.0);

  /// Center content on large screens
  Widget centerContent(Widget child) {
    if (isMobile) return child;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: child,
      ),
    );
  }
}

/// Extension for easy access to ResponsiveHelper
extension ResponsiveContext on BuildContext {
  ResponsiveHelper get responsive => ResponsiveHelper(this);
}
