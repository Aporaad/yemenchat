// =============================================================================
// YemenChat - Home Screen
// =============================================================================
// Main home screen with chat list, bottom navigation, and drawer.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../models/chat_model.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/user_card.dart';
import '../../widgets/input_field.dart';
import '../contacts/contact_screen.dart';
import '../favorites/favorites_screen.dart';

/// Main home screen with bottom navigation
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Bottom navigation index
  int _currentIndex = 0;

  // Page views
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const _ChatsTab(),
      const ContactScreen(),
      const FavoritesScreen(),
    ];
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initControllers();
    });
  }

  /// Initialize controllers with current user ID
  void _initControllers() {
    final authController = context.read<AuthController>();
    final chatController = context.read<ChatController>();

    if (authController.currentUserId != null) {
      chatController.initialize(authController.currentUserId!);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final user = authController.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        title: Text(
          user != null ? 'Hi, ${user.firstName}!' : kAppName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          // More options
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'new_chat',
                    child: ListTile(
                      leading: Icon(Icons.chat_bubble_outline),
                      title: Text('New Chat'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: ListTile(
                      leading: Icon(Icons.settings_outlined),
                      title: Text('Settings'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
          ),
        ],
      ),
      drawer: _buildDrawer(context, user),
      body: IndexedStack(index: _currentIndex, children: _pages),
      floatingActionButton:
          _currentIndex == 0
              ? FloatingActionButton(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                onPressed: () => Navigator.pushNamed(context, kRouteContacts),
                child: const Icon(Icons.chat),
              )
              : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.contacts_outlined),
            selectedIcon: Icon(Icons.contacts),
            label: 'Contacts',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_outline),
            selectedIcon: Icon(Icons.star),
            label: 'Favorites',
          ),
        ],
      ),
    );
  }

  /// Build navigation drawer
  Widget _buildDrawer(BuildContext context, dynamic user) {
    final settingsController = context.watch<SettingsController>();

    return Drawer(
      child: Column(
        children: [
          // User header
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: kPrimaryColor),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage:
                  user?.photoUrl != null
                      ? CachedNetworkImageProvider(user.photoUrl!)
                      : null,
              child:
                  user?.photoUrl == null
                      ? Text(
                        user?.initials ?? '?',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      )
                      : null,
            ),
            accountName: Text(
              user?.fullName ?? 'User',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text('@${user?.username ?? 'unknown'}'),
          ),

          // Menu items
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, kRouteProfile);
            },
          ),

          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, kRouteSettings);
            },
          ),

          const Divider(),

          // Theme toggle
          SwitchListTile(
            secondary: Icon(
              settingsController.isDarkMode
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            title: const Text('Dark Mode'),
            value: settingsController.isDarkMode,
            onChanged: (_) => settingsController.toggleDarkMode(),
          ),

          const Spacer(),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: kErrorColor),
            title: const Text('Logout', style: TextStyle(color: kErrorColor)),
            onTap: () => _handleLogout(),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Handle menu actions
  void _handleMenuAction(String action) {
    switch (action) {
      case 'new_chat':
        Navigator.pushNamed(context, kRouteContacts);
        break;
      case 'settings':
        Navigator.pushNamed(context, kRouteSettings);
        break;
    }
  }

  /// Handle logout
  Future<void> _handleLogout() async {
    final confirmed = await Helpers.showConfirmDialog(
      context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmText: 'Logout',
      isDangerous: true,
    );

    if (!confirmed) return;

    Navigator.pop(context); // Close drawer
    await context.read<AuthController>().signOut();

    if (mounted) {
      Helpers.navigateClearAll(context, kRouteWelcome);
    }
  }
}

/// Chats tab showing list of conversations
class _ChatsTab extends StatefulWidget {
  const _ChatsTab();

  @override
  State<_ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<_ChatsTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatController = context.watch<ChatController>();
    final authController = context.watch<AuthController>();

    if (chatController.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final chats = chatController.chats;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SearchField(
            controller: _searchController,
            hint: 'Search chats...',
            autofocus: false,
            onChanged: (query) {
              chatController.searchChats(query);
            },
            onClear: () {
              chatController.clearSearch();
            },
          ),
        ),

        // Chats list
        Expanded(
          child:
              chats.isEmpty
                  ? Center(
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
                          'No conversations yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start chatting with your contacts!',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                  : _buildChatsList(chats, authController, chatController),
        ),
      ],
    );
  }

  Widget _buildChatsList(
    List<ChatModel> chats,
    AuthController authController,
    ChatController chatController,
  ) {
    return ListView.separated(
      itemCount: chats.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final chat = chats[index];
        final currentUserId = authController.currentUserId ?? '';
        final otherUserId = chat.getOtherUserId(currentUserId);
        final otherUser = chatController.getCachedUser(otherUserId);

        if (otherUser == null) {
          // Load user data if not cached
          chatController.getUser(otherUserId);
          return const SizedBox.shrink();
        }

        return UserCard(
          user: otherUser,
          subtitle: chat.lastMessage,
          trailingText: Helpers.formatChatDate(chat.lastTime),
          badgeCount: chat.getUnreadCount(currentUserId),
          isPinned: chat.isPinnedForUser(currentUserId),
          onTap: () => _openChat(context, chat.id, otherUserId),
          onAvatarTap: () => _openContactInfo(context, otherUserId),
          onLongPress: () => _showChatOptions(context, chat),
        );
      },
    );
  }

  void _openChat(BuildContext context, String chatId, String otherUserId) {
    // Simply navigate to the chat screen with the existing chatId
    Navigator.pushNamed(
      context,
      kRouteChat,
      arguments: {'chatId': chatId, 'userId': otherUserId},
    );
  }

  void _openContactInfo(BuildContext context, String userId) {
    Navigator.pushNamed(context, kRouteContactInfo, arguments: userId);
  }

  void _showChatOptions(BuildContext context, ChatModel chat) {
    final chatController = context.read<ChatController>();
    final currentUserId = context.read<AuthController>().currentUserId ?? '';
    final isPinned = chat.isPinnedForUser(currentUserId);

    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                ),
                title: Text(isPinned ? 'Unpin Chat' : 'Pin Chat'),
                onTap: () {
                  Navigator.pop(context);
                  chatController.togglePin(chat.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: kErrorColor),
                title: const Text(
                  'Delete Chat',
                  style: TextStyle(color: kErrorColor),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmed = await Helpers.showConfirmDialog(
                    context,
                    title: 'Delete Chat',
                    message: 'Are you sure you want to delete this chat?',
                    confirmText: 'Delete',
                    isDangerous: true,
                  );
                  if (confirmed) {
                    chatController.deleteChat(chat.id);
                  }
                },
              ),
            ],
          ),
    );
  }
}
