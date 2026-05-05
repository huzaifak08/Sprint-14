import 'package:flutter/material.dart';
import 'package:sprint_14/views/home_view.dart';
import 'package:sprint_14/views/splash_view.dart';

class RouteName {
  static const String splashView = 'splash_view';
  static const String appsView = 'apps_view';
  static const String homeView = 'home_view';
}

class Routes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteName.splashView:
        return MaterialPageRoute(builder: (context) => const SplashView());

      case RouteName.homeView:
        return MaterialPageRoute(builder: (context) => const HomeView());

      // case RouteName.appsView:
      //   return MaterialPageRoute(builder: (context) => const AppsView());

      default:
        return MaterialPageRoute(
          builder: (context) =>
              const Scaffold(body: Center(child: Text('No Route Defined'))),
        );
    }
  }
}
