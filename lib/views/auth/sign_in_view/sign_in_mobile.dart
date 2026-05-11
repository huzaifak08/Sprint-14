import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sprint_14/providers/auth_provider/auth_provider.dart';
import 'package:sprint_14/views/auth/components/custom_auth_field.dart';
import 'package:sprint_14/views/auth/sign_in_view/sign_in_logic_mixin.dart';
import 'package:sprint_14/views/auth/sign_up_view/sign_up_view.dart';

class SignInMobile extends ConsumerStatefulWidget {
  const SignInMobile({super.key});

  @override
  ConsumerState<SignInMobile> createState() => _SignInMobileState();
}

class _SignInMobileState extends ConsumerState<SignInMobile> with SignInLogic {
  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    emailFocus.dispose();
    passFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);

    // Error Listener for Mobile
    ref.listen<AsyncValue>(authControllerProvider, (prev, next) {
      next.whenOrNull(
        error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        ),
      );
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        height: MediaQuery.of(context).size.height,
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
              key: formKey, // From Mixin
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  Row(
                    children: [
                      SvgPicture.asset("assets/images/logo.svg", width: 60),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome Back",
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            Text(
                              "Sign in to continue your progress",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                  CustomAuthField(
                    label: "Email Address",
                    controller: emailController,
                    focusNode: emailFocus,
                    nextFocus: passFocus,
                    hint: "name@company.com",
                    icon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        !v!.contains("@") ? "Invalid email" : null,
                  ),
                  const SizedBox(height: 8),

                  CustomAuthField(
                    label: "Password",
                    controller: passController,
                    focusNode: passFocus,
                    hint: "••••••••",
                    icon: Icons.lock_outline_rounded,
                    obscure: obscurePass,
                    onSubmitted: handleSignIn, // Mixin method
                    suffix: IconButton(
                      icon: Icon(
                        obscurePass ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => obscurePass = !obscurePass),
                    ),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: showForgotPassword, // From Mixin
                      child: Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: authState.isLoading
                          ? null
                          : handleSignIn, // From Mixin
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
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "SIGN IN",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpView(),
                        ),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodyMedium,
                          children: [
                            const TextSpan(text: "Don't have an account? "),
                            TextSpan(
                              text: "Sign Up",
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
}
