// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_scheduler_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(notificationSchedulerService)
final notificationSchedulerServiceProvider =
    NotificationSchedulerServiceProvider._();

final class NotificationSchedulerServiceProvider
    extends
        $FunctionalProvider<
          NotificationSchedulerService,
          NotificationSchedulerService,
          NotificationSchedulerService
        >
    with $Provider<NotificationSchedulerService> {
  NotificationSchedulerServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationSchedulerServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationSchedulerServiceHash();

  @$internal
  @override
  $ProviderElement<NotificationSchedulerService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationSchedulerService create(Ref ref) {
    return notificationSchedulerService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationSchedulerService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationSchedulerService>(value),
    );
  }
}

String _$notificationSchedulerServiceHash() =>
    r'acaeb4f847e4f1d1bc295c74541e3135b5b54137';
