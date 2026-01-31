// =============================================================================
// YemenChat - Firestore Service
// =============================================================================
// Handles all Firestore database operations for chats, messages, etc.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Service class for handling Firestore operations
class FirestoreService {
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===========================================================================
  // USER OPERATIONS
  // ===========================================================================

  /// Get all registered users (excluding current user)
  Future<List<UserModel>> getAllUsers(String currentUserId) async {
    final querySnapshot =
        await _firestore
            .collection(kUsersCollection)
            .where(FieldPath.documentId, isNotEqualTo: currentUserId)
            .get();

    return querySnapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .toList();
  }

  /// Search users by name or username
  Future<List<UserModel>> searchUsers(
    String query,
    String currentUserId,
  ) async {
    final queryLower = query.toLowerCase();

    // Get all users and filter locally (Firestore doesn't support partial matching)
    final users = await getAllUsers(currentUserId);

    return users.where((user) {
      return user.fullName.toLowerCase().contains(queryLower) ||
          user.username.toLowerCase().contains(queryLower);
    }).toList();
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    final doc = await _firestore.collection(kUsersCollection).doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Stream user data for real-time updates
  Stream<UserModel?> streamUser(String userId) {
    return _firestore
        .collection(kUsersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // ===========================================================================
  // CHAT OPERATIONS
  // ===========================================================================

  /// Get or create a chat between two users
  Future<ChatModel> getOrCreateChat(String userId1, String userId2) async {
    // Generate deterministic chat ID
    final chatId = Helpers.generateChatId(userId1, userId2);

    // Check if chat exists
    final doc = await _firestore.collection(kChatsCollection).doc(chatId).get();

    if (doc.exists) {
      return ChatModel.fromFirestore(doc);
    }

    // Create new chat
    final chat = ChatModel(
      id: chatId,
      members: [userId1, userId2],
      lastMessage: '',
      lastTime: DateTime.now(),
    );

    await _firestore.collection(kChatsCollection).doc(chatId).set(chat.toMap());
    return chat;
  }

  /// Get all chats for a user
  Stream<List<ChatModel>> streamUserChats(String userId) {
    return _firestore
        .collection(kChatsCollection)
        .where('members', arrayContains: userId)
        .orderBy('lastTime', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => ChatModel.fromFirestore(doc)).toList(),
        );
  }

  /// Update chat's last message
  Future<void> updateChatLastMessage(
    String chatId,
    String message,
    DateTime time,
  ) async {
    await _firestore.collection(kChatsCollection).doc(chatId).update({
      'lastMessage': message,
      'lastTime': Timestamp.fromDate(time),
    });
  }

  /// Toggle pin status for a chat
  Future<void> togglePinChat(
    String chatId,
    String userId,
    bool isPinned,
  ) async {
    await _firestore.collection(kChatsCollection).doc(chatId).update({
      'isPinned.$userId': isPinned,
    });
  }

  /// Delete a chat (soft delete - just remove from user's view)
  Future<void> deleteChat(String chatId) async {
    // Delete all messages in the chat
    final messagesRef = _firestore
        .collection(kChatsCollection)
        .doc(chatId)
        .collection(kMessagesCollection);

    final messages = await messagesRef.get();
    for (final doc in messages.docs) {
      await doc.reference.delete();
    }

    // Delete the chat document
    await _firestore.collection(kChatsCollection).doc(chatId).delete();
  }

  /// Update unread count for a user
  Future<void> updateUnreadCount(
    String chatId,
    String userId,
    int count,
  ) async {
    await _firestore.collection(kChatsCollection).doc(chatId).update({
      'unreadCount.$userId': count,
    });
  }

  /// Reset unread count when user opens chat
  Future<void> resetUnreadCount(String chatId, String userId) async {
    await updateUnreadCount(chatId, userId, 0);
  }

  // ===========================================================================
  // MESSAGE OPERATIONS
  // ===========================================================================

  /// Send a message
  Future<MessageModel> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    String? imageUrl,
  }) async {
    final messagesRef = _firestore
        .collection(kChatsCollection)
        .doc(chatId)
        .collection(kMessagesCollection);

    final now = DateTime.now();

    // Create message
    final messageData = {
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'time': Timestamp.fromDate(now),
      'status': 'sent',
    };

    final docRef = await messagesRef.add(messageData);

    // Update chat's last message
    await updateChatLastMessage(
      chatId,
      imageUrl != null ? '📷 Photo' : text,
      now,
    );

    // Increment unread count for other user
    final chat =
        await _firestore.collection(kChatsCollection).doc(chatId).get();
    final members = List<String>.from(chat.data()?['members'] ?? []);
    final otherUserId = members.firstWhere(
      (id) => id != senderId,
      orElse: () => '',
    );
    if (otherUserId.isNotEmpty) {
      final currentCount =
          (chat.data()?['unreadCount']?[otherUserId] ?? 0) as int;
      await updateUnreadCount(chatId, otherUserId, currentCount + 1);
    }

    return MessageModel(
      id: docRef.id,
      chatId: chatId,
      senderId: senderId,
      text: text,
      imageUrl: imageUrl,
      time: now,
      status: MessageStatus.sent,
    );
  }

