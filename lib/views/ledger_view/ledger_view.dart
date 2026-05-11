import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprint_14/views/ledger_view/ledger_mobile.dart';
import '../../components/responsive_layout.dart';
import 'ledger_desktop.dart';

class LedgerView extends ConsumerWidget {
  const LedgerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ResponsiveLayout(
      mobile: LedgerMobile(),
      desktop: LedgerDesktop(),
    );
  }
}
