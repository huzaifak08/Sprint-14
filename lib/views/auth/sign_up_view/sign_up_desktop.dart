import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sprint_14/providers/auth_provider/auth_provider.dart';
import 'package:sprint_14/views/auth/components/custom_auth_field.dart';
import 'sign_up_logic_mixin.dart';

class SignUpDesktop extends ConsumerStatefulWidget {
  const SignUpDesktop({super.key});

  @override
  ConsumerState<SignUpDesktop> createState() => _SignUpDesktopState();
}

class _SignUpDesktopState extends ConsumerState<SignUpDesktop>
    with SignUpLogic {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          // Left: Visual Branding
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.9),
                    theme.colorScheme.primary,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(60.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(
                      "assets/images/logo.svg",
                      width: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      "Start your journey\nwith Sprint 14.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "The most powerful tool for engineers and full-stack developers to manage inventory, finances, and project lifecycles.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 18,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Right: Sign Up Form
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 60,
                  vertical: 40,
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Create Account",
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 40),
                        CustomAuthField(
                          controller: nameController,
                          focusNode: nameFocus,
                          nextFocus: emailFocus,
                          label: "Full Name",
                          hint: "Huzaifa Khan",
                          icon: Icons.person_outline,
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 20),
                        CustomAuthField(
                          controller: emailController,
                          focusNode: emailFocus,
                          nextFocus: passFocus,
                          label: "Email Address",
                          hint: "contact@huzaifakhan.com",
                          icon: Icons.alternate_email,
                          validator: (v) =>
                              !v!.contains("@") ? "Invalid email" : null,
                        ),
                        const SizedBox(height: 20),
                        CustomAuthField(
                          controller: passController,
                          focusNode: passFocus,
                          nextFocus: confirmPassFocus,
                          label: "Password",
                          hint: "••••••••",
                          icon: Icons.lock_outline,
                          obscure: obscurePass,
                          suffix: IconButton(
                            icon: Icon(
                              obscurePass
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () =>
                                setState(() => obscurePass = !obscurePass),
                          ),
                          validator: (v) => v!.length < 6 ? "Too short" : null,
                        ),
                        const SizedBox(height: 20),
                        CustomAuthField(
                          controller: confirmPassController,
                          focusNode: confirmPassFocus,
                          label: "Confirm Password",
                          hint: "••••••••",
                          icon: Icons.lock_reset,
                          obscure: obscurePass,
                          onSubmitted: handleSignUp,
                          validator: (v) =>
                              v != passController.text ? "Mismatch" : null,
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: authState.isLoading
                                ? null
                                : handleSignUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: authState.isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    "CREATE ACCOUNT",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Already have an account? Sign In",
                              style: TextStyle(fontWeight: FontWeight.bold),
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
        ],
      ),
    );
  }
}
