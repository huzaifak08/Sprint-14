import 'dart:math' as math;
import 'package:digital_munshi/helpers/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:digital_munshi/providers/auth_provider/auth_provider.dart';
import 'package:digital_munshi/providers/settings_provider/settings_provider.dart';
import 'package:digital_munshi/services/post_auth_navigation.dart';
import 'package:digital_munshi/views/auth/sign_in_view.dart';
import 'package:digital_munshi/views/auth/verify_email_view.dart';
import 'package:digital_munshi/views/home_view.dart';
import 'dart:developer' as dev;

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView>
    with TickerProviderStateMixin {
  // Entrance: logo pops in, then the text slides up.
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  // Ambient: slow floating shapes and the glow pulse behind the logo.
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  late final Animation<double> _logoScale = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0, 0.6, curve: Curves.elasticOut),
  );
  late final Animation<double> _textFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
  );
  late final Animation<Offset> _textSlide =
      Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _intro,
          curve: const Interval(0.35, 0.9, curve: Curves.easeOutCubic),
        ),
      );

  @override
  void initState() {
    super.initState();
    _handleNavigation();
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    super.dispose();
  }

  Future<void> _handleNavigation() async {
    // Minimum time so the intro animation can play; loading runs meanwhile.
    final minSplash = Future.delayed(const Duration(milliseconds: 1600));

    try {
      // The Firebase session decides signed-in vs signed-out. The Firestore
      // profile can be missing offline; that's not a logout.
      final authUser = await ref.read(authControllerProvider.future);
      // Load the theme/start-screen settings while the animation plays.
      await ref.read(appSettingsProvider.future);
      await minSplash;
      if (!mounted) return;

      if (authUser == null) {
        _replaceWith(const SignInView());
      } else if (!authUser.emailVerified) {
        _replaceWith(const VerifyEmailView());
      } else {
        await openSignedInHome(Navigator.of(context), ref.read);
      }
    } catch (e, s) {
      dev.log('Splash failed: $e', name: 'SplashView', error: e, stackTrace: s);
      await minSplash;
      if (!mounted) return;
      final signedIn = ref.read(authControllerProvider).value != null;
      _replaceWith(signedIn ? const HomeView() : const SignInView());
    }
  }

  void _replaceWith(Widget page) {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => page,
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final on = cs.onPrimary;
    final deep = Color.lerp(cs.primary, Colors.black, 0.45)!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            ThemeData.estimateBrightnessForColor(cs.primary) == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _ambient,
          builder: (context, _) {
            final t = _ambient.value * 2 * math.pi;
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1 + 0.3 * math.sin(t), -1),
                  end: Alignment(1, 1 + 0.3 * math.cos(t)),
                  colors: [cs.primary, deep],
                ),
              ),
              child: Stack(
                // Expand so the content column spans the full width and is
                // centred (it was hugging the left edge).
                fit: StackFit.expand,
                children: [
                  // Soft floating shapes.
                  _blob(on, 260, Alignment(-1.3 + 0.08 * math.sin(t), -0.9)),
                  _blob(on, 200, Alignment(1.4, -0.2 + 0.1 * math.cos(t))),
                  _blob(on, 320, Alignment(0.6 + 0.06 * math.cos(t), 1.4)),
                  SafeArea(
                    child: Column(
                      children: [
                        const Spacer(flex: 3),
                        ScaleTransition(scale: _logoScale, child: _logo(on, t)),
                        const SizedBox(height: 36),
                        FadeTransition(
                          opacity: _textFade,
                          child: SlideTransition(
                            position: _textSlide,
                            child: Column(
                              children: [
                                Text(
                                  appName,
                                  style: TextStyle(
                                    color: on,
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: ShapeDecoration(
                                    shape: const StadiumBorder(),
                                    color: on.withValues(alpha: 0.14),
                                  ),
                                  child: Text(
                                    'Ledgers · Events · Business',
                                    style: TextStyle(
                                      color: on.withValues(alpha: 0.9),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(flex: 4),
                        FadeTransition(
                          opacity: _textFade,
                          child: Column(
                            children: [
                              SizedBox(
                                width: 120,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    minHeight: 4,
                                    color: on,
                                    backgroundColor: on.withValues(alpha: 0.2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Your money, organised',
                                style: TextStyle(
                                  color: on.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _logo(Color on, double t) {
    final pulse = 0.5 + 0.5 * math.sin(t * 2);
    return SizedBox(
      width: 190,
      height: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing glow rings.
          Container(
            width: 170 + 16 * pulse,
            height: 170 + 16 * pulse,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on.withValues(alpha: 0.06 + 0.04 * pulse),
            ),
          ),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on.withValues(alpha: 0.12),
              border: Border.all(color: on.withValues(alpha: 0.25), width: 1.5),
            ),
          ),
          // Logo on a solid disc so it reads on any theme colour.
          Container(
            width: 112,
            height: 112,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: SvgPicture.asset('assets/images/logo.svg'),
          ),
        ],
      ),
    );
  }

  Widget _blob(Color color, double size, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.07),
          ),
        ),
      ),
    );
  }
}
