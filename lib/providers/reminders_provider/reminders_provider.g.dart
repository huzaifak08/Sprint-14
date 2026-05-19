// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminders_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RemindersNotifier)
final remindersProvider = RemindersNotifierProvider._();

final class RemindersNotifierProvider
    extends
        $NotifierProvider<RemindersNotifier, List<PendingNotificationRequest>> {
  RemindersNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'remindersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$remindersNotifierHash();

  @$internal
  @override
  RemindersNotifier create() => RemindersNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<PendingNotificationRequest> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<PendingNotificationRequest>>(
        value,
      ),
    );
  }
}

String _$remindersNotifierHash() => r'51d5a03da717a1ebee8ca2c7810c80c7e1477b56';

abstract class _$RemindersNotifier
    extends $Notifier<List<PendingNotificationRequest>> {
  List<PendingNotificationRequest> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              List<PendingNotificationRequest>,
              List<PendingNotificationRequest>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                List<PendingNotificationRequest>,
                List<PendingNotificationRequest>
              >,
              List<PendingNotificationRequest>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
