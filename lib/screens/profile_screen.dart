// =============================================================================
// YemenChat - Profile Screen
// =============================================================================
// User profile screen with edit options.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../utils/helpers.dart';
import '../widgets/input_field.dart';
import '../widgets/custom_button.dart';

/// User profile screen
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  void _loadProfile() {
    final authController = context.read<AuthController>();
    final profileController = context.read<ProfileController>();

    if (authController.currentUserId != null) {
      profileController.loadProfile(authController.currentUserId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileController = context.watch<ProfileController>();
    final user = profileController.user;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditProfile(),
          ),
        ],
      ),
      body:
          profileController.isLoading
              ? const Center(child: CircularProgressIndicator())
              : user == null
              ? const Center(child: Text('Failed to load profile'))
              : RefreshIndicator(
                onRefresh: profileController.refreshProfile,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Profile photo
                    _buildProfilePhoto(profileController),

                    const SizedBox(height: 24),

                    // User info card
                    _buildInfoCard(user),

                    const SizedBox(height: 24),

                    // Action buttons
                    _buildActionsList(),
                  ],
                ),
              ),
    );
  }

  Widget _buildProfilePhoto(ProfileController controller) {
    final user = controller.user!;

    return Center(
      child: Stack(
        children: [
          // Photo
          CircleAvatar(
            radius: 60,
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
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                    : null,
          ),

          // Edit button
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _showPhotoOptions(controller),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child:
                    controller.isUploadingPhoto
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                        : const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(dynamic user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(Icons.person, 'Full Name', user.fullName),
            const Divider(),
            _buildInfoRow(
              Icons.alternate_email,
              'Username',
              '@${user.username}',
            ),
            const Divider(),
            _buildInfoRow(Icons.email_outlined, 'Email', user.email),
            const Divider(),
            _buildInfoRow(Icons.phone_outlined, 'Phone', user.phone),
            const Divider(),
            _buildInfoRow(
              Icons.calendar_today,
              'Member Since',
              Helpers.formatFullDate(user.createdAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: kPrimaryColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsList() {
    return Column(
      children: [
        _buildActionTile(
          icon: Icons.lock_outline,
          title: 'Change Password',
          onTap: () => _showChangePassword(),
        ),
        _buildActionTile(
          icon: Icons.security,
          title: 'Security Logs',
          onTap: () => _showSecurityLogs(),
        ),
        _buildActionTile(
          icon: Icons.delete_outline,
          title: 'Delete Account',
          color: kErrorColor,
          onTap: () => _showDeleteAccount(),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: Icon(Icons.chevron_right, color: color),
      onTap: onTap,
    );
  }

  void _showPhotoOptions(ProfileController controller) {
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
                  onTap: () async {
                    Navigator.pop(context);
                    final success = await controller.updatePhotoFromGallery();
                    if (!success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            controller.errorMessage ?? 'Failed to upload photo',
                          ),
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: kPrimaryColor),
                  title: const Text('Take a Photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    final success = await controller.updatePhotoFromCamera();
                    if (!success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            controller.errorMessage ?? 'Failed to upload photo',
                          ),
                        ),
                      );
                    }
                  },
                ),
                if (controller.user?.photoUrl != null)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Remove Photo'),
                    onTap: () async {
                      Navigator.pop(context);
                      final success = await controller.removePhoto();
                      if (!success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to remove photo'),
                          ),
                        );
                      }
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

  void _showEditProfile() {
    final profileController = context.read<ProfileController>();
    final user = profileController.user;
    if (user == null) return;

    final nameController = TextEditingController(text: user.fullName);
    final phoneController = TextEditingController(text: user.phone);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Profile'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InputField(
                    controller: nameController,
                    label: 'Full Name',
                    prefixIcon: Icons.person_outline,
                    validator: Validators.validateFullName,
                  ),
                  const SizedBox(height: 16),
                  InputField(
                    controller: phoneController,
                    label: 'Phone',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: Validators.validatePhone,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  Navigator.pop(context);

                  final success = await profileController.updateProfile(
                    fullName: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                  );

                  if (mounted) {
                    if (success) {
                      Helpers.showSuccessSnackBar(context, 'Profile updated');
                    } else {
                      Helpers.showErrorSnackBar(
                        context,
                        profileController.errorMessage ?? 'Update failed',
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showChangePassword() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Change Password'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InputField(
                    controller: currentController,
                    label: 'Current Password',
                    isPassword: true,
                    validator: Validators.validatePassword,
                  ),
                  const SizedBox(height: 16),
                  InputField(
                    controller: newController,
                    label: 'New Password',
                    isPassword: true,
                    validator: Validators.validateStrongPassword,
                  ),
                  const SizedBox(height: 16),
                  InputField(
                    controller: confirmController,
                    label: 'Confirm Password',
                    isPassword: true,
                    validator:
                        (v) => Validators.validateConfirmPassword(
                          v,
                          newController.text,
                        ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  final profileController = context.read<ProfileController>();
                  final success = await profileController.changePassword(
                    currentPassword: currentController.text,
                    newPassword: newController.text,
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    if (success) {
                      Helpers.showSuccessSnackBar(context, 'Password changed');
                    } else {
                      Helpers.showErrorSnackBar(
                        context,
                        profileController.errorMessage ?? 'Change failed',
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
                child: const Text('Change'),
              ),
            ],
          ),
    );
  }

  void _showSecurityLogs() async {
    final profileController = context.read<ProfileController>();
    await profileController.loadSecurityLogs();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            builder:
                (context, scrollController) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Security Logs',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Expanded(
                      child:
                          profileController.securityLogs.isEmpty
                              ? const Center(child: Text('No security logs'))
                              : ListView.builder(
                                controller: scrollController,
                                itemCount:
                                    profileController.securityLogs.length,
                                itemBuilder: (context, index) {
                                  final log =
                                      profileController.securityLogs[index];
                                  return ListTile(
                                    leading: Icon(
                                      _getLogIcon(log.action.name),
                                      color: kPrimaryColor,
                                    ),
                                    title: Text(log.actionDescription),
                                    subtitle: Text(
                                      Helpers.formatLogDate(log.timestamp),
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
          ),
    );
  }

  IconData _getLogIcon(String action) {
    switch (action) {
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      case 'password_change':
        return Icons.lock;
      default:
        return Icons.security;
    }
  }

  void _showDeleteAccount() async {
    final confirmed = await Helpers.showConfirmDialog(
      context,
      title: 'Delete Account',
      message:
          'Are you sure you want to delete your account? This action cannot be undone.',
      confirmText: 'Delete',
      isDangerous: true,
    );

    if (!confirmed) return;

    if (!mounted) return;

    // Show password dialog
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Password'),
            content: InputField(
              controller: passwordController,
              label: 'Password',
              isPassword: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final profileController = context.read<ProfileController>();
                  final success = await profileController.deleteAccount(
                    passwordController.text,
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    if (success) {
                      Helpers.navigateClearAll(context, kRouteWelcome);
                    } else {
                      Helpers.showErrorSnackBar(
                        context,
                        profileController.errorMessage ?? 'Delete failed',
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: kErrorColor),
                child: const Text('Delete Account'),
              ),
            ],
          ),
    );
  }
}
