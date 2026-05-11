import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io' show Platform;

import '../clients/notifications/notification_service.dart';
import '../providers/biometric_provider/biometric_provider.dart';
import '../providers/ledger_provider/ledger_provider.dart';
import '../services/biometric_service.dart';
import 'main_shell.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView>
    with WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initLogic();
  }

  void _initLogic() {
    // Platform-specific gating to prevent crashes on Web
    if (!kIsWeb) {
      _initMobileServices();
    }

    _setupConnectivity();
  }

  void _initMobileServices() {
    requestExactAlarmPermission();
    _notificationService.requestNotificationPermission();
    _notificationService.handleForegroundNotifications(context);
    _notificationService.setUpInteractMessage(context);
  }

  void _setupConnectivity() {
    Connectivity().onConnectivityChanged.listen((result) {
      final isOnline = result.any(
        (r) =>
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.ethernet,
      );

      if (isOnline) {
        ref.read(ledgerProvider.notifier).syncPendingLedgers();
      }
    });
  }

  Future<void> requestExactAlarmPermission() async {
    if (kIsWeb) return;
    if (Platform.isAndroid) {
      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    }
  }

  Future<void> _triggerAuthentication() async {
    final notifier = ref.read(securityProvider.notifier);
    if (notifier.isSecurityEnabled) {
      final success = await BiometricService().authenticate();
      if (success) notifier.setAuthenticated(true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context);
    final securityState = ref.watch(securityProvider);

    // Auto-trigger biometric prompt
    ref.listen(securityProvider, (prev, next) {
      next.whenData((isAuthenticated) {
        if (!isAuthenticated) _triggerAuthentication();
      });
    });

    return securityState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const MainShell(), // Fallback
      data: (isAuthenticated) {
        if (!isAuthenticated) return _buildLockScreen(appTheme);
        return const MainShell(); // Redirect to our adaptive shell
      },
    );
  }

  Widget _buildLockScreen(ThemeData appTheme) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              appTheme.colorScheme.primary.withOpacity(0.05),
              appTheme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset("assets/images/logo.svg", width: 100),
            const SizedBox(height: 40),
            Icon(
              Icons.fingerprint_rounded,
              size: 80,
              color: appTheme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            const Text(
              "Sprint 14 Secured",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              onPressed: _triggerAuthentication,
              style: ElevatedButton.styleFrom(
                backgroundColor: appTheme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("UNLOCK DASHBOARD"),
            ),
          ],
        ),
      ),
    );
  }
}
