import 'package:flutter/material.dart';
import 'package:sprint_14/helpers/responsive_helper.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveHelper.tabletLimit) {
          return desktop;
        } else if (constraints.maxWidth >= ResponsiveHelper.mobileLimit) {
          // Fallback to mobile if tablet layout isn't provided
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}
