// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LedgerNotifier)
final ledgerProvider = LedgerNotifierProvider._();

final class LedgerNotifierProvider
    extends $NotifierProvider<LedgerNotifier, List<LedgerModel>> {
  LedgerNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ledgerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ledgerNotifierHash();

  @$internal
  @override
  LedgerNotifier create() => LedgerNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<LedgerModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<LedgerModel>>(value),
    );
  }
}

String _$ledgerNotifierHash() => r'42d04dc8fb7bd8491dca23448987bb09f753bdb0';

abstract class _$LedgerNotifier extends $Notifier<List<LedgerModel>> {
  List<LedgerModel> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<LedgerModel>, List<LedgerModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<LedgerModel>, List<LedgerModel>>,
              List<LedgerModel>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
