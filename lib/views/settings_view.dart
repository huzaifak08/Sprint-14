import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprint_14/cache/init_cache.dart';
import 'package:sprint_14/cache/sync/pending_sync.dart';
import 'package:sprint_14/components/app_network_image.dart';
import 'package:sprint_14/helpers/theme_widgets.dart';
import 'package:sprint_14/models/business_model.dart';
import 'package:sprint_14/models/user_model.dart';
import 'package:sprint_14/providers/auth_provider/auth_provider.dart';
import 'package:sprint_14/providers/biometric_provider/biometric_provider.dart';
import 'package:sprint_14/providers/business_provider/business_provider.dart';
import 'package:sprint_14/providers/settings_provider/settings_provider.dart';
import 'package:sprint_14/providers/current_user_provider/current_user_provider.dart';
import 'package:sprint_14/views/auth/sign_in_view.dart';
import 'package:sprint_14/views/profile_view.dart';

/// Whether any local change is still waiting to be uploaded.
final _hasUnsyncedProvider = FutureProvider.autoDispose<bool>(
  (ref) => LocalCacheManager.hasUnsyncedData(),
);

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  bool _syncing = false;
  bool _togglingLock = false;

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _syncNow() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      await syncAllPending(ref.read);
      await ref.read(currentUserProvider.notifier).syncPendingData();
      ref.invalidate(_hasUnsyncedProvider);
      final pending = await ref.read(_hasUnsyncedProvider.future);
      if (!mounted) return;
      _snack(
        pending
            ? "Some changes couldn't be uploaded. Check your connection."
            : 'Everything is synced',
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _toggleLock(bool value) async {
    setState(() => _togglingLock = true);
    final result = await ref.read(securityProvider.notifier).setEnabled(value);
    if (!mounted) return;
    setState(() => _togglingLock = false);
    switch (result) {
      case BiometricToggleResult.done:
        _snack(value ? 'App lock turned on' : 'App lock turned off');
      case BiometricToggleResult.unsupported:
        _snack(
          'Set up a fingerprint, face unlock or screen lock on this device first.',
        );
      case BiometricToggleResult.cancelled:
        _snack('Verification cancelled. Nothing changed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(appSettingsProvider);
    final userState = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Couldn't load settings: $e")),
        data: (config) => RefreshIndicator(
          onRefresh: _syncNow,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              userState.when(
                data: (user) => _ProfileCard(user: user),
                loading: () => const SizedBox(
                  height: 104,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => const _ProfileCard(user: null),
              ),
              const SizedBox(height: 24),

              const _SectionHeader('Appearance'),
              _Group(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _TileTitle(
                          icon: Icons.palette_outlined,
                          title: 'Theme',
                          subtitle: 'System follows your phone\'s setting',
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<ThemeMode>(
                            style: themedSegments(theme),
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(
                                value: ThemeMode.light,
                                icon: Icon(Icons.light_mode_rounded, size: 18),
                                label: Text('Light'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                icon: Icon(Icons.dark_mode_rounded, size: 18),
                                label: Text('Dark'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.system,
                                icon: Icon(
                                  Icons.brightness_auto_rounded,
                                  size: 18,
                                ),
                                label: Text('System'),
                              ),
                            ],
                            selected: {config.themeMode},
                            onSelectionChanged: (v) => ref
                                .read(appSettingsProvider.notifier)
                                .setThemeMode(v.first),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const _SectionHeader('General'),
              _Group(
                children: [
                  _StartScreenTile(selectedId: config.defaultBusinessId),
                  _Tile(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Manage alerts in your phone settings',
                    trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                    onTap: () => AppSettings.openAppSettings(
                      type: AppSettingsType.notification,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const _SectionHeader('Security'),
              _Group(children: [_buildLockTile(theme)]),
              const SizedBox(height: 24),

              const _SectionHeader('Data & sync'),
              _Group(children: [_buildSyncTile(theme)]),
              const SizedBox(height: 32),

              const _LogoutButton(),
              const SizedBox(height: 24),
              const _VersionFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLockTile(ThemeData theme) {
    final security = ref.watch(securityProvider);
    final available = ref.watch(biometricAvailableProvider).value ?? true;
    final enabled = ref.read(securityProvider.notifier).isSecurityEnabled;

    return _Tile(
      icon: Icons.fingerprint_rounded,
      title: 'App lock',
      subtitle: !available
          ? 'Not available: set up a screen lock on this device'
          : (enabled
                ? 'Locks again after 30 s in the background'
                : 'Use fingerprint, face or your device PIN'),
      trailing: _togglingLock || security.isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : Switch(
              value: enabled,
              onChanged: available || enabled ? _toggleLock : null,
            ),
      onTap: _togglingLock || (!available && !enabled)
          ? null
          : () => _toggleLock(!enabled),
    );
  }

  Widget _buildSyncTile(ThemeData theme) {
    final pending = ref.watch(_hasUnsyncedProvider);
    final hasPending = pending.value ?? false;
    final positive = positiveMoneyColor(theme);

    return _Tile(
      icon: hasPending
          ? Icons.cloud_upload_outlined
          : Icons.cloud_done_outlined,
      iconColor: hasPending ? theme.colorScheme.primary : positive,
      title: 'Sync now',
      subtitle: pending.isLoading
          ? 'Checking…'
          : (hasPending
                ? 'Some changes are waiting to upload'
                : 'All changes are saved to the cloud'),
      trailing: _syncing
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : Icon(Icons.sync_rounded, color: theme.colorScheme.primary),
      onTap: _syncing ? null : _syncNow,
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

/// A rounded card holding related tiles, separated by thin dividers.
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

class _TileTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _TileTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: theme.hintColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: iconColor ?? theme.colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: theme.hintColor),
      ),
      trailing: trailing,
    );
  }
}

// =========================================================================
// PROFILE CARD
// =========================================================================

class _ProfileCard extends StatelessWidget {
  final UserModel? user;
  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final on = cs.onPrimary;
    final name = (user?.name.trim().isNotEmpty ?? false) ? user!.name : 'User';

    return Material(
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cs.primary, Color.lerp(cs.primary, Colors.black, 0.28)!],
          ),
        ),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileView()),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                AppNetworkImage(
                  path: user?.profilePic,
                  size: 64,
                  isCircle: true,
                  fallbackLetter: name.characters.first.toUpperCase(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: on,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? 'No email linked',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: on.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: ShapeDecoration(
                          shape: const StadiumBorder(),
                          color: on.withValues(alpha: 0.15),
                        ),
                        child: Text(
                          user != null && !user!.isSynced
                              ? 'Profile changes not synced'
                              : 'Edit profile',
                          style: TextStyle(
                            color: on,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: on),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// START SCREEN PICKER
// =========================================================================

class _StartScreenTile extends ConsumerWidget {
  final String? selectedId;
  const _StartScreenTile({required this.selectedId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final businessesAsync = ref.watch(businessProvider);
    final businesses = businessesAsync.value ?? const <BusinessModel>[];

    BusinessModel? selected;
    for (final b in businesses) {
      if (b.id == selectedId) selected = b;
    }

    return _Tile(
      icon: Icons.rocket_launch_outlined,
      title: 'Start screen',
      subtitle: selected == null
          ? 'Opens on Home'
          : 'Opens straight into ${selected.name}',
      trailing: businessesAsync.isLoading && businesses.isEmpty
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(Icons.chevron_right_rounded, color: theme.hintColor),
      onTap: () => _pick(context, ref, businesses, selected?.id),
    );
  }

  void _pick(
    BuildContext context,
    WidgetRef ref,
    List<BusinessModel> businesses,
    String? current,
  ) {
    final theme = Theme.of(context);

    Widget option(String? id, String title, String subtitle, IconData icon) {
      final isSelected = id == current;
      return ListTile(
        leading: Icon(
          icon,
          color: isSelected ? theme.colorScheme.primary : theme.hintColor,
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: isSelected
            ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
            : null,
        onTap: () {
          ref.read(appSettingsProvider.notifier).updateLandingPage(id);
          Navigator.pop(context);
        },
      );
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      builder: (_) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Open the app on',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              option(
                null,
                'Home',
                'Ledger, events and businesses',
                Icons.home_rounded,
              ),
              for (final b in businesses)
                option(
                  b.id,
                  b.name,
                  'Business dashboard',
                  Icons.storefront_rounded,
                ),
              if (businesses.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Text(
                    'Create a business to open the app straight into it.',
                    style: TextStyle(color: theme.hintColor),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// LOGOUT + FOOTER
// =========================================================================

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirm(context),
        icon: const Icon(Icons.logout_rounded),
        label: const Text(
          "Log out",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.error,
          side: BorderSide(
            color: theme.colorScheme.error.withValues(alpha: 0.5),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  void _confirm(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _LogoutDialog(),
    );
  }
}

class _LogoutDialog extends ConsumerStatefulWidget {
  const _LogoutDialog();

  @override
  ConsumerState<_LogoutDialog> createState() => _LogoutDialogState();
}

class _LogoutDialogState extends ConsumerState<_LogoutDialog> {
  bool _busy = false;

  Future<void> _logout() async {
    setState(() => _busy = true);
    final navigator = Navigator.of(context, rootNavigator: true);
    // Uploads pending changes, removes the push token and clears the cache
    // only when nothing is left unsynced.
    await ref.read(authControllerProvider.notifier).logout();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInView()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: const Text("Log out?"),
        content: _busy
            ? const Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  SizedBox(width: 16),
                  Expanded(child: Text('Uploading your changes…')),
                ],
              )
            : const Text(
                "Pending changes are uploaded first. If you're offline, they "
                "stay on this device until you sign in again.",
              ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: _busy ? null : _logout,
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text("Log out"),
          ),
        ],
      ),
    );
  }
}

class _VersionFooter extends ConsumerWidget {
  const _VersionFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionProvider).value;
    final theme = Theme.of(context);
    return Center(
      child: Text(
        version == null ? 'Sprint14' : 'Sprint14 · v$version',
        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
      ),
    );
  }
}
