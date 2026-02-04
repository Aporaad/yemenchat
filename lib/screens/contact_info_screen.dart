// =============================================================================
// YemenChat - Contact Info Screen
// =============================================================================
// Screen showing detailed contact information.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../controllers/contact_controller.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Contact info screen showing user details
class ContactInfoScreen extends StatefulWidget {
  const ContactInfoScreen({super.key});

  @override
  State<ContactInfoScreen> createState() => _ContactInfoScreenState();
}

class _ContactInfoScreenState extends State<ContactInfoScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  UserModel? _user;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userId = ModalRoute.of(context)?.settings.arguments as String?;
    if (userId == null) return;

    setState(() => _isLoading = true);
    _user = await _firestoreService.getUserById(userId);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final contactController = context.watch<ContactController>();

    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _user == null
              ? const Center(child: Text('User not found'))
              : CustomScrollView(
                slivers: [
                  // App bar with photo
                  _buildSliverAppBar(),

                  // Content
                  SliverToBoxAdapter(child: _buildContent(contactController)),
                ],
              ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _user!.fullName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
          ),
        ),
        background:
            _user!.photoUrl != null
                ? CachedNetworkImage(
                  imageUrl: _user!.photoUrl!,
                  fit: BoxFit.cover,
                  color: Colors.black.withValues(alpha: 0.3),
                  colorBlendMode: BlendMode.darken,
                )
                : Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [kPrimaryColor, kPrimaryDarkColor],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _user!.initials,
                      style: const TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showMoreOptions(),
        ),
      ],
    );
  }

  Widget _buildContent(ContactController contactController) {
    final isFavorite = contactController.isFavorite(_user!.id);
    final isBlocked = contactController.isBlocked(_user!.id);

    return Column(
      children: [
        const SizedBox(height: 16),

        // Quick actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.chat,
                label: 'Message',
                onTap: () => _startChat(),
              ),
              _buildActionButton(
                icon: isFavorite ? Icons.star : Icons.star_outline,
                label: isFavorite ? 'Favorited' : 'Favorite',
                color: isFavorite ? kAccentColor : null,
                onTap: () => contactController.toggleFavorite(_user!.id),
              ),
              _buildActionButton(
                icon: isBlocked ? Icons.block : Icons.block_outlined,
                label: isBlocked ? 'Blocked' : 'Block',
                color: isBlocked ? kErrorColor : null,
                onTap: () => _toggleBlock(contactController, isBlocked),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        const Divider(),

        // User info
        _buildInfoTile(
          icon: Icons.person_outline,
          title: 'Username',
          value: '@${_user!.username}',
        ),
        _buildInfoTile(
          icon: Icons.email_outlined,
          title: 'Email',
          value: _user!.email,
        ),
        _buildInfoTile(
          icon: Icons.phone_outlined,
          title: 'Phone',
          value: _user!.phone,
        ),
        _buildInfoTile(
          icon: Icons.calendar_today_outlined,
          title: 'Joined',
          value: Helpers.formatFullDate(_user!.createdAt),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (color ?? kPrimaryColor).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color ?? kPrimaryColor, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: kPrimaryColor),
      title: Text(
        title,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
    );
  }

  Future<void> _startChat() async {
    final chatController = context.read<ChatController>();
    final chat = await chatController.openChat(_user!.id);

    if (chat != null && mounted) {
      Navigator.pushNamed(
        context,
        kRouteChat,
        arguments: {'chatId': chat.id, 'userId': _user!.id},
      );
    }
  }

  Future<void> _toggleBlock(
    ContactController controller,
    bool isBlocked,
  ) async {
    if (isBlocked) {
      await controller.unblockUser(_user!.id);
      if (mounted) {
        Helpers.showSuccessSnackBar(context, 'User unblocked');
      }
    } else {
      final confirmed = await Helpers.showConfirmDialog(
        context,
        title: 'Block User',
        message: 'Are you sure you want to block ${_user!.fullName}?',
        confirmText: 'Block',
        isDangerous: true,
      );

      if (confirmed) {
        await controller.blockUser(_user!.id);
        if (mounted) {
          Helpers.showSnackBar(context, 'User blocked');
        }
      }
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Share Contact'),
                onTap: () {
                  Navigator.pop(context);
                  Helpers.showSnackBar(context, 'Share coming soon!');
                },
              ),
              ListTile(
                leading: const Icon(Icons.report_outlined, color: kErrorColor),
                title: const Text(
                  'Report User',
                  style: TextStyle(color: kErrorColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Helpers.showSnackBar(context, 'Report submitted');
                },
              ),
            ],
          ),
    );
  }
}
