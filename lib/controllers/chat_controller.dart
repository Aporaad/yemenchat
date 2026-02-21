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
  List<ChatModel> _chats = []; // ① كل محادثات المستخدم
  List<MessageModel> _currentMessages = []; // ② رسائل المحادثة المفتوحة حالياً
  Map<String, UserModel> _userCache = {}; // ③ بيانات المستخدمين المخزنة
  String? _currentChatId; // ④ ID المحادثة المفتوحة حالياً
  bool _isLoading = false; // ⑤ حالة التحميل
  bool _isSending = false; // ⑥ حالة الارسال
  String? _errorMessage; // ⑦ رسالة الخطأ
  String _searchQuery = ''; // ⑧ نص البحث

  // Stream :  قناة بيانات مستمرة من Firebase.
  // بدلاً من أن تسأل "هل في رسائل جديدة؟" كل ثانية، Firebase يُرسل لك البيانات تلقائياً عند أي تغيير.
  StreamSubscription?
  _chatsSubscription; // ⑨ اشتراك Stream للمحادثات  // → يحدّث _chats
  StreamSubscription?
  _messagesSubscription; // ⑩ اشتراك Stream للرسائل  // → يحدّث _currentMessages

  // ===========================================================================
  // GETTERS
  // ===========================================================================

  /// All chats (filtered by search if applicable)
  /// uses in _ChatsTaps()
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
  /// uses in _ChatsTaps()
  List<ChatModel> get pinnedChats {
    if (_currentUserId == null) return [];
    return _chats.where((c) => c.isPinnedForUser(_currentUserId!)).toList();
  }

  /// Regular (non-pinned) chats
  /// uses in _ChatsTaps()
  List<ChatModel> get regularChats {
    if (_currentUserId == null) return _chats;
    return _chats.where((c) => !c.isPinnedForUser(_currentUserId!)).toList();
  }

  /// Current chat messages
  /// uses in _ChatScreen()
  List<MessageModel> get messages => _currentMessages;

  /// Current chat ID
  /// uses in _ChatScreen()
  String? get currentChatId => _currentChatId;

  /// Check if loading
  /// uses in _ChatScreen()
  bool get isLoading => _isLoading;

  /// Check if sending message
  /// uses in _ChatScreen()
  bool get isSending => _isSending;

  /// Get error message
  /// uses in _ChatScreen()
  String? get errorMessage => _errorMessage;

  /// Current user ID (set before using controller)
  /// uses in _ChatScreen()
  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================
  /// Set current user ID and start listening to chats
  /// uses in _ChatScreen()
  void initialize(String userId) {
    // Prevent duplicate initialization
    if (_currentUserId == userId) return;

    _currentUserId = userId;
    _listenToChats();
  }

  /// Listen to user's
  /// تجعل المحادثات تتحدث تلقائياً بدون أي تدخل
  /// uses in _ChatScreen()
  ///  "ابقَ مستمعاً لـ Firebase،
  ///  وكل ما تتغير المحادثات: حدّث القائمة، خزّن بيانات المستخدمين، وإذا وصلت رسالة جديدة أرسل إشعاراً."
  void _listenToChats() {
    if (_currentUserId == null) return; // إذا ما في مستخدم مسجل → لا تعمل شيء

    // ← ألغي أي استماع قديم (لو موجود)
    _chatsSubscription
        ?.cancel(); //تعني الغاء الاشتراك السابق لضمان عدم تكرار البيانات اثناء التنقل بين المحادثات

    // Track previous unread counts to detect new messages
    // تتبع عدد الرسائل غير المقروءة السابقة للكشف عن الرسائل الجديدة
    //ثم يحفظ عدد الرسائل غير المقروءة قبل التحديث:
    Map<String, int> previousUnreadCounts = {};
    for (final chat in _chats) {
      previousUnreadCounts[chat.id] = chat.getUnreadCount(_currentUserId!);
    }

    _chatsSubscription = _firestoreService
        .streamUserChats(_currentUserId!)
        .listen((chatList) async {
          // ← "كل ما وصل رسالة جديد، الـ Stream يرسل لك القائمة المحدثة هنا"
          _chats = chatList; // ← يحدّث قائمة المحادثات

          // Check for new unread messages and show notifications
          // يتحقق من وجود رسائل جديدة ويعرض الإشعارات
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

          notifyListeners(); // ← "يا شاشات! البيانات تغيّرت، أعيدوا بناء أنفسكم"
        });
  }

  /// Get cached user or fetch from Firestore
  ///  "إما أن تأخذ المستخدم من الذاكرة (لو موجود)،
  ///  أو تطلبه من Firestore وتخزّنه عندك."
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
  ///  "لو موجود في الذاكرة → أعطيه فوراً، بدون ما تروح للشبكة."
  UserModel? getCachedUser(String userId) => _userCache[userId];

  // ===========================================================================
  // CHAT OPERATIONS
  // ===========================================================================

  /// Search chats
  ///  "يخزّن النص"
  void searchChats(String query) {
    _searchQuery = query; // يخزّن النص
    notifyListeners();
  }

  /// Clear search
  ///  "يمسح البحث"
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  /// Start or open a chat with a user
  ///  "يفتح محادثة جديدة أو يستأنف محادثة موجودة" ي
  /// يستخدم في شاشة جهات الاتصال او المفضلة لفتح محادثة جديدة عند الضغط على زر "محادثة جديدة"
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
  /// يفتح محادثة موجودة بالمعرف (يُستخدم في شاشة الرسائل  عند الانتقال من شاشة المحادثات  إلى شاشة الرسائل)
  void openChatById(String chatId) {
    _currentChatId = chatId;
    // يبدأ بالاستماع إلى الرسائل في المحادثة المحددة
    _listenToMessages(chatId);

    // Reset unread count if we have current user
    // يصفر عدد الرسائل غير المقروءة إذا كان لدينا مستخدم حالي
    if (_currentUserId != null) {
      _firestoreService.resetUnreadCount(chatId, _currentUserId!);
    }
  }

  /*الفرق بين 
openChat: يُستخدم من جهات الاتصال (قد تحتاج إنشاء محادثة جديدة)
openChatById: يُستخدم من قائمة المحادثات (المحادثة موجودة مسبقاً) */

  /// Close current chat
  ///
  /// [silent] - if true, won't call notifyListeners (used during dispose)
  /// يستخدم عند الخروج من شاشة الرسائل لالغاء الاشتراك في الرسائل
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
  /// تستخدم عند فتح شاشة الدردشة وتقوم بتحميل الرسائل وبدء الاستماع
  /// تغيير حاله الرسائل غير المقرؤة
  void _listenToMessages(String chatId) {
    _messagesSubscription?.cancel();

    // Track previous message count to detect new messages
    int previousMessageCount = _currentMessages.length;

    _messagesSubscription = _firestoreService.streamMessages(chatId).listen((
      messageList,
    ) {
      // Check if there are new messages
      final hasNewMessages = messageList.length > previousMessageCount;

      // If there's a new message and it's not from current user, show
      //  يتم عرض إشعار إذا كان هناك رسالة جديدة وليست من المستخدم الحالي
      if (hasNewMessages && messageList.isNotEmpty) {
        //  يتم الحصول على أحدث رسالة
        final latestMessage = messageList.first;

        //  يتم عرض الإشعار فقط إذا كانت الرسالة من مستخدم آخر
        if (latestMessage.senderId != _currentUserId) {
          //  يتم الحصول على معلومات المرسل للإشعار
          final sender = _userCache[latestMessage.senderId];
          if (sender != null) {
            //  يتم عرض الإشعار المحلي
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

  Future<void> updateChats() async {
    _chats = _chats;
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

  /*بدون هذا التنظيف، ستبقى الـ Streams
 تعمل في الخلفية وتستهلك موارد الجهاز والإنترنت حتى بعد إغلاق التطبيق. */
  @override
  void dispose() {
    _chatsSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }
}
