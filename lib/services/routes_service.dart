import 'package:flutter/material.dart';
import 'package:digital_munshi/views/home_view.dart';
import 'package:digital_munshi/views/splash_view.dart';

class RouteName {
  static const String splashView = 'splash_view';
  static const String homeView = 'home_view';
}

class Routes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteName.splashView:
        return MaterialPageRoute(builder: (context) => const SplashView());

      case RouteName.homeView:
        return MaterialPageRoute(builder: (context) => const HomeView());

      default:
        return MaterialPageRoute(
          builder: (context) =>
              const Scaffold(body: Center(child: Text('No Route Defined'))),
        );
    }
  }
}
