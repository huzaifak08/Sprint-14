import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprint_14/cache/init_cache.dart';
import 'package:sprint_14/helpers/app_data.dart';
import 'package:sprint_14/helpers/theme.dart';
import 'package:sprint_14/providers/app_provider_container.dart';
import 'package:sprint_14/providers/theme_provider/theme_provider.dart';
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

  // Notifications:
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  runApp(
    ProviderScope(
      child: UncontrolledProviderScope(
        container: AppProviderContainer.instance,
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeProvider = ref.watch(themeNotifier);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: AppData.shared.navigatorKey,
      title: 'Sprint14',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeProvider.themeMode,
      initialRoute: RouteName.splashView,
      onGenerateRoute: Routes.generateRoute,
    );
  }
}

// dart run build_runner build --delete-conflicting-outputs
