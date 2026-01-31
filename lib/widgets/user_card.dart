// =============================================================================
// YemenChat - User Card Widget
// =============================================================================
// Reusable card for displaying user/contact information.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

/// User card widget for displaying contacts/chat previews
class UserCard extends StatelessWidget {
  /// User to display
  final UserModel user;

  /// Subtitle text (e.g., last message, status)
  final String? subtitle;

  /// Trailing text (e.g., time)
  final String? trailingText;

  /// Badge count (e.g., unread messages)
  final int? badgeCount;

  /// Whether this chat is pinned
  final bool isPinned;

  /// Whether user is online
  final bool isOnline;

  /// Callback when card is tapped
  final VoidCallback? onTap;

  /// Callback when avatar is tapped
  final VoidCallback? onAvatarTap;

  /// Callback when card is long pressed
  final VoidCallback? onLongPress;

  const UserCard({
    super.key,
    required this.user,
    this.subtitle,
    this.trailingText,
    this.badgeCount,
    this.isPinned = false,
    this.isOnline = false,
    this.onTap,
    this.onAvatarTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar with online indicator
              _buildAvatar(),
              const SizedBox(width: 12),

              // Name and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name row with pin icon
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPinned)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.push_pin,
                              size: 14,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),

                    // Subtitle
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Trailing section (time and badge)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (trailingText != null)
                    Text(
                      trailingText!,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            badgeCount != null && badgeCount! > 0
                                ? kPrimaryColor
                                : Colors.grey.shade500,
                      ),
                    ),
                  if (badgeCount != null && badgeCount! > 0) ...[
                    const SizedBox(height: 6),
                    _buildBadge(),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build avatar with online indicator
  Widget _buildAvatar() {
    return GestureDetector(
      onTap: onAvatarTap,
      child: Stack(
        children: [
          // Avatar
          CircleAvatar(
            radius: 26,
            backgroundColor: kPrimaryLightColor,
            backgroundImage:
                user.photoUrl != null
                    ? CachedNetworkImageProvider(user.photoUrl!)
                    : null,
            child:
                user.photoUrl == null
                    ? Text(
                      user.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                    : null,
          ),

          // Online indicator
          if (isOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: kOnlineColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build unread badge
  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        badgeCount! > 99 ? '99+' : badgeCount.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Simple contact card without chat-specific features
class ContactCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;
  final VoidCallback? onAvatarTap;
  final Widget? trailing;

  const ContactCard({
    super.key,
    required this.user,
    this.onTap,
    this.onAvatarTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: GestureDetector(
        onTap: onAvatarTap,
        child: CircleAvatar(
          radius: 24,
          backgroundColor: kPrimaryLightColor,
          backgroundImage:
              user.photoUrl != null
                  ? CachedNetworkImageProvider(user.photoUrl!)
                  : null,
          child:
              user.photoUrl == null
                  ? Text(
                    user.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                  : null,
        ),
      ),
      title: Text(
        user.fullName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '@${user.username}',
        style: TextStyle(color: Colors.grey.shade600),
      ),
      trailing: trailing,
    );
  }
}
