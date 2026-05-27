// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BusinessNotifier)
final businessProvider = BusinessNotifierProvider._();

final class BusinessNotifierProvider
    extends $AsyncNotifierProvider<BusinessNotifier, List<BusinessModel>> {
  BusinessNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'businessProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$businessNotifierHash();

  @$internal
  @override
  BusinessNotifier create() => BusinessNotifier();
}

String _$businessNotifierHash() => r'10b8bda57901b9616240c009d7bcf45a25b7309e';

abstract class _$BusinessNotifier extends $AsyncNotifier<List<BusinessModel>> {
  FutureOr<List<BusinessModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<BusinessModel>>, List<BusinessModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<BusinessModel>>, List<BusinessModel>>,
              AsyncValue<List<BusinessModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(singleBusiness)
final singleBusinessProvider = SingleBusinessFamily._();

final class SingleBusinessProvider
    extends
        $FunctionalProvider<
          AsyncValue<BusinessModel>,
          BusinessModel,
          FutureOr<BusinessModel>
        >
    with $FutureModifier<BusinessModel>, $FutureProvider<BusinessModel> {
  SingleBusinessProvider._({
    required SingleBusinessFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'singleBusinessProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$singleBusinessHash();

  @override
  String toString() {
    return r'singleBusinessProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<BusinessModel> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BusinessModel> create(Ref ref) {
    final argument = this.argument as String;
    return singleBusiness(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SingleBusinessProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$singleBusinessHash() => r'c4a29948bc9cc7e1efbc19864d0402350e7861a8';

final class SingleBusinessFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<BusinessModel>, String> {
  SingleBusinessFamily._()
    : super(
        retry: null,
        name: r'singleBusinessProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SingleBusinessProvider call(String businessId) =>
      SingleBusinessProvider._(argument: businessId, from: this);

  @override
  String toString() => r'singleBusinessProvider';
}

@ProviderFor(currentBusinessRole)
final currentBusinessRoleProvider = CurrentBusinessRoleFamily._();

final class CurrentBusinessRoleProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserBusinessPermissions>,
          UserBusinessPermissions,
          FutureOr<UserBusinessPermissions>
        >
    with
        $FutureModifier<UserBusinessPermissions>,
        $FutureProvider<UserBusinessPermissions> {
  CurrentBusinessRoleProvider._({
    required CurrentBusinessRoleFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'currentBusinessRoleProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$currentBusinessRoleHash();

  @override
  String toString() {
    return r'currentBusinessRoleProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<UserBusinessPermissions> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<UserBusinessPermissions> create(Ref ref) {
    final argument = this.argument as String;
    return currentBusinessRole(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentBusinessRoleProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$currentBusinessRoleHash() =>
    r'48d48b2848e3b9f4f0a068959b1df02eefe37af6';

final class CurrentBusinessRoleFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<UserBusinessPermissions>, String> {
  CurrentBusinessRoleFamily._()
    : super(
        retry: null,
        name: r'currentBusinessRoleProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CurrentBusinessRoleProvider call(String businessId) =>
      CurrentBusinessRoleProvider._(argument: businessId, from: this);

  @override
  String toString() => r'currentBusinessRoleProvider';
}
