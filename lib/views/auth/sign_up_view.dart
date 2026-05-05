import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sprint_14/providers/auth_provider/auth_provider.dart';
import 'package:sprint_14/services/auth_service.dart';
import 'package:sprint_14/views/auth/verify_email_view.dart';

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

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmPassFocus = FocusNode();

  bool _obscurePass = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _confirmPassFocus.dispose();
    super.dispose();
  }

  /// --- THE LOGIC ---
  void _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      // 1. Await the result from the provider
      final AuthResult? result = await ref
          .read(authControllerProvider.notifier)
          .signUp(
            _nameController.text.trim(),
            _emailController.text.trim(),
            _passController.text.trim(),
          );

      // 2. Explicitly navigate based on that result
      if (result == AuthResult.unverified) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const VerifyEmailView()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the auth state to show errors/loading
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    // Listen for errors to show a SnackBar
    ref.listen<AsyncValue>(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.05),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset("assets/images/logo.svg", width: 60),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Create Account",
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Join Sprint14 to manage your daily life",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              softWrap: true,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildLabel("Full Name"),
                  _buildTextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    nextFocus: _emailFocus,
                    hint: "Enter your name",
                    icon: Icons.person_outline_rounded,
                    validator: (v) => v!.isEmpty ? "Name is required" : null,
                  ),
                  _buildLabel("Email Address"),
                  _buildTextField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    nextFocus: _passFocus,
                    hint: "example@mail.com",
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        !v!.contains("@") ? "Invalid email" : null,
                  ),
                  _buildLabel("Password"),
                  _buildTextField(
                    controller: _passController,
                    focusNode: _passFocus,
                    nextFocus: _confirmPassFocus,
                    hint: "*****",
                    icon: Icons.lock_outline_rounded,
                    obscure: _obscurePass,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePass ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                    validator: (v) =>
                        v!.length < 6 ? "Minimum 6 characters" : null,
                  ),
                  _buildLabel("Confirm Password"),
                  _buildTextField(
                    controller: _confirmPassController,
                    focusNode: _confirmPassFocus,
                    hint: "*****",
                    icon: Icons.lock_reset_rounded,
                    obscure: _obscurePass,
                    validator: (v) => v != _passController.text
                        ? "Passwords do not match"
                        : null,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      // Disable button while loading
                      onPressed: authState.isLoading ? null : _handleSignUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: authState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "SIGN UP",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodyMedium,
                          children: [
                            const TextSpan(text: "Already have an account? "),
                            TextSpan(
                              text: "Sign In",
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
    );
  }

  // --- Helper UI methods ---
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: nextFocus != null
          ? TextInputAction.next
          : TextInputAction.done,
      onFieldSubmitted: (_) => nextFocus != null
          ? FocusScope.of(context).requestFocus(nextFocus)
          : _handleSignUp(),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 22),
        suffixIcon: suffix,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}
