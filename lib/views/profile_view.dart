import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sprint_14/components/app_network_image.dart';
import 'package:sprint_14/helpers/theme_widgets.dart';
import 'package:sprint_14/models/user_model.dart';
import 'package:sprint_14/providers/auth_provider/auth_provider.dart';
import 'package:sprint_14/providers/business_provider/business_provider.dart';
import 'package:sprint_14/providers/current_user_provider/current_user_provider.dart';
import 'package:sprint_14/providers/event_ledger_provider/event_ledger_provider.dart';
import 'package:sprint_14/providers/ledger_provider/ledger_provider.dart';
import 'package:sprint_14/services/auth_service.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  bool _uploadingPhoto = false;
  bool _syncing = false;

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------------------------------------------------------------- photo

  Future<void> _showPhotoOptions(UserModel user) async {
    final theme = Theme.of(context);
    final hasPhoto = (user.profilePic ?? '').isNotEmpty;

    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: theme.colorScheme.surface,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(sheetContext, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(sheetContext, 'gallery'),
            ),
            if (hasPhoto)
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  'Remove photo',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () => Navigator.pop(sheetContext, 'remove'),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;

    if (choice == 'remove') {
      await ref.read(currentUserProvider.notifier).removeProfilePicture();
      _snack('Photo removed');
      return;
    }

    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
    } on PlatformException catch (e) {
      _snack(
        e.code.contains('denied')
            ? 'Permission denied. Allow access in your phone settings.'
            : "Couldn't open the ${choice == 'camera' ? 'camera' : 'gallery'}.",
      );
      return;
    }
    if (picked == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    final uploaded = await ref
        .read(currentUserProvider.notifier)
        .updateProfilePicture(File(picked.path));
    if (!mounted) return;
    setState(() => _uploadingPhoto = false);
    _snack(
      uploaded
          ? 'Profile photo updated'
          : 'Photo saved. It will upload when you are back online.',
    );
  }

  // ---------------------------------------------------------------- name

  Future<void> _editName(UserModel user) async {
    final newName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditNameSheet(initial: user.name),
    );
    if (newName == null || newName == user.name || !mounted) return;
    await ref.read(currentUserProvider.notifier).updateName(newName);
    _snack('Name updated');
  }

  // ---------------------------------------------------------------- account

  Future<void> _sendPasswordReset(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change password?'),
        content: Text(
          "We'll email a password reset link to ${user.email}. "
          'Open it to choose a new password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Send link'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      // Called on the service directly: going through the auth controller
      // put the whole app into a "loading" state for a moment.
      await AuthService().resetPassword(user.email);
      _snack('Reset link sent to ${user.email}');
    } catch (e) {
      _snack(e is String ? e : "Couldn't send the link. Try again later.");
    }
  }

  Future<void> _resendVerification() async {
    try {
      await AuthService().resendVerificationEmail();
      _snack('Verification email sent');
    } catch (_) {
      _snack("Couldn't send the email. Try again later.");
    }
  }

  Future<void> _syncNow() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    await ref.read(currentUserProvider.notifier).syncPendingData();
    if (!mounted) return;
    setState(() => _syncing = false);
    final synced = ref.read(currentUserProvider).value?.isSynced ?? false;
    _snack(
      synced
          ? 'Profile synced'
          : "Couldn't sync yet. Check your connection and try again.",
    );
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: userState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Couldn't load profile: $err")),
        data: (user) {
          if (user == null) {
            return const Center(child: Text("No profile found"));
          }
          return RefreshIndicator(
            onRefresh: _syncNow,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _ProfileHeader(
                  user: user,
                  uploading: _uploadingPhoto,
                  syncing: _syncing,
                  onPhoto: () => _showPhotoOptions(user),
                  onSync: _syncNow,
                ),
                const SizedBox(height: 24),
                const _SectionHeader('Personal information'),
                _Group(
                  children: [
                    _Tile(
                      icon: Icons.person_outline_rounded,
                      label: 'Full name',
                      value: user.name.isEmpty ? 'Add your name' : user.name,
                      trailing: const Icon(Icons.edit_outlined, size: 20),
                      onTap: () => _editName(user),
                    ),
                    _Tile(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user.email,
                      trailing: IconButton(
                        tooltip: 'Copy email',
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: user.email));
                          _snack('Email copied');
                        },
                      ),
                    ),
                    _VerificationTile(
                      // Firebase Auth is the source of truth; the profile
                      // document's flag can lag behind.
                      verified:
                          ref
                              .watch(authControllerProvider)
                              .value
                              ?.emailVerified ??
                          user.isEmailVerified,
                      onResend: _resendVerification,
                    ),
                    _Tile(
                      icon: Icons.calendar_month_outlined,
                      label: 'Member since',
                      value: DateFormat('d MMMM yyyy').format(user.createdAt),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _SectionHeader('Your activity'),
                const _ActivityRow(),
                const SizedBox(height: 24),
                const _SectionHeader('Security'),
                _Group(
                  children: [
                    _Tile(
                      icon: Icons.lock_reset_rounded,
                      label: 'Change password',
                      value: 'Get a reset link by email',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _sendPasswordReset(user),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// =========================================================================
// HEADER
// =========================================================================

class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  final bool uploading;
  final bool syncing;
  final VoidCallback onPhoto;
  final VoidCallback onSync;

  const _ProfileHeader({
    required this.user,
    required this.uploading,
    required this.syncing,
    required this.onPhoto,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final on = cs.onPrimary;
    final name = user.name.trim().isEmpty ? 'User' : user.name.trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, Color.lerp(cs.primary, Colors.black, 0.28)!],
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: uploading ? null : onPhoto,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: on.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: AppNetworkImage(
                    path: user.profilePic,
                    size: 108,
                    isCircle: true,
                    fallbackLetter: name.characters.first.toUpperCase(),
                  ),
                ),
                if (uploading)
                  Container(
                    width: 116,
                    height: 116,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black45,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: on,
                      border: Border.all(color: cs.primary, width: 2),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: cs.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: on,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            user.email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: on.withValues(alpha: 0.8), fontSize: 13),
          ),
          if (!user.isSynced) ...[
            const SizedBox(height: 12),
            Material(
              color: on.withValues(alpha: 0.15),
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: syncing ? null : onSync,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      syncing
                          ? SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: on,
                              ),
                            )
                          : Icon(Icons.cloud_off_rounded, size: 14, color: on),
                      const SizedBox(width: 6),
                      Text(
                        syncing ? 'Syncing…' : 'Not synced · Tap to retry',
                        style: TextStyle(
                          color: on,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =========================================================================
// ACTIVITY
// =========================================================================

class _ActivityRow extends ConsumerWidget {
  const _ActivityRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgers = ref.watch(ledgerProvider).value?.length;
    final events = ref.watch(eventLedgerProvider).value?.length;
    final businesses = ref.watch(businessProvider).value?.length;

    return Row(
      children: [
        _stat(context, Icons.receipt_long_rounded, ledgers, 'Transactions'),
        const SizedBox(width: 10),
        _stat(context, Icons.groups_rounded, events, 'Event ledgers'),
        const SizedBox(width: 10),
        _stat(context, Icons.storefront_rounded, businesses, 'Businesses'),
      ],
    );
  }

  Widget _stat(BuildContext context, IconData icon, int? value, String label) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value?.toString() ?? '–',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: theme.hintColor),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// BUILDING BLOCKS
// =========================================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 56,
                color: theme.dividerColor.withValues(alpha: 0.15),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _Tile({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        label,
        style: TextStyle(fontSize: 12, color: theme.hintColor),
      ),
      subtitle: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
      trailing: trailing,
    );
  }
}

class _VerificationTile extends StatelessWidget {
  final bool verified;
  final VoidCallback onResend;
  const _VerificationTile({required this.verified, required this.onResend});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = verified
        ? positiveMoneyColor(theme)
        : theme.colorScheme.error;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(
        verified ? Icons.verified_rounded : Icons.error_outline_rounded,
        color: color,
      ),
      title: Text(
        'Email verification',
        style: TextStyle(fontSize: 12, color: theme.hintColor),
      ),
      subtitle: Text(
        verified ? 'Verified' : 'Not verified',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      trailing: verified
          ? null
          : TextButton(onPressed: onResend, child: const Text('Resend')),
    );
  }
}

// =========================================================================
// EDIT NAME SHEET
// =========================================================================

class _EditNameSheet extends StatefulWidget {
  final String initial;
  const _EditNameSheet({required this.initial});

  @override
  State<_EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends State<_EditNameSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final name = _controller.text.trim();
    if (name.length < 2) {
      setState(() => _error = 'Enter at least 2 characters');
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit name',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: 40,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: InputDecoration(
                labelText: 'Full name',
                errorText: _error,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
