import 'dart:async' show StreamSubscription, unawaited;
import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:injectable/injectable.dart';

import '../../errors/errors.dart';
import '../../functions/functions.dart';
import '../../utils/utils.dart';
import '../domain/entities/push_device.dart';
import '../domain/repositories/push_device_repository.dart';
import 'device_installation_id_provider.dart';
import 'push_registration_local_store.dart';
import 'push_token_service.dart';

/// [PushTokenService] backed by the real `firebase_messaging` SDK.
///
/// Subscribes to [FirebaseMessaging.onTokenRefresh] once, at construction,
/// so a token rotation re-registers itself for whichever
/// `organizationId`/`userId` this device last registered for (read back
/// from [PushRegistrationLocalStore] — `onTokenRefresh` itself carries no
/// session context). Every public method — and the refresh handler itself —
/// is fully guarded: nothing here ever throws or completes with an
/// unhandled error, matching every other Firebase-backed service in this
/// codebase (`FirebaseAnalyticsService`, `FirebaseCrashReporter`).
@LazySingleton(as: PushTokenService)
final class FirebaseMessagingPushTokenService implements PushTokenService {
  FirebaseMessagingPushTokenService({
    required this.messaging,
    required this.repository,
    required this.deviceIdProvider,
    required this.clientMetadataProvider,
    required this.registrationStore,
  }) {
    _tokenRefreshSubscription = messaging.onTokenRefresh.listen((_) {
      unawaited(_reRegisterAfterTokenRefresh());
    });
  }

  final FirebaseMessaging messaging;
  final PushDeviceRepository repository;
  final DeviceInstallationIdProvider deviceIdProvider;
  final AppClientMetadataProvider clientMetadataProvider;
  final PushRegistrationLocalStore registrationStore;
  late final StreamSubscription<String> _tokenRefreshSubscription;

  /// Cancels the [messaging.onTokenRefresh] subscription. Never called in
  /// production — this service is a process-lifetime singleton, same as
  /// every other Firebase-backed `@LazySingleton` service in this codebase
  /// — but keeps the subscription reachable/disposable from a test.
  @visibleForTesting
  void dispose() {
    unawaited(_tokenRefreshSubscription.cancel());
  }

  @override
  Future<void> registerDevice({
    required String organizationId,
    required String userId,
  }) async {
    try {
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) {
        // No token yet (e.g. permission not requested/granted on a
        // platform that requires it before issuing one, or genuinely
        // offline): not an error — the next `onTokenRefresh`/session change
        // tries again.
        return;
      }

      final deviceId = await deviceIdProvider.resolve();
      final metadata = await clientMetadataProvider.resolve();
      final now = DateTime.now().toUtc();

      final result = await repository.upsert(
        PushDevice(
          id: deviceId,
          organizationId: organizationId,
          userId: userId,
          token: token,
          platform: metadata.platform,
          appVersion: '${metadata.appVersion}+${metadata.buildNumber}',
          createdAt: now,
          lastUsedAt: now,
        ),
      );

      switch (result) {
        case AppSuccess<void>():
          await registrationStore.save(
            PushRegistrationRecord(
              organizationId: organizationId,
              userId: userId,
              deviceId: deviceId,
            ),
          );
        case AppFailure<void>(failure: final failure):
          _logFailure(
            'registerDevice failed to upsert the push device link.',
            failure,
          );
      }
    } catch (error, stackTrace) {
      _log('registerDevice failed unexpectedly.', error, stackTrace);
    }
  }

  @override
  Future<void> unregisterCurrentDevice() async {
    try {
      final record = await registrationStore.read();
      if (record != null) {
        final result = await repository.deactivate(
          organizationId: record.organizationId,
          deviceId: record.deviceId,
        );
        if (result case AppFailure<void>(failure: final failure)) {
          _logFailure(
            'unregisterCurrentDevice failed to deactivate the push device '
            'link.',
            failure,
          );
        }
      }

      // Forces a brand-new FCM token on the next `getToken()` call, so a
      // different user signing in on this same device afterwards never
      // inherits this account's registration token.
      await messaging.deleteToken();
    } catch (error, stackTrace) {
      _log('unregisterCurrentDevice failed unexpectedly.', error, stackTrace);
    } finally {
      await registrationStore.clear();
    }
  }

  Future<void> _reRegisterAfterTokenRefresh() async {
    try {
      final record = await registrationStore.read();
      if (record == null) return;
      await registerDevice(
        organizationId: record.organizationId,
        userId: record.userId,
      );
    } catch (error, stackTrace) {
      _log(
        'Failed to re-register the push device after a token refresh.',
        error,
        stackTrace,
      );
    }
  }

  void _log(String message, Object error, StackTrace stackTrace) {
    developer.log(
      message,
      name: 'vestipro.push_token_service',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _logFailure(String message, Failure failure) {
    developer.log(
      '$message $failure',
      name: 'vestipro.push_token_service',
      level: 900,
    );
  }
}
