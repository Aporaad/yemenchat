// =============================================================================
// YemenChat - Image Message Widget
// =============================================================================
// Professional widget for displaying image messages in chat.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/constants.dart';
import 'full_screen_image.dart';

/// Widget for displaying image messages in chat
class ImageMessage extends StatelessWidget {
  /// Image URL from Cloudinary
  final String imageUrl;

  /// Whether this message was sent by current user
  final bool isSent;

  /// Optional caption/text with the image
  final String? caption;

  /// Message timestamp
  final String time;

  /// Loading widget builder
  final Widget Function(BuildContext, String)? loadingBuilder;

  /// Error widget builder
  final Widget Function(BuildContext, String, dynamic)? errorBuilder;

  const ImageMessage({
    super.key,
    required this.imageUrl,
    required this.isSent,
    this.caption,
    required this.time,
    this.loadingBuilder,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        margin: EdgeInsets.only(
          left: isSent ? 64 : 8,
          right: isSent ? 8 : 64,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          color: isSent ? kSentBubbleColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isSent ? 16 : 4),
            bottomRight: Radius.circular(isSent ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            _buildImage(context),

            // Caption and time
            if (caption != null && caption!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Text(caption!, style: const TextStyle(fontSize: 14)),
              ),
            ],

            // Timestamp
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Text(
                time,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final hasCaption = caption != null && caption!.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(16),
        topRight: const Radius.circular(16),
        bottomLeft: Radius.circular(hasCaption ? 0 : 16),
        bottomRight: Radius.circular(hasCaption ? 0 : 16),
      ),
      child: GestureDetector(
        onTap: () => _openFullScreen(context),
        child: Hero(
          tag: imageUrl,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: loadingBuilder ?? _defaultLoadingBuilder,
            errorWidget: errorBuilder ?? _defaultErrorBuilder,
          ),
        ),
      ),
    );
  }

  Widget _defaultLoadingBuilder(BuildContext context, String url) {
    return Container(
      height: 200,
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                isSent ? kPrimaryDarkColor : kPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Loading image...',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultErrorBuilder(BuildContext context, String url, dynamic error) {
    return Container(
      height: 200,
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'Failed to load image',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () {
              // Trigger reload by rebuilding
              (context as Element).markNeedsBuild();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => FullScreenImage(imageUrl: imageUrl, heroTag: imageUrl),
      ),
    );
  }
}
