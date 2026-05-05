import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sprint_14/providers/auth_provider/auth_provider.dart';
import 'package:sprint_14/views/auth/sign_in_view.dart';
import 'package:sprint_14/views/auth/verify_email_view.dart';
import 'package:sprint_14/views/home_view.dart';

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _handleNavigation();
  }

  void _setupAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    );
    _textAnimation = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    );

    _logoController.forward();
    Future.delayed(
      const Duration(milliseconds: 500),
      () => _textController.forward(),
    );
  }

  Future<void> _handleNavigation() async {
    // 1. Wait for animations to at least start/look good (e.g., 2.5 seconds total)
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // 2. Read the current Auth State from our Provider
    // We use ref.read here because this is a one-time navigation event
    final authState = ref.read(authControllerProvider);

    authState.when(
      data: (user) {
        if (user == null) {
          _navigate(const SignInView());
        } else if (!user.emailVerified) {
          _navigate(const VerifyEmailView());
        } else {
          _navigate(const HomeView());
        }
      },
      // If Firebase is still loading or errored, default to Sign In
      loading: () =>
          _handleNavigation(), // Retry after a short delay if still loading
      error: (_, _) => _navigate(const SignInView()),
    );
  }

  void _navigate(Widget destination) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => destination),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Optional: Keep status bar clean during splash
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade600,
              Colors.cyan.shade400,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _logoAnimation,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: SvgPicture.asset("assets/images/logo.svg"),
              ),
            ),
            const SizedBox(height: 60),
            FadeTransition(
              opacity: _textAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(_textController),
                child: Column(
                  children: [
                    Text(
                      'Sprint14',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Securely synchronizing...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80),
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
