import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sprint_14/providers/auth_provider/auth_provider.dart';
import 'package:sprint_14/views/auth/components/custom_auth_field.dart';
import 'package:sprint_14/views/auth/sign_in_view/sign_in_logic_mixin.dart';
import 'package:sprint_14/views/auth/sign_up_view/sign_up_view.dart';

class SignInDesktop extends ConsumerStatefulWidget {
  const SignInDesktop({super.key});

  @override
  ConsumerState<SignInDesktop> createState() => _SignInDesktopState();
}

class _SignInDesktopState extends ConsumerState<SignInDesktop>
    with SignInLogic {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);

    // Error Listener
    ref.listen<AsyncValue>(authControllerProvider, (prev, next) {
      next.whenOrNull(
        error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
            width: 400, // Fixed width for desktop snackbar
          ),
        ),
      );
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          // --- LEFT SIDE: Branding & Aesthetic ---
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Large Logo for Desktop
                    SvgPicture.asset("assets/images/logo.svg", width: 120),
                    const SizedBox(height: 32),
                    const Text(
                      "SPRINT 14",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Next-Gen Inventory & Business Management",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- RIGHT SIDE: The Form ---
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Form(
                  key: formKey, // From Mixin
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome Back",
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Please enter your details to access your dashboard.",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Example usage in either file:
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

                      const SizedBox(height: 20),

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
                            obscurePass
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () =>
                              setState(() => obscurePass = !obscurePass),
                        ),
                        validator: (v) => v!.isEmpty ? "Required" : null,
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: showForgotPassword, // From Mixin
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // SIGN IN BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: authState.isLoading
                              ? null
                              : handleSignIn, // From Mixin
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: authState.isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "SIGN IN TO DASHBOARD",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
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
                                const TextSpan(text: "New here? "),
                                TextSpan(
                                  text: "Create an Account",
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
        ],
      ),
    );
  }
}
