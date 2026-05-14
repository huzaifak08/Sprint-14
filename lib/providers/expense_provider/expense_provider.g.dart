// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ExpenseNotifier)
final expenseProvider = ExpenseNotifierFamily._();

final class ExpenseNotifierProvider
    extends $AsyncNotifierProvider<ExpenseNotifier, List<ExpenseModel>> {
  ExpenseNotifierProvider._({
    required ExpenseNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'expenseProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$expenseNotifierHash();

  @override
  String toString() {
    return r'expenseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ExpenseNotifier create() => ExpenseNotifier();

  @override
  bool operator ==(Object other) {
    return other is ExpenseNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$expenseNotifierHash() => r'10450bb9c000b3d5e58832db8832a59b749457af';

final class ExpenseNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ExpenseNotifier,
          AsyncValue<List<ExpenseModel>>,
          List<ExpenseModel>,
          FutureOr<List<ExpenseModel>>,
          String
        > {
  ExpenseNotifierFamily._()
    : super(
        retry: null,
        name: r'expenseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  ExpenseNotifierProvider call(String businessId) =>
      ExpenseNotifierProvider._(argument: businessId, from: this);

  @override
  String toString() => r'expenseProvider';
}

abstract class _$ExpenseNotifier extends $AsyncNotifier<List<ExpenseModel>> {
  late final _$args = ref.$arg as String;
  String get businessId => _$args;

  FutureOr<List<ExpenseModel>> build(String businessId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<ExpenseModel>>, List<ExpenseModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ExpenseModel>>, List<ExpenseModel>>,
              AsyncValue<List<ExpenseModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
