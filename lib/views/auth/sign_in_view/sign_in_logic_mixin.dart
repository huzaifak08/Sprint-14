import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider/auth_provider.dart';
import '../../../services/auth_service.dart';
import '../verify_email_view.dart';
import '../../home_view.dart';

mixin SignInLogic<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final emailFocus = FocusNode();
  final passFocus = FocusNode();
  bool obscurePass = true;

  void handleSignIn() async {
    if (formKey.currentState!.validate()) {
      final AuthResult? result = await ref
          .read(authControllerProvider.notifier)
          .signIn(emailController.text.trim(), passController.text.trim());

      if (!mounted) return;

      if (result == AuthResult.unverified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const VerifyEmailView()),
        );
      } else if (result == AuthResult.success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeView()),
        );
      }
    }
  }

  // Common UI helper for reset password
  void showForgotPassword() {
    final emailControl = TextEditingController(text: emailController.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Password"),
        content: TextField(
          controller: emailControl,
          decoration: const InputDecoration(hintText: "Enter registered email"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(authControllerProvider.notifier)
                  .passwordReset(emailControl.text.trim());
              Navigator.pop(context);
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }
}
