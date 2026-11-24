import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:digital_munshi/cache/sync/pending_sync.dart';
import 'package:digital_munshi/models/business_model.dart';
import 'package:digital_munshi/providers/business_provider/business_provider.dart';
import 'package:digital_munshi/providers/current_user_provider/current_user_provider.dart';
import 'package:digital_munshi/providers/settings_provider/settings_provider.dart';
import 'package:digital_munshi/views/business_views/business_dashboard_view/business_dashboard_view.dart';
import 'package:digital_munshi/views/home_view.dart';

/// Opens the signed-in part of the app, honouring the "Start screen"
/// setting (Home, or straight into a business dashboard on top of Home).
///
/// Used by the splash screen, sign-in and email verification so all three
/// behave the same without showing the splash again after signing in.
Future<void> openSignedInHome(
  NavigatorState navigator,
  ProviderReader read,
) async {
  BusinessModel? startBusiness;
  try {
    final settings = await read(appSettingsProvider.future);
    final targetId = settings.defaultBusinessId;
    if (targetId != null) {
      // The business list needs the profile; don't wait long for either.
      await read(
        currentUserProvider.future,
      ).timeout(const Duration(seconds: 4));
      final businesses = await read(
        businessProvider.future,
      ).timeout(const Duration(seconds: 3));
      for (final b in businesses) {
        if (b.id == targetId) startBusiness = b;
      }
    }
  } catch (e) {
    dev.log('Start screen lookup skipped: $e', name: 'PostAuthNavigation');
  }

  navigator.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const HomeView()),
    (route) => false,
  );
  if (startBusiness != null) {
    final id = startBusiness.id;
    navigator.push(
      MaterialPageRoute(builder: (_) => BusinessDashboardView(businessId: id)),
    );
  }
}
