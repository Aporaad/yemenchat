// =============================================================================
// YemenChat - Chat Controller
// =============================================================================
// State management for chats and messages.
// =============================================================================

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/image_upload_service.dart';
import '../services/storage_service.dart'; // For picking images only
import '../main.dart'; // For notificationService

/// Controller for managing chat state
class ChatController extends ChangeNotifier {
  // Services
  final FirestoreService _firestoreService = FirestoreService();
  final ImageUploadService _imageUploadService = ImageUploadService();
  final StorageService _storageService =
      StorageService(); // For image picking only

  // State
  List<ChatModel> _chats = [];
  List<MessageModel> _currentMessages = [];
  Map<String, UserModel> _userCache = {};
  String? _currentChatId;
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;
  String _searchQuery = '';

  // Stream subscriptions
  StreamSubscription? _chatsSubscription;
  StreamSubscription? _messagesSubscription;

  // ===========================================================================
  // GETTERS
  // ===========================================================================

  /// All chats (filtered by search if applicable)
  List<ChatModel> get chats {
    if (_searchQuery.isEmpty) return _chats;

    return _chats.where((chat) {
      // Search in last message or user name
      final user = _userCache[chat.getOtherUserId(_currentUserId ?? '')];
      if (user == null) return false;

      final query = _searchQuery.toLowerCase();
      return user.fullName.toLowerCase().contains(query) ||
          user.username.toLowerCase().contains(query) ||
          chat.lastMessage.toLowerCase().contains(query);
    }).toList();
  }

  /// Pinned chats
  List<ChatModel> get pinnedChats {
    if (_currentUserId == null) return [];
    return _chats.where((c) => c.isPinnedForUser(_currentUserId!)).toList();
  }

  /// Regular (non-pinned) chats
  List<ChatModel> get regularChats {
    if (_currentUserId == null) return _chats;
    return _chats.where((c) => !c.isPinnedForUser(_currentUserId!)).toList();
  }

  /// Current chat messages
  List<MessageModel> get messages => _currentMessages;

  /// Current chat ID
  String? get currentChatId => _currentChatId;

  /// Check if loading
  bool get isLoading => _isLoading;

  /// Check if sending message
  bool get isSending => _isSending;

  /// Get error message
  String? get errorMessage => _errorMessage;

  /// Current user ID (set before using controller)
  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================

  /// Set current user ID and start listening to chats
  void initialize(String userId) {
    // Prevent duplicate initialization
    if (_currentUserId == userId) return;

    _currentUserId = userId;
    _listenToChats();
  }

  /// Listen to user's chats
  void _listenToChats() {
    if (_currentUserId == null) return;

    _chatsSubscription?.cancel();

    // Track previous unread counts to detect new messages
    Map<String, int> previousUnreadCounts = {};
    for (final chat in _chats) {
      previousUnreadCounts[chat.id] = chat.getUnreadCount(_currentUserId!);
    }

    _chatsSubscription = _firestoreService
        .streamUserChats(_currentUserId!)
        .listen((chatList) async {
          _chats = chatList;

          // Check for new unread messages and show notifications
          for (final chat in chatList) {
            final currentUnread = chat.getUnreadCount(_currentUserId!);
            final previousUnread = previousUnreadCounts[chat.id] ?? 0;

            // If unread count increased, there's a new message
            if (currentUnread > previousUnread) {
              final otherUserId = chat.getOtherUserId(_currentUserId!);

              // Cache user data and show notification
              if (!_userCache.containsKey(otherUserId)) {
                final user = await _firestoreService.getUserById(otherUserId);
                if (user != null) {
                  _userCache[otherUserId] = user;
                }
              }

              final sender = _userCache[otherUserId];
              if (sender != null) {
                // Show notification
                notificationService.showNotification(
                  title: sender.fullName,
                  body: chat.lastMessage,
                  payload: chat.id,
                );
              }
            }

            // Update previous count
            previousUnreadCounts[chat.id] = currentUnread;
          }

          // Cache user data for each chat
          for (final chat in chatList) {
            final otherUserId = chat.getOtherUserId(_currentUserId!);
            if (!_userCache.containsKey(otherUserId)) {
              final user = await _firestoreService.getUserById(otherUserId);
              if (user != null) {
                _userCache[otherUserId] = user;
              }
            }
          }

          notifyListeners();
        });
  }

  /// Get cached user or fetch from Firestore
  Future<UserModel?> getUser(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    final user = await _firestoreService.getUserById(userId);
    if (user != null) {
      _userCache[userId] = user;
    }
    return user;
  }

  /// Get user from cache (synchronous)
  UserModel? getCachedUser(String userId) => _userCache[userId];

  // ===========================================================================
  // CHAT OPERATIONS
  // ===========================================================================

