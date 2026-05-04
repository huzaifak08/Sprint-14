import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sprint_14/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sprint 14',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A73E8),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
