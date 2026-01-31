// =============================================================================
// YemenChat - Chat Model
// =============================================================================
// This model represents a chat conversation between two users.
// It maps to the 'chats' collection in Firestore.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

/// Chat model class representing a conversation between users
class ChatModel {
  // Unique chat ID
  final String id;

  // List of user IDs in this chat (typically 2 users for 1-on-1 chat)
  final List<String> members;

  // Preview of the last message in this chat
  final String lastMessage;

  // Timestamp of the last message
  final DateTime lastTime;

  // Map of userId -> isPinned status
  final Map<String, bool> isPinned;

  // Map of userId -> unread count
  final Map<String, int> unreadCount;

  /// Constructor
  ChatModel({
    required this.id,
    required this.members,
    required this.lastMessage,
    required this.lastTime,
    Map<String, bool>? isPinned,
    Map<String, int>? unreadCount,
  }) : isPinned = isPinned ?? {},
       unreadCount = unreadCount ?? {};

  /// Create ChatModel from Firestore document
  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      members: List<String>.from(data['members'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastTime: (data['lastTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPinned: Map<String, bool>.from(data['isPinned'] ?? {}),
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
    );
  }

  /// Convert ChatModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'members': members,
      'lastMessage': lastMessage,
      'lastTime': Timestamp.fromDate(lastTime),
      'isPinned': isPinned,
      'unreadCount': unreadCount,
    };
  }

  /// Get the other user's ID (for 1-on-1 chats)
  String getOtherUserId(String currentUserId) {
    return members.firstWhere((id) => id != currentUserId, orElse: () => '');
  }

  /// Check if chat is pinned for a specific user
  bool isPinnedForUser(String userId) {
    return isPinned[userId] ?? false;
  }

  /// Get unread count for a specific user
  int getUnreadCount(String userId) {
    return unreadCount[userId] ?? 0;
  }

  /// Create a copy with updated fields
  ChatModel copyWith({
    String? id,
    List<String>? members,
    String? lastMessage,
    DateTime? lastTime,
    Map<String, bool>? isPinned,
    Map<String, int>? unreadCount,
  }) {
    return ChatModel(
      id: id ?? this.id,
      members: members ?? this.members,
      lastMessage: lastMessage ?? this.lastMessage,
      lastTime: lastTime ?? this.lastTime,
      isPinned: isPinned ?? this.isPinned,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  String toString() {
    return 'ChatModel(id: $id, members: $members, lastMessage: $lastMessage)';
  }
}
