import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprint_14/cache/tables/ledger_table.dart';
import 'package:sprint_14/cache/tables/user_table.dart';
import 'package:sprint_14/models/user_model.dart';
import 'package:sprint_14/providers/auth_provider/auth_provider.dart';
import 'package:sprint_14/providers/biometric_provider/biometric_provider.dart';
import 'package:sprint_14/providers/ledger_provider/ledger_provider.dart';
import 'package:sprint_14/providers/theme_provider/theme_provider.dart';
import 'package:sprint_14/providers/user_provider/user_provider.dart';
import 'package:sprint_14/views/auth/sign_in_view.dart';
import 'package:sprint_14/views/profile_view.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeState = ref.watch(themeNotifier);

    // 1. Watch Security State (Biometrics)
    final securityState = ref.watch(securityProvider);
    final securityNotifier = ref.read(securityProvider.notifier);

    // 2. Watch User Data directly from UserNotifier (Cache + Firestore)
    final userState = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(userProvider.notifier).syncPendingUser(),
        child: ListView(
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
              subtitle: "Switch between light and dark themes",
              trailing: Switch(
                value: themeState.themeMode == ThemeMode.dark,
                activeColor: theme.colorScheme.primary,
                onChanged: (val) {
                  ref
                      .read(themeNotifier.notifier)
                      .setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                },
              ),
            ),

            const SizedBox(height: 24),

            // --- SECURITY SECTION ---
            _buildSectionHeader(theme, "Security"),
            securityState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => _buildErrorCard(theme, "Biometrics error"),
              data: (_) => _buildSettingTile(
                theme,
                icon: Icons.fingerprint_rounded,
                title: "Biometric Lock",
                subtitle: "Protect your data with fingerprint",
                trailing: Switch(
                  value: securityNotifier.isSecurityEnabled,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (val) async {
                    await securityNotifier.toggleBiometrics(val);
                  },
                ),
              ),
            ),

            const SizedBox(height: 40),

            // --- LOGOUT SECTION ---
            _buildLogoutButton(context, ref, theme),

            const SizedBox(height: 32),
            _buildVersionInfo(theme),
          ],
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
              color: theme.colorScheme.primary.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white24,
              child: Text(
                user?.name.isNotEmpty == true
                    ? user!.name[0].toUpperCase()
                    : "U",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (user != null && !user.isSynced)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.cloud_off_rounded,
                  color: Colors.white70,
                  size: 20,
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
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
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
        onPressed: () => _handleLogout(context, ref),
        icon: const Icon(Icons.logout_rounded),
        label: const Text(
          "LOGOUT ACCOUNT",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.error,
          side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text(
          "Are you sure you want to sign out? Local cache will be preserved.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              // 1. Clear the Singleton

              // 2. Clear Local SQLite Cache (Crucial for security)
              await UserTable.clearAllUsers();
              // await ProjectTable.deleteAllProjects();
              await LedgerTable.deleteAllLedgers();

              // 3. Invalidate Providers (This resets their state to default/loading)
              // This will trigger the build() methods to run again and see 'null' user
              ref.invalidate(userProvider);
              // ref.invalidate(projectNotifierProvider);
              ref.invalidate(ledgerProvider);

              // 4. Perform Firebase Logout
              await ref.read(authControllerProvider.notifier).logout();

              // 5. Navigate to Sign In
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const SignInView()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(ThemeData theme) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
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

  Widget _buildVersionInfo(ThemeData theme) {
    return Center(
      child: Text(
        "Sprint14 v1.0.2 • Secure Build",
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.3),
        ),
      ),
    );
  }
}
