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
    extends $AsyncNotifierProvider<LedgerNotifier, List<LedgerModel>> {
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
}

String _$ledgerNotifierHash() => r'c3c684c79f014cd41fbaff786b46f196a9391039';

abstract class _$LedgerNotifier extends $AsyncNotifier<List<LedgerModel>> {
  FutureOr<List<LedgerModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<LedgerModel>>, List<LedgerModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<LedgerModel>>, List<LedgerModel>>,
              AsyncValue<List<LedgerModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(singleLedger)
final singleLedgerProvider = SingleLedgerFamily._();

final class SingleLedgerProvider
    extends
        $FunctionalProvider<
          AsyncValue<LedgerModel>,
          LedgerModel,
          FutureOr<LedgerModel>
        >
    with $FutureModifier<LedgerModel>, $FutureProvider<LedgerModel> {
  SingleLedgerProvider._({
    required SingleLedgerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'singleLedgerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$singleLedgerHash();

  @override
  String toString() {
    return r'singleLedgerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<LedgerModel> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LedgerModel> create(Ref ref) {
    final argument = this.argument as String;
    return singleLedger(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SingleLedgerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$singleLedgerHash() => r'46aae20fc74ee11f48a72dcb78ba2da6c035c057';

final class SingleLedgerFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<LedgerModel>, String> {
  SingleLedgerFamily._()
    : super(
        retry: null,
        name: r'singleLedgerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SingleLedgerProvider call(String ledgerId) =>
      SingleLedgerProvider._(argument: ledgerId, from: this);

  @override
  String toString() => r'singleLedgerProvider';
}
