// =============================================================================
// YemenChat - Constants
// =============================================================================
// Central location for all app constants including colors, styles, and routes.
// =============================================================================

import 'package:flutter/material.dart';

// =============================================================================
// APP INFORMATION
// =============================================================================

/// Application name
const String kAppName = 'YemenChat';

/// Application version
const String kAppVersion = '1.0.0';

// =============================================================================
// CLOUDINARY CONFIGURATION
// =============================================================================
// cloud name
const String kCloudinaryCloudName = 'dpcmgnvyx';

/// Cloudinary unsigned upload preset
const String kCloudinaryUploadPreset = 'yemenchat_unsigned';

/// Cloudinary base URL
const String kCloudinaryBaseUrl = 'https://api.cloudinary.com/v1_1';

/// Cloudinary upload URL
const String kCloudinaryUploadUrl =
    '$kCloudinaryBaseUrl/$kCloudinaryCloudName/image/upload';

// =============================================================================
// COLORS - Modern Chat App Theme
// =============================================================================

/// Primary color - Deep teal for professional look
const Color kPrimaryColor = Color(0xFF00897B);

/// Primary color light variant
const Color kPrimaryLightColor = Color(0xFF4DB6AC);

/// Primary color dark variant
const Color kPrimaryDarkColor = Color(0xFF00695C);

/// Accent color - Warm amber for highlights
const Color kAccentColor = Color(0xFFFFB300);

/// Background color for light theme
const Color kBackgroundLight = Color(0xFFF5F5F5);

/// Background color for dark theme
const Color kBackgroundDark = Color(0xFF121212);

/// Surface color for cards in light theme
const Color kSurfaceLight = Colors.white;

/// Surface color for cards in dark theme
const Color kSurfaceDark = Color(0xFF1E1E1E);

/// Sent message bubble color
const Color kSentBubbleColor = Color(0xFFDCF8C6);

/// Received message bubble color
const Color kReceivedBubbleColor = Colors.white;

/// Error color
const Color kErrorColor = Color(0xFFE53935);

/// Success color
const Color kSuccessColor = Color(0xFF43A047);

/// Online status color
const Color kOnlineColor = Color(0xFF4CAF50);

/// Offline status color
const Color kOfflineColor = Color(0xFF9E9E9E);

// =============================================================================
// TEXT STYLES
// =============================================================================
/// Heading text style
const TextStyle kHeadingStyle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: Colors.black87,
);

/// Subheading text style
const TextStyle kSubheadingStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w600,
  color: Colors.black87,
);

/// Body text style
const TextStyle kBodyStyle = TextStyle(fontSize: 14, color: Colors.black87);

/// Caption text style
const TextStyle kCaptionStyle = TextStyle(fontSize: 12, color: Colors.black54);

/// Chat name style
const TextStyle kChatNameStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
);

/// Chat preview style
const TextStyle kChatPreviewStyle = TextStyle(
  fontSize: 14,
  color: Colors.black54,
);

/// Time text style
const TextStyle kTimeStyle = TextStyle(fontSize: 12, color: Colors.black45);

// =============================================================================
// SPACING
// =============================================================================
/// Extra small spacing
const double kSpaceXS = 4.0;

/// Small spacing
const double kSpaceSM = 8.0;

/// Medium spacing
const double kSpaceMD = 16.0;

/// Large spacing
const double kSpaceLG = 24.0;

/// Extra large spacing
const double kSpaceXL = 32.0;

/// Default padding
const EdgeInsets kDefaultPadding = EdgeInsets.all(26.0);

/// Horizontal padding
const EdgeInsets kHorizontalPadding = EdgeInsets.symmetric(horizontal: 16.0);

/// Vertical padding
const EdgeInsets kVerticalPadding = EdgeInsets.symmetric(vertical: 16.0);

// =============================================================================
// BORDER RADIUS
// =============================================================================

/// Small border radius
const double kRadiusSM = 8.0;

/// Medium border radius
const double kRadiusMD = 15.0;

/// Large border radius
const double kRadiusLG = 16.0;

/// Extra large border radius (for cards/containers)
const double kRadiusXL = 24.0;

/// Full round border radius
const double kRadiusFull = 100.0;

// =============================================================================
// FIREBASE COLLECTION NAMES
// =============================================================================
/// Users collection
const String kUsersCollection = 'users';

/// Chats collection
const String kChatsCollection = 'chats';

/// Messages subcollection
const String kMessagesCollection = 'messages';

/// Favorites collection
const String kFavoritesCollection = 'favorites';

/// Blocked users collection
const String kBlockedUsersCollection = 'blocked_users';

/// Security logs collection
const String kSecurityLogsCollection = 'security_logs';

// =============================================================================
// ROUTE NAMES
// =============================================================================
/// Splash route
const String kRouteSplash = '/';

/// Welcome route
const String kRouteWelcome = '/welcome';

/// Sign in route
const String kRouteSignIn = '/signin';

/// Sign up route
const String kRouteSignUp = '/signup';

/// Home route
const String kRouteHome = '/home';

/// Chat route
const String kRouteChat = '/chat';

/// Contacts route
const String kRouteContacts = '/contacts';

/// Contact info route
const String kRouteContactInfo = '/contact-info';

/// Favorites route
const String kRouteFavorites = '/favorites';

/// Profile route
const String kRouteProfile = '/profile';

/// Settings route
const String kRouteSettings = '/settings';

// =============================================================================
// INPUT DECORATION
// =============================================================================
/// Default input decoration for text fields
InputDecoration kInputDecoration({
  //###########
  required String label,
  String? hint,
  IconData? prefixIcon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
    suffixIcon: suffixIcon,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadiusMD)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kRadiusMD),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kRadiusMD),
      borderSide: const BorderSide(color: kPrimaryColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kRadiusMD),
      borderSide: const BorderSide(color: kErrorColor),
    ),
    filled: true,
    fillColor: Colors.grey.shade50,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}

// =============================================================================
// ANIMATION DURATIONS
// =============================================================================
/// Fast animation duration
const Duration kAnimationFast = Duration(milliseconds: 200);

/// Normal animation duration
const Duration kAnimationNormal = Duration(milliseconds: 300);

/// Slow animation duration
const Duration kAnimationSlow = Duration(milliseconds: 500);

/// Splash screen display duration
const Duration kSplashDuration = Duration(seconds: 2);
