import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprint_14/cache/cache_owner.dart';
import 'package:sprint_14/cache/init_cache.dart';
import 'package:sprint_14/helpers/app_data.dart';
import 'package:sprint_14/helpers/theme.dart';
import 'package:sprint_14/providers/app_provider_container.dart';
import 'package:sprint_14/providers/settings_provider/settings_provider.dart';
import 'package:sprint_14/services/routes_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Cache:
  await LocalCacheManager.initDatabase();

  await Firebase.initializeApp();

  // Make sure the local cache belongs to the signed-in account (if any)
  // before any provider reads it.
  final existingUser = FirebaseAuth.instance.currentUser;
  if (existingUser != null) await CacheOwner.ensureOwner(existingUser.uid);

  // Notifications:
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  // A single provider container for the whole app. Non-widget code
  // (e.g. utils/save_send_notification.dart) reads the same instance.
  runApp(
    UncontrolledProviderScope(
      container: AppProviderContainer.instance,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    return settings.when(
      data: (config) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: AppData.shared.navigatorKey,
          title: 'Sprint14',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: config.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: RouteName.splashView,
          onGenerateRoute: Routes.generateRoute,
        );
      },
      loading: () => const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (err, stack) => MaterialApp(
        home: Scaffold(body: Center(child: Text("Init Error: $err"))),
      ),
    );
  }
}

// dart run build_runner build --delete-conflicting-outputs
