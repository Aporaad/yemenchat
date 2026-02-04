// =============================================================================
// YemenChat - Contact Screen
// =============================================================================
// Screen showing all registered users.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../controllers/contact_controller.dart';
import '../utils/constants.dart';
import '../widgets/user_card.dart';
import '../widgets/input_field.dart';

/// Screen displaying all contacts
class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initController();
    });
  }

  void _initController() {
    final authController = context.read<AuthController>();
    final contactController = context.read<ContactController>();

    if (authController.currentUserId != null) {
      contactController.initialize(authController.currentUserId!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contactController = context.watch<ContactController>();
    final contacts = contactController.contacts;

    // If used as standalone screen (not in bottom nav)
    final isStandalone =
        ModalRoute.of(context)?.settings.name == kRouteContacts;

    return Scaffold(
      appBar:
          isStandalone
              ? AppBar(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                title:
                    _isSearching
                        ? TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Search contacts...',
                            hintStyle: TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                          ),
                          onChanged: contactController.searchContacts,
                        )
                        : const Text('Select Contact'),
                actions: [
                  IconButton(
                    icon: Icon(_isSearching ? Icons.close : Icons.search),
                    onPressed: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) {
                          _searchController.clear();
                          contactController.clearSearch();
                        }
                      });
                    },
                  ),
                ],
              )
              : null,
      body: Column(
        children: [
          // Search bar (when embedded in home)
          if (!isStandalone)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SearchField(
                controller: _searchController,
                hint: 'Search contacts...',
                onChanged: contactController.searchContacts,
                onClear: contactController.clearSearch,
              ),
            ),

          // Contacts list
          Expanded(child: _buildContactsList(contactController, contacts)),
        ],
      ),
    );
  }

  Widget _buildContactsList(ContactController controller, List contacts) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No contacts found',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.refreshContacts,
      child: ListView.separated(
        itemCount: contacts.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final user = contacts[index];
          final isFavorite = controller.isFavorite(user.id);

          return ContactCard(
            user: user,
            onTap: () => _startChat(user.id),
            onAvatarTap: () => _openContactInfo(user.id),
            trailing: IconButton(
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_outline,
                color: isFavorite ? kAccentColor : Colors.grey,
              ),
              onPressed: () => controller.toggleFavorite(user.id),
            ),
          );
        },
      ),
    );
  }

  Future<void> _startChat(String userId) async {
    final chatController = context.read<ChatController>();
    final authController = context.read<AuthController>();
    final chat = await chatController.openChat(
      userId,
      currentUserId: authController.currentUserId,
    );

    if (chat != null && mounted) {
      Navigator.pushNamed(
        context,
        kRouteChat,
        arguments: {'chatId': chat.id, 'userId': userId},
      );
    }
  }

  void _openContactInfo(String userId) {
    Navigator.pushNamed(context, kRouteContactInfo, arguments: userId);
  }
}
