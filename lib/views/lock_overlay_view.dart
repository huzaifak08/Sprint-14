import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprint_14/providers/biometric_provider/biometric_provider.dart';
import 'package:sprint_14/services/biometric_service.dart';

class LockOverlayView extends ConsumerStatefulWidget {
  const LockOverlayView({super.key});

  @override
  ConsumerState<LockOverlayView> createState() => _LockOverlayViewState();
}

class _LockOverlayViewState extends ConsumerState<LockOverlayView> {
  @override
  void initState() {
    // 🔥 Trigger authentication as soon as the frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleAuthentication();
    });
    super.initState();
  }

  Future<void> _handleAuthentication() async {
    final success = await BiometricService().authenticate();
    if (success) {
      ref.read(securityProvider.notifier).setAuthenticated(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Using your logo or a prominent icon
            Icon(
              Icons.lock_person_rounded,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              "Sprint14 is Locked",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please verify your identity to continue",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.6,
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Manual fallback button
            ElevatedButton.icon(
              onPressed: _handleAuthentication,
              icon: const Icon(Icons.fingerprint_rounded),
              label: const Text("UNLOCK NOW"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(220, 55),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),

            const SizedBox(height: 20),
            // Subtle indicator that the app is waiting for input
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
