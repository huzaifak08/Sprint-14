import 'dart:developer' as dev;
import 'package:flutter_riverpod/misc.dart';
import 'package:sprint_14/cache/init_cache.dart';
import 'package:sprint_14/cache/sync/sync_utils.dart';
import 'package:sprint_14/cache/tables/expense_table.dart';
import 'package:sprint_14/cache/tables/participant_table.dart';
import 'package:sprint_14/cache/tables/product_table.dart';
import 'package:sprint_14/cache/tables/sale_table.dart';
import 'package:sprint_14/providers/business_provider/business_provider.dart';
import 'package:sprint_14/providers/event_ledger_provider/event_ledger_provider.dart';
import 'package:sprint_14/providers/expense_provider/expense_provider.dart';
import 'package:sprint_14/providers/ledger_provider/ledger_provider.dart';
import 'package:sprint_14/providers/notification_provider/notification_provider.dart';
import 'package:sprint_14/providers/participant_provider/participant_provider.dart';
import 'package:sprint_14/providers/product_provider/product_provider.dart';
import 'package:sprint_14/providers/sale_provider/sale_provider.dart';

/// Pushes every pending local change to the cloud (best effort).
/// Used before logout and when connectivity comes back.
///
/// [read] is `ref.read` from either a provider `Ref` or a `WidgetRef`.
typedef ProviderReader = T Function<T>(ProviderListenable<T> provider);

Future<void> syncAllPending(ProviderReader read) async {
  if (!await isOnline()) return;

  Future<void> safe(String name, Future<void> Function() task) async {
    try {
      await task();
    } catch (e) {
      dev.log('Pending sync failed for $name: $e', name: 'PendingSync');
    }
  }

  await safe('businesses', () {
    return read(businessProvider.notifier).syncPending();
  });
  await safe('ledgers', () {
    return read(ledgerProvider.notifier).syncPendingLedgers();
  });
  await safe('event ledgers', () {
    return read(eventLedgerProvider.notifier).syncPendingRecordsToCloud();
  });
  await safe('notifications', () {
    return read(notificationProvider.notifier).syncPendingNotifications();
  });

  // Per-business data: only touch businesses that actually have pending rows.
  final saleIds = await _pendingBusinessIds(SaleTable.tableName);
  final productIds = await _pendingBusinessIds(ProductTable.tableName);
  final expenseIds = await _pendingBusinessIds(ExpenseTable.tableName);
  final participantIds = await _pendingBusinessIds(ParticipantTable.tableName);

  for (final id in saleIds) {
    await safe('sales', () {
      return read(saleProvider(id).notifier).syncPending(id);
    });
  }
  for (final id in productIds) {
    await safe('products', () {
      return read(productProvider(id).notifier).syncPending(id);
    });
  }
  for (final id in expenseIds) {
    await safe('expenses', () {
      return read(expenseProvider(id).notifier).syncPending(id);
    });
  }
  if (participantIds.isNotEmpty) {
    // syncPendingParticipants already covers every business.
    await safe('participants', () {
      return read(participantProvider(participantIds.first).notifier)
          .syncPendingParticipants();
    });
  }
}

Future<List<String>> _pendingBusinessIds(String table) async {
  final rows = await LocalCacheManager.queryAllRows(
    table,
    where: 'isSynced = ?',
    whereArgs: [0],
  );
  return rows
      .map((r) => r['businessId']?.toString())
      .whereType<String>()
      .toSet()
      .toList();
}

