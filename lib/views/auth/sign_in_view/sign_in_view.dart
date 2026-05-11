import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../components/responsive_layout.dart';
import 'sign_in_mobile.dart';
import 'sign_in_desktop.dart';

class SignInView extends ConsumerStatefulWidget {
  const SignInView({super.key});

  @override
  ConsumerState<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends ConsumerState<SignInView> {
  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: SignInMobile(),
      desktop: SignInDesktop(),
    );
  }
}
