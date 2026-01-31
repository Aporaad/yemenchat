// =============================================================================
// YemenChat - Image Upload Service (Cloudinary)
// =============================================================================
// Professional service for uploading images to Cloudinary using unsigned upload.
// No API secrets required - safe for mobile apps.
// =============================================================================

import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';

/// Service for uploading images to Cloudinary
class ImageUploadService {
  /// Upload image to Cloudinary
  ///
  /// [imageFile] - The image file to upload
  /// [folder] - Optional folder name in Cloudinary (e.g., 'profiles', 'chats')
  ///
  /// Returns the secure HTTPS URL of the uploaded image
  /// Throws exception if upload fails
  Future<String> uploadImage(File imageFile, {String? folder}) async {
    try {
      // Validate file size (max 5MB for free tier)
      final fileSize = await imageFile.length();
      const maxSize = 5 * 1024 * 1024; // 5MB in bytes

      if (fileSize > maxSize) {
        throw Exception('Image size must be less than 5 MB');
      }

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(kCloudinaryUploadUrl),
      );

      // Add upload preset (unsigned)
      request.fields['upload_preset'] = kCloudinaryUploadPreset;

      // Add folder if specified
      if (folder != null && folder.isNotEmpty) {
        request.fields['folder'] = folder;
      }

      // Add the image file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Check response status
      if (response.statusCode != 200) {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }

      // Parse response
      final responseData = json.decode(response.body);

      // Extract secure URL
      final secureUrl = responseData['secure_url'] as String?;

      if (secureUrl == null || secureUrl.isEmpty) {
        throw Exception('No URL returned from Cloudinary');
      }

      return secureUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload profile photo to Cloudinary
  ///
  /// [userId] - User ID for organized storage
  /// [imageFile] - Profile photo file
  ///
  /// Returns the secure URL
  Future<String> uploadProfilePhoto(String userId, File imageFile) async {
    return uploadImage(imageFile, folder: 'profiles/$userId');
  }

  /// Upload chat image to Cloudinary
  ///
  /// [chatId] - Chat ID for organized storage
  /// [imageFile] - Chat image file
  ///
  /// Returns the secure URL
  Future<String> uploadChatImage(String chatId, File imageFile) async {
    return uploadImage(imageFile, folder: 'chats/$chatId');
  }

  /// Optional: Delete image from Cloudinary
  ///
  /// Note: Deletion requires authenticated API calls with API secret.
  /// For unsigned uploads, images can be deleted from Cloudinary dashboard.
  /// This method is a placeholder for future implementation.
  ///
  /// [publicId] - The public ID of the image (from Cloudinary response)
  Future<bool> deleteImage(String publicId) async {
    // Deletion requires API secret - not recommended for client apps
    // Images can be managed from Cloudinary dashboard
    // Or implement server-side deletion endpoint
    throw UnimplementedError(
      'Image deletion requires server-side implementation for security',
    );
  }

  /// Validate image file
  ///
  /// [imageFile] - File to validate
  ///
  /// Returns true if valid, throws exception otherwise
  bool validateImageFile(File imageFile) {
    // Check if file exists
    if (!imageFile.existsSync()) {
      throw Exception('Image file does not exist');
    }

    // Check file extension
    final ext = imageFile.path.split('.').last.toLowerCase();
    const validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];

    if (!validExtensions.contains(ext)) {
      throw Exception('Invalid image format. Supported: JPG, PNG, GIF, WebP');
    }

    return true;
  }

  /// Get optimized image URL with transformations
  ///
  /// Cloudinary supports URL-based transformations.
  /// Example: w_400,h_400,c_fill (resize to 400x400, crop to fill)
  ///
  /// [originalUrl] - Original Cloudinary URL
  /// [width] - Desired width
  /// [height] - Desired height
  /// [quality] - Image quality (auto, best, good, eco, low)
  ///
  /// Returns optimized URL
  String getOptimizedUrl(
    String originalUrl, {
    int? width,
    int? height,
    String quality = 'auto',
  }) {
    // Parse original URL
    if (!originalUrl.contains('cloudinary.com')) {
      return originalUrl; // Not a Cloudinary URL
    }

    // Build transformation string
    final transformations = <String>[];

    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    transformations.add('c_fill'); // Crop to fill
    transformations.add('q_$quality'); // Quality
    transformations.add('f_auto'); // Auto format (WebP for supported browsers)

    final transformString = transformations.join(',');

    // Insert transformation into URL
    // URL format: https://res.cloudinary.com/{cloud}/image/upload/{public_id}
    // New format: https://res.cloudinary.com/{cloud}/image/upload/{transforms}/{public_id}

    final uploadIndex = originalUrl.indexOf('/upload/');
    if (uploadIndex == -1) return originalUrl;

    final beforeUpload = originalUrl.substring(0, uploadIndex + 8);
    final afterUpload = originalUrl.substring(uploadIndex + 8);

    return '$beforeUpload$transformString/$afterUpload';
  }

  /// Get thumbnail URL (small size for lists)
  ///
  /// [originalUrl] - Original Cloudinary URL
  ///
  /// Returns thumbnail URL (200x200)
  String getThumbnailUrl(String originalUrl) {
    return getOptimizedUrl(
      originalUrl,
      width: 200,
      height: 200,
      quality: 'auto',
    );
  }

  /// Get medium URL (for chat messages)
  ///
  /// [originalUrl] - Original Cloudinary URL
  ///
  /// Returns medium-sized URL (800x800)
  String getMediumUrl(String originalUrl) {
    return getOptimizedUrl(
      originalUrl,
      width: 800,
      height: 800,
      quality: 'good',
    );
  }
}
