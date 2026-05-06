import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sprint_14/clients/notifications/notification_service.dart';
import 'package:sprint_14/providers/biometric_provider/biometric_provider.dart';
import 'package:sprint_14/providers/ledger_provider/ledger_provider.dart';
import 'package:sprint_14/services/biometric_service.dart';
import 'package:sprint_14/views/add_or_update_ledger_view.dart';
import 'package:sprint_14/views/business_views/business_view.dart';
import 'package:sprint_14/views/ledger_view/ledger_view.dart';
import 'package:sprint_14/views/reminders_view.dart';
import 'package:sprint_14/views/settings_view.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView>
    with WidgetsBindingObserver {
  int selectedView = 0;
  late PageController _pageController;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: selectedView);
    WidgetsBinding.instance.addObserver(this);
    _initLogic();
  }

  void _initLogic() {
    // ref.watch(appDataProvider).value;

    requestExactAlarmPermission();
    _notificationService.requestNotificationPermission();
    _notificationService.handleForegroundNotifications(context);
    _notificationService.setUpInteractMessage(context);

    Connectivity().onConnectivityChanged.listen((result) {
      if (result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.mobile)) {
        // ref.read(projectNotifierProvider.notifier).syncPendingProjects();
        ref.read(ledgerProvider.notifier).syncPendingLedgers();
      }
    });
  }

  Future<void> _triggerAuthentication() async {
    final notifier = ref.read(securityProvider.notifier);

    // Only trigger if security is actually enabled in settings
    if (notifier.isSecurityEnabled) {
      final success = await BiometricService().authenticate();
      if (success) {
        notifier.setAuthenticated(true);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<bool> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.scheduleExactAlarm.request();
      return status.isGranted;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context);

    // 1. Watch the AsyncValue from the provider
    final securityState = ref.watch(securityProvider);

    // 2. Listen for state changes to auto-trigger the prompt
    ref.listen(securityProvider, (previous, next) {
      next.whenData((isAuthenticated) {
        if (!isAuthenticated) {
          _triggerAuthentication();
        }
      });
    });

    // 3. Handle the UI based on the AsyncValue states
    return securityState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => _buildMainUI(appTheme), // Fallback if error
      data: (isAuthenticated) {
        if (!isAuthenticated) {
          return _buildLockScreen(appTheme);
        }
        return _buildMainUI(appTheme);
      },
    );
  }

  // --- UI Sections ---

  Widget _buildLockScreen(ThemeData appTheme) {
    return Scaffold(
      backgroundColor: appTheme.scaffoldBackgroundColor,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              appTheme.colorScheme.primary.withValues(alpha: 0.05),
              appTheme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'app_logo',
              child: SvgPicture.asset("assets/images/logo.svg", width: 100),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: appTheme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fingerprint_rounded,
                size: 60,
                color: appTheme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Sprint14 Secured",
              style: appTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please authenticate to access your data",
              style: appTheme.textTheme.bodyMedium?.copyWith(
                color: appTheme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.6,
                ),
              ),
            ),
            const SizedBox(height: 60),
            ElevatedButton.icon(
              onPressed: _triggerAuthentication,
              icon: const Icon(Icons.lock_open_rounded),
              label: const Text("UNLOCK APP"),
              style: ElevatedButton.styleFrom(
                backgroundColor: appTheme.colorScheme.primary,
                foregroundColor: appTheme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainUI(ThemeData appTheme) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Sprint14'),
        titleSpacing: 10,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: SvgPicture.asset("assets/images/logo.svg"),
        ),
        actions: [
          _buildNotificationButton(),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsView()),
            ),
          ),
        ],
        bottom: _buildSegmentedToggle(appTheme),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => selectedView = index),
        children: const [LedgerView(), BusinessView()],
      ),
      floatingActionButton: selectedView == 0
          ? FloatingActionButton(
              backgroundColor: appTheme.colorScheme.primary,
              child: Icon(Icons.add, color: appTheme.colorScheme.onPrimary),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddOrUpdateLedgerView(),
                ),
              ),
            )
          : SizedBox.shrink(),
    );
  }

  PreferredSizeWidget _buildSegmentedToggle(ThemeData appTheme) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SegmentedButton<int>(
          segments: const [
            ButtonSegment(
              value: 0,
              label: Text("Ledger"),
              icon: Icon(Icons.account_balance_wallet_rounded),
            ),
            ButtonSegment(
              value: 1,
              label: Text("Business"),
              icon: Icon(Icons.business),
            ),
          ],
          selected: {selectedView},
          onSelectionChanged: (value) {
            setState(() => selectedView = value.first);
            _pageController.animateToPage(
              value.first,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: appTheme.colorScheme.primary,
            selectedForegroundColor: appTheme.colorScheme.onPrimary,
            side: BorderSide(color: appTheme.colorScheme.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: CircleAvatar(
        backgroundColor: const Color(0xFF4285F4),
        child: IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RemindersView()),
          ),
          icon: const Icon(Icons.notifications, color: Colors.white),
        ),
      ),
    );
  }
}
