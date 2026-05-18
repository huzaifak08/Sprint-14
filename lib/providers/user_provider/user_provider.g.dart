// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserNotifier)
final userProvider = UserNotifierFamily._();

final class UserNotifierProvider
    extends $AsyncNotifierProvider<UserNotifier, UserModel?> {
  UserNotifierProvider._({
    required UserNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'userProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userNotifierHash();

  @override
  String toString() {
    return r'userProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  UserNotifier create() => UserNotifier();

  @override
  bool operator ==(Object other) {
    return other is UserNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userNotifierHash() => r'7a823dbd2e9f309773b93303ef2f85cdd09e9b9d';

final class UserNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          UserNotifier,
          AsyncValue<UserModel?>,
          UserModel?,
          FutureOr<UserModel?>,
          String
        > {
  UserNotifierFamily._()
    : super(
        retry: null,
        name: r'userProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  UserNotifierProvider call(String userId) =>
      UserNotifierProvider._(argument: userId, from: this);

  @override
  String toString() => r'userProvider';
}

abstract class _$UserNotifier extends $AsyncNotifier<UserModel?> {
  late final _$args = ref.$arg as String;
  String get userId => _$args;

  FutureOr<UserModel?> build(String userId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<UserModel?>, UserModel?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<UserModel?>, UserModel?>,
              AsyncValue<UserModel?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
