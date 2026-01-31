// =============================================================================
// YemenChat - Auth Controller
// =============================================================================
// State management for authentication using ChangeNotifier.
// =============================================================================

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

/// Controller for managing authentication state
class AuthController extends ChangeNotifier {
  // Services
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  // State
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  // ===========================================================================
  // GETTERS
  // ===========================================================================

  /// Current logged in user
  UserModel? get currentUser => _currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  /// Check if authentication is loading
  bool get isLoading => _isLoading;

  /// Get error message (if any)
  String? get errorMessage => _errorMessage;

  /// Check if auth state has been initialized
  bool get isInitialized => _isInitialized;

  /// Get current user ID
  String? get currentUserId => _currentUser?.id;

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================

  /// Initialize auth controller and check login state
  Future<void> initialize() async {
    _setLoading(true);

    try {
      // Check if user is already logged in
      if (_authService.isLoggedIn) {
        _currentUser = await _authService.getCurrentUserProfile();

        // Update FCM token
        if (_currentUser != null) {
          final token = await _notificationService.getToken();
          if (token != null) {
            await _authService.updateFcmToken(token);
          }
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to initialize: $e';
    } finally {
      _isInitialized = true;
      _setLoading(false);
    }
  }

  // ===========================================================================
  // SIGN UP
  // ===========================================================================

  /// Sign up a new user
  Future<bool> signUp({
    required String fullName,
    required String username,
    required String phone,
    required String email,
    required String password,
  }) async {
    _clearError();
    _setLoading(true);

    try {
      // Check for duplicate email
      if (await _authService.isEmailTaken(email)) {
        throw Exception('This email is already registered');
      }

      // Check for duplicate username
      if (await _authService.isUsernameTaken(username)) {
        throw Exception('This username is already taken');
      }

      // Create account
      _currentUser = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        username: username,
        phone: phone,
      );

      // Update FCM token
      final token = await _notificationService.getToken();
      if (token != null && _currentUser != null) {
        await _authService.updateFcmToken(token);
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  // ===========================================================================
  // SIGN IN
  // ===========================================================================

  /// Sign in with email or username
  Future<bool> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    _clearError();
    _setLoading(true);

    try {
      // Check if input is email or username
      if (emailOrUsername.contains('@')) {
        // Sign in with email
        _currentUser = await _authService.signInWithEmail(
          email: emailOrUsername,
          password: password,
        );
      } else {
        // Sign in with username
        _currentUser = await _authService.signInWithUsername(
          username: emailOrUsername,
          password: password,
        );
      }

      // Update FCM token
      final token = await _notificationService.getToken();
      if (token != null && _currentUser != null) {
        await _authService.updateFcmToken(token);
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  // ===========================================================================
  // SIGN OUT
  // ===========================================================================

  /// Sign out current user
  Future<void> signOut() async {
    _setLoading(true);

    try {
      await _authService.signOut();
      _currentUser = null;
    } catch (e) {
      _errorMessage = 'Failed to sign out: $e';
    } finally {
      _setLoading(false);
    }
  }

  // ===========================================================================
  // PASSWORD MANAGEMENT
  // ===========================================================================

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _clearError();
    _setLoading(true);

    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordReset(String email) async {
    _clearError();
    _setLoading(true);

    try {
      await _authService.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to send reset email: $e';
      _setLoading(false);
      return false;
    }
  }

  // ===========================================================================
  // PROFILE UPDATE
  // ===========================================================================

  /// Update user profile
  Future<bool> updateProfile(UserModel updatedUser) async {
    _clearError();
    _setLoading(true);

    try {
      await _authService.updateUserProfile(updatedUser);
      _currentUser = updatedUser;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      _setLoading(false);
      return false;
    }
  }

  /// Update profile photo URL
  Future<bool> updateProfilePhoto(String photoUrl) async {
    if (_currentUser == null) return false;

    final updatedUser = _currentUser!.copyWith(photoUrl: photoUrl);
    return updateProfile(updatedUser);
  }

  // ===========================================================================
  // ACCOUNT DELETION
  // ===========================================================================

  /// Delete user account
  Future<bool> deleteAccount(String password) async {
    _clearError();
    _setLoading(true);

    try {
      await _authService.deleteAccount(password);
      _currentUser = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  // ===========================================================================
  // HELPER METHODS
  // ===========================================================================

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
  }

  /// Clear error manually
  void clearError() {
    _clearError();
    notifyListeners();
  }
}
