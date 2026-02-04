// =============================================================================
// YemenChat - Favorites Screen
// =============================================================================
// Screen showing favorite contacts.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../controllers/contact_controller.dart';
import '../utils/constants.dart';
import '../widgets/user_card.dart';

/// Screen displaying favorite contacts
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
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
  Widget build(BuildContext context) {
    final contactController = context.watch<ContactController>();
    final favorites = contactController.favorites;

    if (contactController.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_outline, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No favorites yet',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Star contacts to add them here',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: contactController.refreshContacts,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: favorites.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final user = favorites[index];

          return ContactCard(
            user: user,
            onTap: () => _startChat(user.id),
            onAvatarTap: () => _openContactInfo(user.id),
            trailing: IconButton(
              icon: const Icon(Icons.star, color: kAccentColor),
              onPressed: () => contactController.removeFromFavorites(user.id),
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
