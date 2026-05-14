import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sprint_14/components/app_network_image.dart';
import 'package:sprint_14/models/user_model.dart';
import 'package:sprint_14/providers/auth_provider/auth_provider.dart';
import 'package:sprint_14/providers/user_provider/user_provider.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  late TextEditingController _nameController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    // Initialize controller with current name from provider
    final user = ref.read(userProvider).value;
    _nameController = TextEditingController(text: user?.name ?? "");
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage(UserModel user) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      await ref
          .read(userProvider.notifier)
          .updateProfile(user, imageFile: File(pickedFile.path));
    }
  }

  Future<void> _handleUpdateName(UserModel user) async {
    if (_nameController.text.trim().isEmpty) return;

    final updatedUser = user.copyWith(name: _nameController.text.trim());

    await ref.read(userProvider.notifier).updateProfile(updatedUser);

    setState(() => _isEditing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userState = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: userState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
        data: (user) {
          if (user == null) {
            return const Center(child: Text("No user data found"));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Avatar Section
                _buildAvatar(theme, user),
                const SizedBox(height: 32),

                // Personal Info Section
                _buildSectionLabel(theme, "Personal Information"),
                const SizedBox(height: 12),
                _buildEditableTile(
                  theme,
                  label: "Full Name",
                  controller: _nameController,
                  icon: Icons.person_outline_rounded,
                  isEditing: _isEditing,
                  onEditPressed: () => setState(() => _isEditing = true),
                  onSavePressed: () => _handleUpdateName(user),
                ),

                const SizedBox(height: 16),
                _buildReadOnlyTile(
                  theme,
                  label: "Email Address",
                  value: user.email,
                  icon: Icons.email_outlined,
                ),

                const SizedBox(height: 32),

                // Security Section
                _buildSectionLabel(theme, "Security"),
                const SizedBox(height: 12),
                _buildActionTile(
                  theme,
                  label: "Change Password",
                  subtitle: "Send a reset link to your email",
                  icon: Icons.lock_reset_rounded,
                  onTap: () {
                    ref
                        .read(authControllerProvider.notifier)
                        .passwordReset(user.email);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Reset link sent to your email!"),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- UI Components ---

  Widget _buildAvatar(ThemeData theme, UserModel user) {
    return Column(
      children: [
        Stack(
          children: [
            // The Outer Border ring
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              // 🔥 Using your Unified Image Widget
              child: AppNetworkImage(
                path: user.profilePic,
                size: 120, // radius 60 * 2 = 120
                isCircle: true,
                fallbackLetter: user.name.isNotEmpty ? user.name[0] : "U",
              ),
            ),

            // Camera Action Button
            Positioned(
              bottom: 4, // Adjusted slightly for the padding
              right: 4,
              child: GestureDetector(
                onTap: () => _pickAndUploadImage(user),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.primary,
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Sync Status
        if (!user.isSynced)
          Chip(
            visualDensity: VisualDensity.compact,
            label: const Text(
              "PENDING SYNC",
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            avatar: SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            side: BorderSide.none,
            shape: StadiumBorder(),
          ),
      ],
    );
  }

  Widget _buildSectionLabel(ThemeData theme, String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEditableTile(
    ThemeData theme, {
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isEditing,
    required VoidCallback onEditPressed,
    required VoidCallback onSavePressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                TextField(
                  controller: controller,
                  enabled: isEditing,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: isEditing ? onSavePressed : onEditPressed,
            icon: Icon(
              isEditing ? Icons.check_circle_rounded : Icons.edit_rounded,
              color: isEditing ? Colors.green : theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyTile(
    ThemeData theme, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    ThemeData theme, {
    required String label,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}
