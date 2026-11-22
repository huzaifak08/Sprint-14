import 'dart:async';
import 'package:sprint_14/components/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprint_14/providers/auth_provider/auth_provider.dart';
import 'package:sprint_14/views/auth/sign_in_view.dart';
import 'package:sprint_14/views/auth/widgets/auth_widgets.dart';
import 'package:sprint_14/services/post_auth_navigation.dart';

class VerifyEmailView extends ConsumerStatefulWidget {
  const VerifyEmailView({super.key});

  @override
  ConsumerState<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends ConsumerState<VerifyEmailView>
    with WidgetsBindingObserver {
  static const _pollEvery = Duration(seconds: 5);
  static const _resendCooldown = 60;

  Timer? _pollTimer;
  Timer? _cooldownTimer;
  bool _checking = false;
  bool _manualCheck = false;
  bool _resending = false;
  bool _leaving = false;
  int _cooldownLeft = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Users usually verify in their mail app: check right when they return,
    // and don't poll while the app is in the background.
    if (state == AppLifecycleState.resumed) {
      _checkStatus();
      _startPolling();
    } else if (state == AppLifecycleState.paused) {
      _pollTimer?.cancel();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollEvery, (_) => _checkStatus());
  }

  Future<void> _checkStatus({bool manual = false}) async {
    if (_checking || _leaving) return;
    _checking = true;
    if (manual) setState(() => _manualCheck = true);

    final verified = await ref
        .read(authControllerProvider.notifier)
        .refreshUserStatus();

    _checking = false;
    if (!mounted) return;
    if (manual) setState(() => _manualCheck = false);

    if (verified) {
      _leaving = true;
      _pollTimer?.cancel();
      await openSignedInHome(Navigator.of(context), ref.read);
    } else if (manual) {
      AppToast.info(
        "Not verified yet. Open the link in the email, then try again.",
      );
    }
  }

  Future<void> _handleResend() async {
    if (_resending || _cooldownLeft > 0) return;
    setState(() => _resending = true);
    try {
      await ref.read(authControllerProvider.notifier).resendVerification();
      if (!mounted) return;
      AppToast.success('Verification email sent');
      _startCooldown();
    } catch (e) {
      if (mounted) showAuthError(context, e);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownLeft = _resendCooldown);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _cooldownLeft--);
      if (_cooldownLeft <= 0) t.cancel();
    });
  }

  Future<void> _useDifferentEmail() async {
    _leaving = true;
    _pollTimer?.cancel();
    final navigator = Navigator.of(context);
    await ref.read(authControllerProvider.notifier).logout();
    // Replace the whole stack: this screen can be the only route (opened
    // from the splash), so a plain pop would leave a black screen.
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInView()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = ref.watch(authControllerProvider).value?.email;
    final isDark = theme.brightness == Brightness.dark;
    final noteColor = isDark ? Colors.amber.shade300 : Colors.orange.shade900;

    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mark_email_unread_rounded,
                      size: 72,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Verify your email',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: "We've sent a verification link to ",
                        ),
                        TextSpan(
                          text: email ?? 'your email address',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(
                          text:
                              '. Open it to activate your account. This page '
                              'continues automatically once you have.',
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.75,
                      ),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: noteColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Can't find it? Check your Spam or Junk folder.",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: noteColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _manualCheck
                          ? null
                          : () => _checkStatus(manual: true),
                      icon: _manualCheck
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.verified_user_rounded),
                      label: const Text(
                        "I'VE VERIFIED",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _resending || _cooldownLeft > 0
                        ? null
                        : _handleResend,
                    child: _resending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _cooldownLeft > 0
                                ? 'Resend available in ${_cooldownLeft}s'
                                : 'Resend verification email',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: _leaving ? null : _useDifferentEmail,
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Use a different email'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
