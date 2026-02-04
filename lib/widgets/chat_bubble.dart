// =============================================================================
// YemenChat - Chat Bubble Widget
// =============================================================================
// Reusable chat bubble for displaying messages.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/message_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Chat bubble widget for displaying messages
class ChatBubble extends StatelessWidget {
  /// The message to display
  final MessageModel message;

  /// Whether this message was sent by the current user
  final bool isSent;

  /// Callback when message is long pressed
  final VoidCallback? onLongPress;

  /// Callback when image is tapped
  final VoidCallback? onImageTap;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isSent,
    this.onLongPress,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: EdgeInsets.only(
            top: 5,
            bottom: 5,
            left: isSent ? 64 : 1,
            right: isSent ? 1 : 64,
          ),
          padding:
              message.hasImage
                  ? const EdgeInsets.all(4)
                  : EdgeInsets.only(
                    top: 10,
                    bottom: 10,
                    right: isSent ? 8 : 48,
                    left: isSent ? 38 : 8,
                  ),
          decoration: BoxDecoration(
            color: isSent ? kSentBubbleColor : kReceivedBubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isSent ? 20 : 0),
              topRight: Radius.circular(isSent ? 0 : 20),
              bottomLeft: Radius.circular(isSent ? 16 : 40),
              bottomRight: Radius.circular(isSent ? 40 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Image (if present)
              if (message.hasImage) _buildImage(),

              // Text (if present)
              if (message.hasText)
                Padding(
                  padding:
                      message.hasImage
                          ? const EdgeInsets.fromLTRB(8, 4, 8, 0)
                          : EdgeInsets.only(
                            right: isSent ? 8 : 5,
                            left: isSent ? 5 : 8,
                          ),
                  child: Text(
                    message.text,
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                ),

              // Time and status
              const SizedBox(height: 4),
              _buildTimeAndStatus(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build image widget
  Widget _buildImage() {
    return GestureDetector(
      onTap: onImageTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 250, maxHeight: 300),
          child: CachedNetworkImage(
            imageUrl: message.imageUrl!,
            fit: BoxFit.cover,
            placeholder:
                (context, url) => Container(
                  width: 200,
                  height: 150,
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            errorWidget:
                (context, url, error) => Container(
                  width: 200,
                  height: 150,
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.broken_image,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),
          ),
        ),
      ),
    );
  }

  /// Build time and status indicator
  Widget _buildTimeAndStatus() {
    return Padding(
      padding:
          message.hasImage
              ? const EdgeInsets.only(right: 8, bottom: 4)
              : EdgeInsets.only(right: isSent ? 10 : 28, left: isSent ? 18 : 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Helpers.formatMessageTime(message.time),
            style: TextStyle(
              fontSize: 11,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
          if (isSent) ...[const SizedBox(width: 4), _buildStatusIcon()],
        ],
      ),
    );
  }

  /// Build message status icon
  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    switch (message.status) {
      case MessageStatus.sending:
        icon = Icons.access_time;
        color = Colors.grey;
        break;
      case MessageStatus.sent:
        icon = Icons.check;
        color = Colors.grey;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = Colors.grey;
        break;
      case MessageStatus.seen:
        icon = Icons.done_all;
        color = Colors.blue;
        break;
    }

    return Icon(icon, size: 14, color: color);
  }
}