  /// Stream messages for a chat
  Stream<List<MessageModel>> streamMessages(String chatId) {
    return _firestore
        .collection(kChatsCollection)
        .doc(chatId)
        .collection(kMessagesCollection)
        .orderBy('time', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => MessageModel.fromFirestore(doc, chatId))
                  .toList(),
        );
  }

  /// Update message status
  Future<void> updateMessageStatus(
    String chatId,
    String messageId,
    MessageStatus status,
  ) async {
    String statusStr;
    switch (status) {
      case MessageStatus.sent:
        statusStr = 'sent';
        break;
      case MessageStatus.delivered:
        statusStr = 'delivered';
        break;
      case MessageStatus.seen:
        statusStr = 'seen';
        break;
      default:
        statusStr = 'sending';
    }

    await _firestore
        .collection(kChatsCollection)
        .doc(chatId)
        .collection(kMessagesCollection)
        .doc(messageId)
        .update({'status': statusStr});
  }

  /// Mark all messages as seen
  Future<void> markMessagesAsSeen(String chatId, String currentUserId) async {
    final messagesRef = _firestore
        .collection(kChatsCollection)
        .doc(chatId)
        .collection(kMessagesCollection);

    // Get messages not from current user (we can't use multiple != filters in Firestore)
    final allMessages = await messagesRef.get();

    for (final doc in allMessages.docs) {
      final data = doc.data();
      final senderId = data['senderId'] as String?;
      final status = data['status'] as String?;

      // Only update if message is from other user and not already seen
      if (senderId != currentUserId && status != 'seen') {
        await doc.reference.update({'status': 'seen'});
      }
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String chatId, String messageId) async {
    await _firestore
        .collection(kChatsCollection)
        .doc(chatId)
        .collection(kMessagesCollection)
        .doc(messageId)
        .delete();
  }

  /// Search messages in a chat
  Future<List<MessageModel>> searchMessages(String chatId, String query) async {
    final queryLower = query.toLowerCase();

    final snapshot =
        await _firestore
            .collection(kChatsCollection)
            .doc(chatId)
            .collection(kMessagesCollection)
            .orderBy('time', descending: true)
            .get();

    return snapshot.docs
        .map((doc) => MessageModel.fromFirestore(doc, chatId))
        .where((msg) => msg.text.toLowerCase().contains(queryLower))
        .toList();
  }

  // ===========================================================================
  // FAVORITES OPERATIONS
  // ===========================================================================

  /// Add user to favorites
  Future<void> addToFavorites(String userId, String favoriteUserId) async {
    await _firestore
        .collection(kFavoritesCollection)
        .doc(userId)
        .collection('list')
        .doc(favoriteUserId)
        .set({'addedAt': Timestamp.now()});
  }

  /// Remove user from favorites
  Future<void> removeFromFavorites(String userId, String favoriteUserId) async {
    await _firestore
        .collection(kFavoritesCollection)
        .doc(userId)
        .collection('list')
        .doc(favoriteUserId)
        .delete();
  }

  /// Check if user is in favorites
  Future<bool> isFavorite(String userId, String targetUserId) async {
    final doc =
        await _firestore
            .collection(kFavoritesCollection)
            .doc(userId)
            .collection('list')
            .doc(targetUserId)
            .get();
    return doc.exists;
  }

  /// Get all favorite users
  Stream<List<String>> streamFavoriteIds(String userId) {
    return _firestore
        .collection(kFavoritesCollection)
        .doc(userId)
        .collection('list')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  /// Get favorite users with full profiles
  Future<List<UserModel>> getFavoriteUsers(String userId) async {
    final favDocs =
        await _firestore
            .collection(kFavoritesCollection)
            .doc(userId)
            .collection('list')
            .get();

    final favoriteIds = favDocs.docs.map((doc) => doc.id).toList();
    if (favoriteIds.isEmpty) return [];

    final users = <UserModel>[];
    for (final id in favoriteIds) {
      final user = await getUserById(id);
      if (user != null) users.add(user);
    }
    return users;
  }

  // ===========================================================================
  // BLOCKED USERS OPERATIONS
  // ===========================================================================

  /// Block a user
  Future<void> blockUser(String userId, String blockedUserId) async {
    await _firestore
        .collection(kBlockedUsersCollection)
        .doc(userId)
        .collection('list')
        .doc(blockedUserId)
        .set({'blockedAt': Timestamp.now()});
  }

  /// Unblock a user
  Future<void> unblockUser(String userId, String blockedUserId) async {
    await _firestore
        .collection(kBlockedUsersCollection)
        .doc(userId)
        .collection('list')
        .doc(blockedUserId)
        .delete();
  }

  /// Check if user is blocked
  Future<bool> isBlocked(String userId, String targetUserId) async {
    final doc =
        await _firestore
            .collection(kBlockedUsersCollection)
            .doc(userId)
            .collection('list')
            .doc(targetUserId)
            .get();
    return doc.exists;
  }

  /// Get all blocked user IDs
  Stream<List<String>> streamBlockedIds(String userId) {
    return _firestore
        .collection(kBlockedUsersCollection)
        .doc(userId)
        .collection('list')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }
}
