import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/image_message.dart';
import '../widgets/input_field.dart';
import '../services/pdf_export_service.dart';

/// Chat screen for messaging
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _searchController = TextEditingController();
  final _pdfService = PDFExportService();

  String? _chatId;
  String? _otherUserId;
  UserModel? _otherUser;
  ChatController? _chatController;

  // Search state
  bool _isSearching = false;
  String _searchQuery = '';
  List<MessageModel> _searchResults = [];
  int _currentSearchIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only initialize once
    if (!_isInitialized) {
      _isInitialized = true;
      // Save reference to ChatController before widget is deactivated
      _chatController = context.read<ChatController>();
      _loadChatData();
    }
  }

  void _loadChatData() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _chatId = args['chatId'] as String?;
      _otherUserId = args['userId'] as String?;

      if (_chatId != null && _chatController != null) {
        // Open the chat to load messages
        _chatController!.openChatById(_chatId!);
      }

      if (_otherUserId != null) {
        _loadOtherUser();
      }
    }
  }

  Future<void> _loadOtherUser() async {
    if (_chatController == null) return;
    _otherUser = await _chatController!.getUser(_otherUserId!);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _searchController.dispose();

    // Close chat when leaving (silent mode to avoid notifyListeners during dispose)
    _chatController?.closeChat(silent: true);
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: kAnimationFast,
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _chatController == null) return;

    _messageController.clear();

    await _chatController!.sendMessage(text);

    // Scroll to bottom after sending
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  /// Show image picker dialog
  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: kPrimaryColor,
                  ),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _sendImageFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: kPrimaryColor),
                  title: const Text('Take a Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _sendImageFromCamera();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cancel, color: Colors.grey),
                  title: const Text('Cancel'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
    );
  }

  /// Send image from gallery
  Future<void> _sendImageFromGallery() async {
    if (_chatController == null) return;

    final success = await _chatController!.sendImageFromGallery();

    if (success) {
      // Scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to send image')));
      }
    }
  }

  /// Send image from camera
  Future<void> _sendImageFromCamera() async {
    if (_chatController == null) return;

    final success = await _chatController!.sendImageFromCamera();

    if (success) {
      // Scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to send image')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatController = context.watch<ChatController>();
    final authController = context.watch<AuthController>();
    final messages = chatController.messages;
    final currentUserId = authController.currentUserId ?? '';

    // Auto-scroll when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (messages.isNotEmpty) _scrollToBottom();
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: _buildAppBarTitle(),
        actions: [
          // Search icon
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _toggleSearch,
            ),

          // More menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'export_pdf',
                    child: ListTile(
                      leading: Icon(Icons.picture_as_pdf),
                      title: Text('Export to PDF'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear',
                    child: ListTile(
                      leading: Icon(Icons.delete_sweep),
                      title: Text('Clear Chat'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar (shown when searching)
          if (_isSearching) _buildSearchBar(),

          // Messages list
          Expanded(
            child:
                messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 16,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isSent = message.senderId == currentUserId;
                        final time = Helpers.formatTime(message.time);

                        // Show ImageMessage widget for image messages
                        if (message.isImageMessage) {
                          return ImageMessage(
                            imageUrl: message.imageUrl!,
                            isSent: isSent,
                            caption: message.hasText ? message.text : null,
                            time: time,
                          );
                        }

                        // Show ChatBubble for text messages
                        return ChatBubble(
                          message: message,
                          isSent: isSent,
                          onLongPress: () => _showMessageOptions(message.id),
                        );
                      },
                    ),
          ),

          // Message input with image support
          MessageInputField(
            controller: _messageController,
            focusNode: _focusNode,
            isSending: chatController.isSending,
            onSend: _sendMessage,
            onImagePick: _showImagePickerDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarTitle() {
    return GestureDetector(
      onTap: () {
        if (_otherUserId != null) {
          Navigator.pushNamed(
            context,
            kRouteContactInfo,
            arguments: _otherUserId,
          );
        }
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: kPrimaryLightColor,
            backgroundImage:
                _otherUser?.photoUrl != null
                    ? NetworkImage(_otherUser!.photoUrl!)
                    : null,
            child:
                _otherUser?.photoUrl == null
                    ? Text(
                      _otherUser?.initials ?? '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                    : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _otherUser?.fullName ?? 'Loading...',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '@${_otherUser?.username ?? '...'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text('Say hello! 👋', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  /// Toggle search mode
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchResults.clear();
        _searchController.clear();
      }
    });
  }

  /// Build search bar
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: kPrimaryColor.withOpacity(0.1),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search in messages...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch('');
                          },
                        )
                        : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onChanged: _performSearch,
            ),
          ),
          const SizedBox(width: 8),
          // Navigation buttons when results exist
          if (_searchResults.isNotEmpty) ...[
            Text(
              '${_currentSearchIndex + 1}/${_searchResults.length}',
              style: const TextStyle(fontSize: 12),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up),
              onPressed: _previousSearchResult,
              tooltip: 'Previous',
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: _nextSearchResult,
              tooltip: 'Next',
            ),
          ],
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _toggleSearch,
            tooltip: 'Close search',
          ),
        ],
      ),
    );
  }

  /// Perform search in messages
  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _currentSearchIndex = 0;

      if (_searchQuery.isEmpty) {
        _searchResults.clear();
        return;
      }

      final chatController = context.read<ChatController>();
      final messages = chatController.messages;

      _searchResults =
          messages
              .where((msg) => msg.text.toLowerCase().contains(_searchQuery))
              .toList();
    });
  }

  /// Navigate to next search result
  void _nextSearchResult() {
    if (_searchResults.isEmpty) return;
    setState(() {
      _currentSearchIndex = (_currentSearchIndex + 1) % _searchResults.length;
    });
    // TODO: Scroll to message
  }

  /// Navigate to previous search result
  void _previousSearchResult() {
    if (_searchResults.isEmpty) return;
    setState(() {
      _currentSearchIndex =
          (_currentSearchIndex - 1 + _searchResults.length) %
          _searchResults.length;
    });
    // TODO: Scroll to message
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export_pdf':
        _showExportPDFDialog();
        break;
      case 'clear':
        _clearChat();
        break;
    }
  }

  /// Show PDF export options dialog
  void _showExportPDFDialog() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Export Chat to PDF',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.all_inclusive),
                  title: const Text('Export all messages'),
                  onTap: () {
                    Navigator.pop(context);
                    _exportPDF();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.date_range),
                  title: const Text('Export date range'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDateRangePicker();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );
  }

  /// Show date range picker for PDF export
  Future<void> _showDateRangePicker() async {
    final chatController = context.read<ChatController>();
    final messages = chatController.messages;

    if (messages.isEmpty) {
      Helpers.showSnackBar(context, 'No messages to export');
      return;
    }

    // Get date range
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: messages.last.time,
      lastDate: messages.first.time,
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: ColorScheme.light(primary: kPrimaryColor)),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _exportPDF(startDate: picked.start, endDate: picked.end);
    }
  }

  /// Export chat to PDF
  Future<void> _exportPDF({DateTime? startDate, DateTime? endDate}) async {
    final chatController = context.read<ChatController>();
    final authController = context.read<AuthController>();
    final messages = chatController.messages;

    if (messages.isEmpty) {
      Helpers.showSnackBar(context, 'No messages to export');
      return;
    }

    if (_otherUser == null || authController.currentUser == null) {
      Helpers.showSnackBar(context, 'Unable to export chat');
      return;
    }

    // Show loading
    Helpers.showLoadingDialog(context, message: 'Generating PDF...');

    try {
      final filePath = await _pdfService.generateChatPDF(
        messages: messages,
        currentUser: authController.currentUser!,
        otherUser: _otherUser!,
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading

        // Show success with options
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('PDF Exported Successfully'),
                content: Text('File saved to:\n$filePath'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Share file (would need share_plus package)
                      Helpers.showSnackBar(
                        context,
                        'Open file manager to share',
                      );
                    },
                    child: const Text('Share'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        Helpers.showSnackBar(context, 'Error exporting PDF: $e');
      }
    }
  }

  Future<void> _clearChat() async {
    final confirmed = await Helpers.showConfirmDialog(
      context,
      title: 'Clear Chat',
      message: 'Are you sure you want to delete all messages?',
      confirmText: 'Clear',
      isDangerous: true,
    );

    if (confirmed && _chatId != null) {
      await context.read<ChatController>().deleteChat(_chatId!);
      if (mounted) Navigator.pop(context);
    }
  }

  void _showMessageOptions(String messageId) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy'),
                onTap: () {
                  Navigator.pop(context);
                  Helpers.showSnackBar(context, 'Message copied');
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: kErrorColor),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: kErrorColor),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await context.read<ChatController>().deleteMessage(messageId);
                },
              ),
            ],
          ),
    );
  }

  void _showFullImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              body: Center(
                child: InteractiveViewer(child: Image.network(imageUrl)),
              ),
            ),
      ),
    );
  }
}
