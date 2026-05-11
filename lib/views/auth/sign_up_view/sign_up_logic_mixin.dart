import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprint_14/providers/auth_provider/auth_provider.dart';
import 'package:sprint_14/services/auth_service.dart';
import 'package:sprint_14/views/auth/verify_email_view.dart';

mixin SignUpLogic<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final confirmPassController = TextEditingController();

  final nameFocus = FocusNode();
  final emailFocus = FocusNode();
  final passFocus = FocusNode();
  final confirmPassFocus = FocusNode();

  bool obscurePass = true;

  void handleSignUp() async {
    if (formKey.currentState!.validate()) {
      final AuthResult? result = await ref
          .read(authControllerProvider.notifier)
          .signUp(
            nameController.text.trim(),
            emailController.text.trim(),
            passController.text.trim(),
          );

      if (!mounted) return;

      if (result == AuthResult.unverified) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const VerifyEmailView()),
        );
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passController.dispose();
    confirmPassController.dispose();
    nameFocus.dispose();
    emailFocus.dispose();
    passFocus.dispose();
    confirmPassFocus.dispose();
    super.dispose();
  }
}
