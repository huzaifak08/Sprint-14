import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprint_14/cache/init_cache.dart';
import 'package:sprint_14/components/app_network_image.dart';
import 'package:sprint_14/models/user_model.dart';
import 'package:sprint_14/providers/auth_provider/auth_provider.dart';
import 'package:sprint_14/providers/biometric_provider/biometric_provider.dart';
import 'package:sprint_14/providers/business_provider/business_provider.dart';
import 'package:sprint_14/providers/settings_provider/settings_provider.dart';
import 'package:sprint_14/providers/current_user_provider/current_user_provider.dart';
import 'package:sprint_14/views/auth/sign_in_view.dart';
import 'package:sprint_14/views/profile_view.dart';
import 'dart:developer' as dev;

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Watchers for Real-time UI updates
    final appSettings = ref.watch(appSettingsProvider);
    final businesses = ref.watch(businessProvider);

    // Watch securityState to ensure the UI reacts to biometric changes
    final securityState = ref.watch(securityProvider);
    final securityNotifier = ref.read(securityProvider.notifier);

    final userState = ref.watch(currentUserProvider);

    final appVersionState = ref.watch(appVersionProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(currentUserProvider.notifier).syncPendingData(),
        child: appSettings.when(
          data: (settings) {
            dev.log(
              settings.defaultBusinessId ?? "No Business Id",
              name: "Settings View",
            );
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                // --- ACCOUNT SECTION ---
                _buildSectionHeader(theme, "Account"),
                userState.when(
                  data: (user) => _buildProfileCard(context, theme, user),
                  loading: () => _buildLoadingCard(theme),
                  error: (err, stack) =>
                      _buildErrorCard(theme, "Profile unavailable"),
                ),
                const SizedBox(height: 24),

                // --- APPEARANCE SECTION ---
                _buildSectionHeader(theme, "Appearance"),
                _buildSettingTile(
                  theme,
                  icon: Icons.dark_mode_outlined,
                  title: "Dark Mode",
                  subtitle: "Toggle between high-contrast themes",
                  trailing: Switch(
                    value: settings.isDarkMode,
                    activeThumbColor: theme.colorScheme.primary,
                    onChanged: (val) =>
                        ref.read(appSettingsProvider.notifier).updateTheme(val),
                  ),
                ),
                const SizedBox(height: 24),

                // --- WORKFLOW SECTION ---
                _buildSectionHeader(theme, "Workflow"),
                businesses.when(
                  data: (bus) {
                    return _buildSettingTile(
                      theme,
                      icon: Icons.rocket_launch_outlined,
                      title: "Landing Page",
                      subtitle: "Direct access to your primary shop",
                      trailing: DropdownButton<String?>(
                        value:
                            bus.any((b) => b.id == settings.defaultBusinessId)
                            ? settings.defaultBusinessId
                            : null,
                        underline: const SizedBox(),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: theme.colorScheme.primary,
                        ),
                        onChanged: (val) => ref
                            .read(appSettingsProvider.notifier)
                            .updateLandingPage(val),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text("Default Home"),
                          ),
                          ...bus.map(
                            (b) => DropdownMenuItem<String?>(
                              value: b.id,
                              child: Text(b.name),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text("Error: $err")),
                ),
                const SizedBox(height: 24),

                // --- SECURITY SECTION ---
                _buildSectionHeader(theme, "Security"),
                securityState.when(
                  data: (isAuthenticated) => _buildSettingTile(
                    theme,
                    icon: Icons.fingerprint_rounded,
                    title: "Biometric Lock",
                    subtitle: "Protect your data with fingerprint",
                    trailing: Switch(
                      // Check the persistent preference from the notifier
                      value: securityNotifier.isSecurityEnabled,
                      activeThumbColor: theme.colorScheme.primary,
                      onChanged: (val) =>
                          securityNotifier.toggleBiometrics(val),
                    ),
                  ),
                  loading: () => _buildLoadingCard(theme),
                  error: (e, s) => _buildErrorCard(theme, "Security Error"),
                ),
                const SizedBox(height: 40),

                // --- LOGOUT SECTION ---
                _buildLogoutButton(context, ref, theme),
                const SizedBox(height: 32),

                appVersionState.when(
                  data: (version) {
                    return _buildVersionInfo(theme, version);
                  },
                  error: (error, stackTrace) => SizedBox.shrink(),
                  loading: () => SizedBox.shrink(),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _buildErrorCard(theme, "Error loading settings"),
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildProfileCard(
    BuildContext context,
    ThemeData theme,
    UserModel? user,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileView()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            AppNetworkImage(
              path: user?.profilePic,
              size: 64, // radius 32 * 2 = 64
              isCircle: true,
              fallbackLetter: user?.name.isNotEmpty == true
                  ? user!.name[0]
                  : "U",
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.name ?? "User",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? "No email linked",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        trailing: trailing,
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildLogoutButton(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _handleLogout(context, ref, theme),
        icon: const Icon(Icons.logout_rounded),
        label: const Text(
          "LOGOUT ACCOUNT",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.error,
          side: BorderSide(
            color: theme.colorScheme.error.withValues(alpha: 0.5),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure? Local cache will be preserved."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(currentUserProvider.notifier).clearUser();

              await LocalCacheManager.deleteAllCacheData();

              // ref.invalidate(currentUserProvider);
              // ref.invalidate(ledgerProvider);
              // ref.invalidate(businessProvider);
              // ref.invalidate(saleProvider);
              // ref.invalidate(productProvider);
              // ref.invalidate(expenseProvider);
              // ref.invalidate(appSettingsProvider);

              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) {
                ref.container.refresh(authControllerProvider);

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const SignInView()),
                  (route) => false,
                );
                ref.invalidate(authControllerProvider);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(ThemeData theme) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorCard(ThemeData theme, String message) {
    return ListTile(
      tileColor: theme.colorScheme.errorContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      leading: Icon(Icons.error_outline, color: theme.colorScheme.error),
      title: Text(message),
    );
  }

  Widget _buildVersionInfo(ThemeData theme, String version) {
    return Center(
      child: Text(
        "Sprint14 v$version • Secure Build",
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
