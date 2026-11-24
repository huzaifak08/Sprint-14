import 'package:flutter/material.dart';
import 'package:digital_munshi/components/app_toast.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_munshi/providers/auth_provider/auth_provider.dart';
import 'package:digital_munshi/services/auth_service.dart';
import 'package:digital_munshi/views/auth/sign_up_view.dart';
import 'package:digital_munshi/views/auth/verify_email_view.dart';
import 'package:digital_munshi/views/auth/widgets/auth_widgets.dart';
import 'package:digital_munshi/helpers/recent_emails.dart';
import 'package:digital_munshi/services/post_auth_navigation.dart';

class SignInView extends ConsumerStatefulWidget {
  const SignInView({super.key});

  @override
  ConsumerState<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends ConsumerState<SignInView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();

  bool _obscurePass = true;
  bool _loading = false;
  List<String> _recentEmails = const [];

  @override
  void initState() {
    super.initState();
    RecentEmails.load().then((list) {
      if (!mounted) return;
      setState(() => _recentEmails = list);
      // One account used before: pre-fill it and jump to the password.
      if (list.length == 1 && _emailController.text.isEmpty) {
        _emailController.text = list.first;
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final result = await ref
          .read(authControllerProvider.notifier)
          .signIn(_emailController.text, _passController.text);
      if (!mounted) return;
      // Lets the password manager offer to save these credentials.
      TextInput.finishAutofillContext(shouldSave: true);
      RecentEmails.remember(_emailController.text);

      final navigator = Navigator.of(context);
      if (result == AuthResult.unverified) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const VerifyEmailView()),
          (route) => false,
        );
      } else {
        // Straight in: no second splash screen after signing in.
        await openSignedInHome(navigator, ref.read);
      }
    } catch (e) {
      if (mounted) showAuthError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          // Top-aligned so the layout doesn't jump when the keyboard opens.
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AuthHeader(
                        title: 'Welcome back',
                        subtitle: 'Sign in to continue your progress',
                      ),
                      const SizedBox(height: 36),
                      AuthEmailField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        suggestions: _recentEmails,
                        readOnly: _loading,
                        onSubmitted: (_) => _passFocus.requestFocus(),
                      ),
                      AuthTextField(
                        label: 'Password',
                        controller: _passController,
                        focusNode: _passFocus,
                        hint: '••••••••',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscurePass,
                        readOnly: _loading,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onSubmitted: (_) => _handleSignIn(),
                        suffix: IconButton(
                          tooltip: _obscurePass
                              ? 'Show password'
                              : 'Hide password',
                          icon: Icon(
                            _obscurePass
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePass = !_obscurePass),
                        ),
                        validator: (v) =>
                            (v ?? '').isEmpty ? 'Password is required' : null,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _loading
                              ? null
                              : () => showDialog<void>(
                                  context: context,
                                  builder: (_) => _ForgotPasswordDialog(
                                    initialEmail: _emailController.text,
                                  ),
                                ),
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      AuthPrimaryButton(
                        label: 'SIGN IN',
                        loading: _loading,
                        onPressed: _handleSignIn,
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: TextButton(
                          onPressed: _loading
                              ? null
                              : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SignUpView(),
                                  ),
                                ),
                          child: Text.rich(
                            TextSpan(
                              style: theme.textTheme.bodyMedium,
                              children: [
                                const TextSpan(text: "Don't have an account? "),
                                TextSpan(
                                  text: 'Sign up',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks for the email, validates it, and reports what really happened.
class _ForgotPasswordDialog extends StatefulWidget {
  final String initialEmail;
  const _ForgotPasswordDialog({required this.initialEmail});

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final _controller = TextEditingController(
    text: widget.initialEmail.trim(),
  );
  String? _error;
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _controller.text.trim();
    final invalid = validateEmail(email);
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await AuthService().resetPassword(email);
      if (!mounted) return;
      Navigator.pop(context);
      // Firebase doesn't reveal whether an account exists.
      AppToast.success(
        'If an account exists for $email, a reset link is on its way.',
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Enter your account's email and we'll send a reset link."),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: widget.initialEmail.trim().isEmpty,
            enabled: !_sending,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            onSubmitted: (_) => _send(),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(
              labelText: 'Email',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _sending ? null : _send,
          child: _sending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send link'),
        ),
      ],
    );
  }
}
