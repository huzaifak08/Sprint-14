import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprint_14/providers/auth_provider/auth_provider.dart';
import 'package:sprint_14/helpers/recent_emails.dart';
import 'package:sprint_14/views/auth/verify_email_view.dart';
import 'package:sprint_14/views/auth/widgets/auth_widgets.dart';

class SignUpView extends ConsumerStatefulWidget {
  const SignUpView({super.key});

  @override
  ConsumerState<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends ConsumerState<SignUpView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmPassFocus = FocusNode();

  bool _obscurePass = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _confirmPassFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signUp(
            _nameController.text.trim(),
            _emailController.text.trim(),
            // Passwords are used exactly as typed (never trimmed).
            _passController.text,
          );
      if (!mounted) return;
      TextInput.finishAutofillContext(shouldSave: true);
      RecentEmails.remember(_emailController.text);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const VerifyEmailView()),
        (route) => false,
      );
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      // SafeArea below already adds the app bar's height, so the form starts
      // under the back button while the background runs edge to edge.
      extendBodyBehindAppBar: true,
      body: AuthBackground(
        child: SafeArea(
          // Top-aligned so the layout doesn't jump when the keyboard opens.
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AuthHeader(
                        title: 'Create account',
                        subtitle: 'Join Sprint14 to manage your daily life',
                      ),
                      const SizedBox(height: 24),
                      AuthTextField(
                        label: 'Full name',
                        controller: _nameController,
                        hint: 'Enter your name',
                        icon: Icons.person_outline_rounded,
                        readOnly: _loading,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        onSubmitted: (_) => _emailFocus.requestFocus(),
                        validator: (v) => (v?.trim().length ?? 0) < 2
                            ? 'Enter your name (at least 2 characters)'
                            : null,
                      ),
                      AuthTextField(
                        label: 'Email address',
                        controller: _emailController,
                        focusNode: _emailFocus,
                        hint: 'example@mail.com',
                        icon: Icons.email_outlined,
                        readOnly: _loading,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        onSubmitted: (_) => _passFocus.requestFocus(),
                        validator: validateEmail,
                      ),
                      AuthTextField(
                        label: 'Password',
                        controller: _passController,
                        focusNode: _passFocus,
                        hint: 'At least 6 characters',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscurePass,
                        readOnly: _loading,
                        autofillHints: const [AutofillHints.newPassword],
                        onSubmitted: (_) => _confirmPassFocus.requestFocus(),
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
                        validator: (v) {
                          final p = v ?? '';
                          if (p.length < 6) return 'Use at least 6 characters';
                          if (p.trim() != p) {
                            return "Password can't start or end with a space";
                          }
                          return null;
                        },
                      ),
                      AuthTextField(
                        label: 'Confirm password',
                        controller: _confirmPassController,
                        focusNode: _confirmPassFocus,
                        hint: 'Repeat your password',
                        icon: Icons.lock_reset_rounded,
                        obscure: _obscurePass,
                        readOnly: _loading,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        onSubmitted: (_) => _handleSignUp(),
                        validator: (v) => v != _passController.text
                            ? 'Passwords do not match'
                            : null,
                      ),
                      const SizedBox(height: 32),
                      AuthPrimaryButton(
                        label: 'CREATE ACCOUNT',
                        loading: _loading,
                        onPressed: _handleSignUp,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: _loading
                              ? null
                              : () => Navigator.pop(context),
                          child: Text.rich(
                            TextSpan(
                              style: theme.textTheme.bodyMedium,
                              children: [
                                const TextSpan(
                                  text: 'Already have an account? ',
                                ),
                                TextSpan(
                                  text: 'Sign in',
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
