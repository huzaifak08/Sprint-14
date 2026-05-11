import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprint_14/components/responsive_layout.dart';
import 'sign_up_mobile.dart';
import 'sign_up_desktop.dart';

class SignUpView extends ConsumerStatefulWidget {
  const SignUpView({super.key});

  @override
  ConsumerState<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends ConsumerState<SignUpView> {
  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: SignUpMobile(),
      desktop: SignUpDesktop(),
    );
  }
}
