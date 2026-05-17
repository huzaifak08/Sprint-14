// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participant_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ParticipantNotifier)
final participantProvider = ParticipantNotifierFamily._();

final class ParticipantNotifierProvider
    extends
        $AsyncNotifierProvider<ParticipantNotifier, List<ParticipantModel>> {
  ParticipantNotifierProvider._({
    required ParticipantNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'participantProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$participantNotifierHash();

  @override
  String toString() {
    return r'participantProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ParticipantNotifier create() => ParticipantNotifier();

  @override
  bool operator ==(Object other) {
    return other is ParticipantNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$participantNotifierHash() =>
    r'08ae75556611c2da24517fcd1b8ebbdb7a679178';

final class ParticipantNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ParticipantNotifier,
          AsyncValue<List<ParticipantModel>>,
          List<ParticipantModel>,
          FutureOr<List<ParticipantModel>>,
          String
        > {
  ParticipantNotifierFamily._()
    : super(
        retry: null,
        name: r'participantProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  ParticipantNotifierProvider call(String businessId) =>
      ParticipantNotifierProvider._(argument: businessId, from: this);

  @override
  String toString() => r'participantProvider';
}

abstract class _$ParticipantNotifier
    extends $AsyncNotifier<List<ParticipantModel>> {
  late final _$args = ref.$arg as String;
  String get businessId => _$args;

  FutureOr<List<ParticipantModel>> build(String businessId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<ParticipantModel>>, List<ParticipantModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<ParticipantModel>>,
                List<ParticipantModel>
              >,
              AsyncValue<List<ParticipantModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