  /// Search chats
  void searchChats(String query) {
    _searchQuery = query;// يخزّن النص
    notifyListeners();
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  /// Start or open a chat with a user
  Future<ChatModel?> openChat(
    String otherUserId, {
    String? currentUserId,
  }) async {
    // Initialize if needed
    if (_currentUserId == null && currentUserId != null) {
      initialize(currentUserId);
    }

    if (_currentUserId == null) return null;

    _setLoading(true);

    try {
      final chat = await _firestoreService.getOrCreateChat(
        _currentUserId!,
        otherUserId,
      );

      _currentChatId = chat.id;
      _listenToMessages(chat.id);

      // Reset unread count
      await _firestoreService.resetUnreadCount(chat.id, _currentUserId!);

      _setLoading(false);
      return chat;
    } catch (e) {
      _errorMessage = 'Failed to open chat: $e';
      _setLoading(false);
      return null;
    }
  }

  /// Open an existing chat by ID (used when navigating to chat screen)
  void openChatById(String chatId) {
    _currentChatId = chatId;
    _listenToMessages(chatId);

    // Reset unread count if we have current user
    if (_currentUserId != null) {
      _firestoreService.resetUnreadCount(chatId, _currentUserId!);
    }
  }

  /// Close current chat
  ///
  /// [silent] - if true, won't call notifyListeners (used during dispose)
  void closeChat({bool silent = false}) {
    _messagesSubscription?.cancel();
    _currentChatId = null;
    _currentMessages = [];

    // Only notify listeners if not disposing
    if (!silent) {
      notifyListeners();
    }
  }

  /// Pin/unpin a chat
  Future<void> togglePin(String chatId) async {
    if (_currentUserId == null) return;

    final chat = _chats.firstWhere((c) => c.id == chatId);
    final isPinned = chat.isPinnedForUser(_currentUserId!);

    await _firestoreService.togglePinChat(chatId, _currentUserId!, !isPinned);
  }

  /// Delete a chat
  Future<bool> deleteChat(String chatId) async {
    try {
      await _firestoreService.deleteChat(chatId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete chat: $e';
      return false;
    }
  }

  // ===========================================================================
  // MESSAGE OPERATIONS
  // ===========================================================================

  /// Listen to messages in current chat
  void _listenToMessages(String chatId) {
    _messagesSubscription?.cancel();

    // Track previous message count to detect new messages
    int previousMessageCount = _currentMessages.length;

    _messagesSubscription = _firestoreService.streamMessages(chatId).listen((
      messageList,
    ) {
      // Check if there are new messages
      final hasNewMessages = messageList.length > previousMessageCount;

      // If there's a new message and it's not from current user, show notification
      if (hasNewMessages && messageList.isNotEmpty) {
        final latestMessage = messageList.first;

        // Only notify if message is from other user
        if (latestMessage.senderId != _currentUserId) {
          // Get sender info for notification
          final sender = _userCache[latestMessage.senderId];
          if (sender != null) {
            // Show local notification
            notificationService.showNotification(
              title: sender.fullName,
              body: latestMessage.text,
              payload: chatId,
            );
          }
        }
      }

      _currentMessages = messageList;
      previousMessageCount = messageList.length;

      // Mark messages as seen
      if (_currentUserId != null) {
        _firestoreService.markMessagesAsSeen(chatId, _currentUserId!);
      }

      notifyListeners();
    });
  }

  /// Send a text message
  Future<bool> sendMessage(String text) async {
    if (_currentChatId == null || _currentUserId == null) return false;
    if (text.trim().isEmpty) return false;

    _isSending = true;
    notifyListeners();

    try {
      await _firestoreService.sendMessage(
        chatId: _currentChatId!,
        senderId: _currentUserId!,
        text: text.trim(),
      );

      _isSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to send message: $e';
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  /// Send an image message
  Future<bool> sendImage(File imageFile, {String? caption}) async {
    if (_currentChatId == null || _currentUserId == null) return false;

    _isSending = true;
    notifyListeners();

    try {
      // Upload image to Cloudinary
      final imageUrl = await _imageUploadService.uploadChatImage(
        _currentChatId!,
        imageFile,
      );

      // Send message with image
      await _firestoreService.sendMessage(
        chatId: _currentChatId!,
        senderId: _currentUserId!,
        text: caption ?? '',
        imageUrl: imageUrl,
      );

      _isSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to send image: $e';
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  /// Pick and send image from gallery
  Future<bool> sendImageFromGallery({String? caption}) async {
    final file = await _storageService.pickImageFromGallery();
    if (file == null) return false;
    return sendImage(file, caption: caption);
  }

  /// Take and send photo from camera
  Future<bool> sendImageFromCamera({String? caption}) async {
    final file = await _storageService.pickImageFromCamera();
    if (file == null) return false;
    return sendImage(file, caption: caption);
  }

  /// Delete a message
  Future<bool> deleteMessage(String messageId) async {
    if (_currentChatId == null) return false;

    try {
      await _firestoreService.deleteMessage(_currentChatId!, messageId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete message: $e';
      return false;
    }
  }

  /// Search messages in current chat
  Future<List<MessageModel>> searchMessages(String query) async {
    if (_currentChatId == null) return [];
    return _firestoreService.searchMessages(_currentChatId!, query);
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

  /// Get total unread count across all chats
  int get totalUnreadCount {
    if (_currentUserId == null) return 0;
    return _chats.fold(
      0,
      (sum, chat) => sum + chat.getUnreadCount(_currentUserId!),
    );
  }

  @override
  void dispose() {
    _chatsSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }
}
