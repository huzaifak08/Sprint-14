import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sprint_14/models/business_model.dart';
import 'package:sprint_14/providers/auth_provider/auth_provider.dart';
import 'package:sprint_14/providers/business_provider/business_provider.dart';
import 'package:sprint_14/providers/settings_provider/settings_provider.dart';
import 'package:sprint_14/providers/user_provider/user_provider.dart';
import 'package:sprint_14/views/auth/sign_in_view.dart';
import 'package:sprint_14/views/auth/verify_email_view.dart';
import 'package:sprint_14/views/business_views/business_dashboard_view.dart';
import 'package:sprint_14/views/home_view.dart';
import 'dart:developer' as dev;

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
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _handleNavigation();
  }

  void _setupAnimations() {
    // Logo scale controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Text fade & slide controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut, // Gives that premium "pop" effect
    );

    _textOpacity = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
        );

    // Start animations with slight stagger
    _logoController.forward();
    Future.delayed(
      const Duration(milliseconds: 600),
      () => _textController.forward(),
    );
  }

  Future<void> _handleNavigation() async {
    dev.log('🚀 Navigation sequence initiated', name: 'SplashView');

    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // 1. 🔥 FIRST: Wait for the UserProvider to be ready
    // This ensures the BusinessNotifier has a UID when it builds.
    dev.log('👤 Waiting for User session...', name: 'SplashView');
    final user = await ref.read(userProvider.future);

    if (user == null) {
      dev.log(
        '❌ No user session found. Navigating to SignInView.',
        name: 'SplashView',
      );
      _navigate(const SignInView());
      return;
    }

    // 2. 🔥 SECOND: Now that we have a user, get the businesses
    dev.log(
      '📦 User ready. Initializing and awaiting Business list...',
      name: 'SplashView',
    );

    try {
      final List<BusinessModel> businessList = await ref.read(
        businessProvider.future,
      );
      dev.log(
        '✅ Business list loaded. Items found: ${businessList.length}',
        name: 'SplashView',
      );

      final authState = ref.read(authControllerProvider);
      final settingsAsync = ref.read(appSettingsProvider);

      authState.when(
        data: (user) {
          if (user?.emailVerified == false) {
            _navigate(const VerifyEmailView());
          } else {
            final settings = settingsAsync.value;
            final targetId = settings?.defaultBusinessId;

            if (targetId != null) {
              final business = businessList.cast<BusinessModel?>().firstWhere(
                (b) => b?.id == targetId,
                orElse: () => null,
              );

              if (business != null) {
                dev.log(
                  '🎯 Match found: ${business.name}. Navigating to Dashboard.',
                  name: 'SplashView',
                );
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeView()),
                  (route) => false,
                );
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BusinessDashboardView(business: business),
                  ),
                );
                return;
              }
            }
            _navigate(const HomeView());
          }
        },
        loading: () => _handleNavigation(),
        error: (e, s) => _navigate(const SignInView()),
      );
    } catch (e, s) {
      dev.log('🚨 Failed: $e', name: 'SplashView', error: e, stackTrace: s);
      _navigate(const HomeView());
    }
  }

  void _navigate(Widget dest) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => dest),
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
            // RESTORED: Animated Logo with Scale & Shadow
            ScaleTransition(
              scale: _logoAnimation,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: SvgPicture.asset("assets/images/logo.svg"),
              ),
            ),
            const SizedBox(height: 50),

            // RESTORED: Animated Text (Fade + Slide)
            FadeTransition(
              opacity: _textOpacity,
              child: SlideTransition(
                position: _textSlide,
                child: Column(
                  children: [
                    Text(
                      'Sprint14',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'SECURE RETAIL ENGINE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80),

            // Subtle loading indicator
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white38),
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
