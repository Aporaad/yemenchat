// =============================================================================
// YemenChat - Storage Service
// =============================================================================
// Handles Firebase Storage operations for image uploads.
// =============================================================================

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

/// Service class for handling Firebase Storage operations
class StorageService {
  // Firebase Storage instance
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Image picker instance
  final ImagePicker _picker = ImagePicker();

  // UUID generator
  final Uuid _uuid = const Uuid();

  // ===========================================================================
  // IMAGE PICKING
  // ===========================================================================

  /// Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Take photo with camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      print('Error taking photo: $e');
      return null;
    }
  }

  // ===========================================================================
  // PROFILE PHOTO OPERATIONS
  // ===========================================================================

  /// Upload profile photo and return download URL
  Future<String?> uploadProfilePhoto(String userId, File imageFile) async {
    try {
      // Create unique filename
      final fileName = 'profile_$userId.jpg';
      final ref = _storage.ref().child('profile_photos/$fileName');

      // Upload file
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile photo: $e');
      return null;
    }
  }

  /// Delete profile photo
  Future<bool> deleteProfilePhoto(String userId) async {
    try {
      final fileName = 'profile_$userId.jpg';
      final ref = _storage.ref().child('profile_photos/$fileName');
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting profile photo: $e');
      return false;
    }
  }

  // ===========================================================================
  // CHAT IMAGE OPERATIONS
  // ===========================================================================

  /// Upload chat image and return download URL
  Future<String?> uploadChatImage(String chatId, File imageFile) async {
    try {
      // Create unique filename with timestamp and UUID
      final fileName = '${_uuid.v4()}.jpg';
      final ref = _storage.ref().child('chat_images/$chatId/$fileName');

      // Upload file
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading chat image: $e');
      return null;
    }
  }

  /// Delete chat image by URL
  Future<bool> deleteChatImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting chat image: $e');
      return false;
    }
  }

  // ===========================================================================
  // UPLOAD PROGRESS TRACKING
  // ===========================================================================

  /// Upload image with progress callback
  Future<String?> uploadImageWithProgress(
    String path,
    File imageFile,
    void Function(double progress)? onProgress,
  ) async {
    try {
      final fileName = '${_uuid.v4()}.jpg';
      final ref = _storage.ref().child('$path/$fileName');

      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Listen to upload progress
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // ===========================================================================
  // UTILITY METHODS
  // ===========================================================================

  /// Get file size in MB
  double getFileSizeInMb(File file) {
    final bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }

  /// Check if file size is within limit (default 5 MB)
  bool isFileSizeValid(File file, {double maxSizeMb = 5.0}) {
    return getFileSizeInMb(file) <= maxSizeMb;
  }
}
