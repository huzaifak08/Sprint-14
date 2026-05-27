// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_ledger_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EventLedgerNotifier)
final eventLedgerProvider = EventLedgerNotifierProvider._();

final class EventLedgerNotifierProvider
    extends
        $AsyncNotifierProvider<EventLedgerNotifier, List<EventLedgerModel>> {
  EventLedgerNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventLedgerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventLedgerNotifierHash();

  @$internal
  @override
  EventLedgerNotifier create() => EventLedgerNotifier();
}

String _$eventLedgerNotifierHash() =>
    r'2d6297df62f2bdaf2d629d740dca3ec2838cb51b';

abstract class _$EventLedgerNotifier
    extends $AsyncNotifier<List<EventLedgerModel>> {
  FutureOr<List<EventLedgerModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<EventLedgerModel>>, List<EventLedgerModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<EventLedgerModel>>,
                List<EventLedgerModel>
              >,
              AsyncValue<List<EventLedgerModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ActiveEventTransactions)
final activeEventTransactionsProvider = ActiveEventTransactionsFamily._();

final class ActiveEventTransactionsProvider
    extends
        $AsyncNotifierProvider<
          ActiveEventTransactions,
          List<EventTransactionModel>
        > {
  ActiveEventTransactionsProvider._({
    required ActiveEventTransactionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'activeEventTransactionsProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$activeEventTransactionsHash();

  @override
  String toString() {
    return r'activeEventTransactionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ActiveEventTransactions create() => ActiveEventTransactions();

  @override
  bool operator ==(Object other) {
    return other is ActiveEventTransactionsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$activeEventTransactionsHash() =>
    r'868a6d9fe32c3a3be97b78833673fd7f15894cc5';

final class ActiveEventTransactionsFamily extends $Family
    with
        $ClassFamilyOverride<
          ActiveEventTransactions,
          AsyncValue<List<EventTransactionModel>>,
          List<EventTransactionModel>,
          FutureOr<List<EventTransactionModel>>,
          String
        > {
  ActiveEventTransactionsFamily._()
    : super(
        retry: null,
        name: r'activeEventTransactionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  ActiveEventTransactionsProvider call(String eventId) =>
      ActiveEventTransactionsProvider._(argument: eventId, from: this);

  @override
  String toString() => r'activeEventTransactionsProvider';
}

abstract class _$ActiveEventTransactions
    extends $AsyncNotifier<List<EventTransactionModel>> {
  late final _$args = ref.$arg as String;
  String get eventId => _$args;

  FutureOr<List<EventTransactionModel>> build(String eventId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<EventTransactionModel>>,
              List<EventTransactionModel>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<EventTransactionModel>>,
                List<EventTransactionModel>
              >,
              AsyncValue<List<EventTransactionModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(EventParticipantsRoster)
final eventParticipantsRosterProvider = EventParticipantsRosterFamily._();

final class EventParticipantsRosterProvider
    extends
        $AsyncNotifierProvider<
          EventParticipantsRoster,
          List<EventParticipantModel>
        > {
  EventParticipantsRosterProvider._({
    required EventParticipantsRosterFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'eventParticipantsRosterProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventParticipantsRosterHash();

  @override
  String toString() {
    return r'eventParticipantsRosterProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  EventParticipantsRoster create() => EventParticipantsRoster();

  @override
  bool operator ==(Object other) {
    return other is EventParticipantsRosterProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventParticipantsRosterHash() =>
    r'a3f39f070cdfccf23497b9902066701ff31efb3d';

final class EventParticipantsRosterFamily extends $Family
    with
        $ClassFamilyOverride<
          EventParticipantsRoster,
          AsyncValue<List<EventParticipantModel>>,
          List<EventParticipantModel>,
          FutureOr<List<EventParticipantModel>>,
          String
        > {
  EventParticipantsRosterFamily._()
    : super(
        retry: null,
        name: r'eventParticipantsRosterProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  EventParticipantsRosterProvider call(String eventId) =>
      EventParticipantsRosterProvider._(argument: eventId, from: this);

  @override
  String toString() => r'eventParticipantsRosterProvider';
}

abstract class _$EventParticipantsRoster
    extends $AsyncNotifier<List<EventParticipantModel>> {
  late final _$args = ref.$arg as String;
  String get eventId => _$args;

  FutureOr<List<EventParticipantModel>> build(String eventId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<EventParticipantModel>>,
              List<EventParticipantModel>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<EventParticipantModel>>,
                List<EventParticipantModel>
              >,
              AsyncValue<List<EventParticipantModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(singleEventLedger)
final singleEventLedgerProvider = SingleEventLedgerFamily._();

final class SingleEventLedgerProvider
    extends
        $FunctionalProvider<
          AsyncValue<EventLedgerModel>,
          EventLedgerModel,
          FutureOr<EventLedgerModel>
        >
    with $FutureModifier<EventLedgerModel>, $FutureProvider<EventLedgerModel> {
  SingleEventLedgerProvider._({
    required SingleEventLedgerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'singleEventLedgerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$singleEventLedgerHash();

  @override
  String toString() {
    return r'singleEventLedgerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<EventLedgerModel> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<EventLedgerModel> create(Ref ref) {
    final argument = this.argument as String;
    return singleEventLedger(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SingleEventLedgerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$singleEventLedgerHash() => r'370364c358727431199094f05f32ce8003dee593';

final class SingleEventLedgerFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<EventLedgerModel>, String> {
  SingleEventLedgerFamily._()
    : super(
        retry: null,
        name: r'singleEventLedgerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SingleEventLedgerProvider call(String eventId) =>
      SingleEventLedgerProvider._(argument: eventId, from: this);

  @override
  String toString() => r'singleEventLedgerProvider';
}

/// Dynamic Roster Dropdown Category Aggregator Lookup Provider.
/// Pulls unique strings used in existing local transaction categories to feed custom workspace entries.

@ProviderFor(dynamicEventCategories)
final dynamicEventCategoriesProvider = DynamicEventCategoriesFamily._();

/// Dynamic Roster Dropdown Category Aggregator Lookup Provider.
/// Pulls unique strings used in existing local transaction categories to feed custom workspace entries.

final class DynamicEventCategoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  /// Dynamic Roster Dropdown Category Aggregator Lookup Provider.
  /// Pulls unique strings used in existing local transaction categories to feed custom workspace entries.
  DynamicEventCategoriesProvider._({
    required DynamicEventCategoriesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'dynamicEventCategoriesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dynamicEventCategoriesHash();

  @override
  String toString() {
    return r'dynamicEventCategoriesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    final argument = this.argument as String;
    return dynamicEventCategories(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DynamicEventCategoriesProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dynamicEventCategoriesHash() =>
    r'48b8808844c4306c30dbf18664fde59ab262ba8c';

/// Dynamic Roster Dropdown Category Aggregator Lookup Provider.
/// Pulls unique strings used in existing local transaction categories to feed custom workspace entries.

final class DynamicEventCategoriesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<String>>, String> {
  DynamicEventCategoriesFamily._()
    : super(
        retry: null,
        name: r'dynamicEventCategoriesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Dynamic Roster Dropdown Category Aggregator Lookup Provider.
  /// Pulls unique strings used in existing local transaction categories to feed custom workspace entries.

  DynamicEventCategoriesProvider call(String eventId) =>
      DynamicEventCategoriesProvider._(argument: eventId, from: this);

  @override
  String toString() => r'dynamicEventCategoriesProvider';
}

@ProviderFor(eventFinancialSummary)
final eventFinancialSummaryProvider = EventFinancialSummaryFamily._();

final class EventFinancialSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<EventFinancialSummary>,
          EventFinancialSummary,
          FutureOr<EventFinancialSummary>
        >
    with
        $FutureModifier<EventFinancialSummary>,
        $FutureProvider<EventFinancialSummary> {
  EventFinancialSummaryProvider._({
    required EventFinancialSummaryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'eventFinancialSummaryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventFinancialSummaryHash();

  @override
  String toString() {
    return r'eventFinancialSummaryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<EventFinancialSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<EventFinancialSummary> create(Ref ref) {
    final argument = this.argument as String;
    return eventFinancialSummary(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EventFinancialSummaryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventFinancialSummaryHash() =>
    r'c23c4abdadc3c77ebecaccf780dbd7f3fe011c6b';

final class EventFinancialSummaryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<EventFinancialSummary>, String> {
  EventFinancialSummaryFamily._()
    : super(
        retry: null,
        name: r'eventFinancialSummaryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EventFinancialSummaryProvider call(String eventId) =>
      EventFinancialSummaryProvider._(argument: eventId, from: this);

  @override
  String toString() => r'eventFinancialSummaryProvider';
}
