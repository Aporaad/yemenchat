// =============================================================================
// YemenChat - Settings Controller
// =============================================================================
// State management for app settings (theme, notifications, etc).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

/// Controller for managing app settings
class SettingsController extends ChangeNotifier {
  // Services
  final NotificationService _notificationService = NotificationService();

  // SharedPreferences keys
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keySessionDuration = 'session_duration';
  static const String _keyChatWallpaper = 'chat_wallpaper';

  // State
  ThemeMode _themeMode = ThemeMode.system;
  bool _notificationsEnabled = true;
  int _sessionDurationMinutes = 30; // Default 30 minutes
  String? _chatWallpaper;
  bool _isLoading = false;

  // ===========================================================================
  // GETTERS
  // ===========================================================================

  /// Current theme mode
  ThemeMode get themeMode => _themeMode;

  /// Check if dark mode
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Check if notifications enabled
  bool get notificationsEnabled => _notificationsEnabled;

  /// Session duration in minutes
  int get sessionDurationMinutes => _sessionDurationMinutes;

  /// Chat wallpaper path
  String? get chatWallpaper => _chatWallpaper;

  /// Check if loading
  bool get isLoading => _isLoading;

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================

  /// Load settings from SharedPreferences
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load theme mode
      final themeModeIndex = prefs.getInt(_keyThemeMode) ?? 0;
      _themeMode = ThemeMode.values[themeModeIndex];

      // Load notifications setting
      _notificationsEnabled = prefs.getBool(_keyNotificationsEnabled) ?? true;

      // Load session duration
      _sessionDurationMinutes = prefs.getInt(_keySessionDuration) ?? 30;

      // Load chat wallpaper
      _chatWallpaper = prefs.getString(_keyChatWallpaper);
    } catch (e) {
      // Use default values on error
      debugPrint('Failed to load settings: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ===========================================================================
  // THEME SETTINGS
  // ===========================================================================

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode.index);
  }

  /// Toggle between light and dark mode
  Future<void> toggleDarkMode() async {
    final newMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  /// Set to system theme
  Future<void> useSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }

  // ===========================================================================
  // NOTIFICATION SETTINGS
  // ===========================================================================

  /// Enable/disable notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();

    // Update system notifications
    await _notificationService.setNotificationsEnabled(enabled);

    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);
  }

  /// Toggle notifications
  Future<void> toggleNotifications() async {
    await setNotificationsEnabled(!_notificationsEnabled);
  }

  // ===========================================================================
  // SESSION SETTINGS
  // ===========================================================================

  /// Set session duration in minutes
  Future<void> setSessionDuration(int minutes) async {
    _sessionDurationMinutes = minutes;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySessionDuration, minutes);
  }

  /// Get available session duration options
  List<int> get sessionDurationOptions => [5, 15, 30, 60, 120, 480];

  /// Get session duration display text
  String getSessionDurationText(int minutes) {
    if (minutes < 60) {
      return '$minutes minutes';
    } else {
      final hours = minutes ~/ 60;
      return '$hours ${hours == 1 ? 'hour' : 'hours'}';
    }
  }

  // ===========================================================================
  // CHAT WALLPAPER
  // ===========================================================================

  /// Set chat wallpaper
  Future<void> setChatWallpaper(String? path) async {
    _chatWallpaper = path;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString(_keyChatWallpaper, path);
    } else {
      await prefs.remove(_keyChatWallpaper);
    }
  }

  /// Remove chat wallpaper
  Future<void> removeChatWallpaper() async {
    await setChatWallpaper(null);
  }

  // ===========================================================================
  // RESET SETTINGS
  // ===========================================================================

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_keyThemeMode);
    await prefs.remove(_keyNotificationsEnabled);
    await prefs.remove(_keySessionDuration);
    await prefs.remove(_keyChatWallpaper);

    _themeMode = ThemeMode.system;
    _notificationsEnabled = true;
    _sessionDurationMinutes = 30;
    _chatWallpaper = null;

    notifyListeners();
  }
}
