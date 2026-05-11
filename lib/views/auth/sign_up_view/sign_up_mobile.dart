import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sprint_14/providers/auth_provider/auth_provider.dart';
import 'package:sprint_14/views/auth/components/custom_auth_field.dart';
import 'sign_up_logic_mixin.dart';

class SignUpMobile extends ConsumerStatefulWidget {
  const SignUpMobile({super.key});

  @override
  ConsumerState<SignUpMobile> createState() => _SignUpMobileState();
}

class _SignUpMobileState extends ConsumerState<SignUpMobile> with SignUpLogic {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Row(
                  children: [
                    SvgPicture.asset("assets/images/logo.svg", width: 60),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Create Account",
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Join Sprint 14 today",
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                CustomAuthField(
                  controller: nameController,
                  focusNode: nameFocus,
                  nextFocus: emailFocus,
                  label: "Full Name",
                  hint: "Enter your name",
                  icon: Icons.person_outline_rounded,
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 20),
                CustomAuthField(
                  controller: emailController,
                  focusNode: emailFocus,
                  nextFocus: passFocus,
                  label: "Email Address",
                  hint: "example@mail.com",
                  icon: Icons.email_outlined,
                  validator: (v) => !v!.contains("@") ? "Invalid email" : null,
                ),
                const SizedBox(height: 20),
                CustomAuthField(
                  controller: passController,
                  focusNode: passFocus,
                  nextFocus: confirmPassFocus,
                  label: "Password",
                  hint: "••••••••",
                  icon: Icons.lock_outline_rounded,
                  obscure: obscurePass,
                  suffix: IconButton(
                    icon: Icon(
                      obscurePass ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => obscurePass = !obscurePass),
                  ),
                  validator: (v) => v!.length < 6 ? "Min 6 characters" : null,
                ),
                const SizedBox(height: 20),
                CustomAuthField(
                  controller: confirmPassController,
                  focusNode: confirmPassFocus,
                  label: "Confirm Password",
                  hint: "••••••••",
                  icon: Icons.lock_reset_rounded,
                  obscure: obscurePass,
                  onSubmitted: handleSignUp,
                  validator: (v) =>
                      v != passController.text ? "Mismatch" : null,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : handleSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: authState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "SIGN UP",
                            style: TextStyle(fontWeight: FontWeight.bold),
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
    );
  }
}
