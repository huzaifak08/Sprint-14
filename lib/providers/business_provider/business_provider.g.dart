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

String _$businessNotifierHash() => r'c4d9ab723fd8a6eca26eb1f263a8dbebc1db1e65';

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
