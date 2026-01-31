// =============================================================================
// YemenChat - Profile Controller
// =============================================================================
// State management for user profile operations.
// =============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/security_log_model.dart';
import '../services/auth_service.dart';
import '../services/image_upload_service.dart';
import '../services/storage_service.dart'; // For image picking only

/// Controller for managing profile state
class ProfileController extends ChangeNotifier {
  // Services
  final AuthService _authService = AuthService();
  final ImageUploadService _imageUploadService = ImageUploadService();
  final StorageService _storageService =
      StorageService(); // For image picking only

  // State
  UserModel? _user;
  List<SecurityLogModel> _securityLogs = [];
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  String? _errorMessage;

  // ===========================================================================
  // GETTERS
  // ===========================================================================

  /// Current user profile
  UserModel? get user => _user;

  /// Security logs
  List<SecurityLogModel> get securityLogs => _securityLogs;

  /// Check if loading
  bool get isLoading => _isLoading;

  /// Check if uploading photo
  bool get isUploadingPhoto => _isUploadingPhoto;

  /// Get error message
  String? get errorMessage => _errorMessage;

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================

  /// Load user profile
  Future<void> loadProfile(String userId) async {
    _setLoading(true);

    try {
      _user = await _authService.getUserProfile(userId);
      _setLoading(false);
    } catch (e) {
      _errorMessage = 'Failed to load profile: $e';
      _setLoading(false);
    }
  }

  /// Refresh profile
  Future<void> refreshProfile() async {
    if (_user == null) return;
    await loadProfile(_user!.id);
  }

  // ===========================================================================
  // PROFILE UPDATE
  // ===========================================================================

  /// Update profile info
  Future<bool> updateProfile({String? fullName, String? phone}) async {
    if (_user == null) return false;

    _setLoading(true);

    try {
      final updatedUser = _user!.copyWith(
        fullName: fullName ?? _user!.fullName,
        phone: phone ?? _user!.phone,
      );

      await _authService.updateUserProfile(updatedUser);
      _user = updatedUser;

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      _setLoading(false);
      return false;
    }
  }

  /// Update profile photo from gallery
  Future<bool> updatePhotoFromGallery() async {
    final file = await _storageService.pickImageFromGallery();
    if (file == null) return false;
    return _uploadPhoto(file);
  }

  /// Update profile photo from camera
  Future<bool> updatePhotoFromCamera() async {
    final file = await _storageService.pickImageFromCamera();
    if (file == null) return false;
    return _uploadPhoto(file);
  }

  /// Upload photo file
  Future<bool> _uploadPhoto(File imageFile) async {
    if (_user == null) return false;

    _isUploadingPhoto = true;
    notifyListeners();

    try {
      // Validate image file
      _imageUploadService.validateImageFile(imageFile);

      // Check file size
      final fileSize = await imageFile.length();
      const maxSize = 5 * 1024 * 1024; // 5MB

      if (fileSize > maxSize) {
        throw Exception('Image size must be less than 5 MB');
      }

      // Upload to Cloudinary
      final photoUrl = await _imageUploadService.uploadProfilePhoto(
        _user!.id,
        imageFile,
      );

      // Update user profile
      final updatedUser = _user!.copyWith(photoUrl: photoUrl);
      await _authService.updateUserProfile(updatedUser);
      _user = updatedUser;

      _isUploadingPhoto = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isUploadingPhoto = false;
      notifyListeners();
      return false;
    }
  }

  /// Remove profile photo
  Future<bool> removePhoto() async {
    if (_user == null) return false;

    _setLoading(true);

    try {
      // Note: Cloudinary images can be managed from dashboard
      // For now, just remove URL from user profile

      // Update user profile (set photoUrl to null)
      final updatedUser = _user!.copyWith(photoUrl: null);
      await _authService.updateUserProfile(updatedUser);
      _user = updatedUser;

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to remove photo: $e';
      _setLoading(false);
      return false;
    }
  }

  // ===========================================================================
  // PASSWORD
  // ===========================================================================

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
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

  // ===========================================================================
  // SECURITY LOGS
  // ===========================================================================

  /// Load security logs
  Future<void> loadSecurityLogs() async {
    _setLoading(true);

    try {
      _securityLogs = await _authService.getSecurityLogs();
      _setLoading(false);
    } catch (e) {
      _errorMessage = 'Failed to load security logs: $e';
      _setLoading(false);
    }
  }

  // ===========================================================================
  // ACCOUNT DELETION
  // ===========================================================================

  /// Delete account
  Future<bool> deleteAccount(String password) async {
    _setLoading(true);

    try {
      await _authService.deleteAccount(password);
      _user = null;
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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
