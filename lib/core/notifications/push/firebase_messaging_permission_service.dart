import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'push_permission_service.dart';
import 'push_permission_status.dart';

/// [PushPermissionService] backed by the real `firebase_messaging` SDK.
///
/// Never throws: every public method falls back to
/// [PushPermissionStatus.notDetermined] on any SDK/platform-channel error,
/// same defensive pattern as `FirebaseAnalyticsService`/
/// `FirebaseCrashReporter` — a broken permission check must never crash the
/// caller.
@LazySingleton(as: PushPermissionService)
final class FirebaseMessagingPermissionService
    implements PushPermissionService {
  FirebaseMessagingPermissionService(this._messaging);

  final FirebaseMessaging _messaging;

  static const _alreadyAskedKey = 'push_permission_already_asked';

  @override
  Future<PushPermissionStatus> currentStatus() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return _fromAuthorizationStatus(settings.authorizationStatus);
    } catch (error, stackTrace) {
      _log(
        'currentStatus failed to read notification settings.',
        error,
        stackTrace,
      );
      return PushPermissionStatus.notDetermined;
    }
  }

  @override
  Future<PushPermissionStatus> requestIfNotAlreadyAsked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyAsked = prefs.getBool(_alreadyAskedKey) ?? false;
      if (alreadyAsked) {
        // Never repeats the OS prompt: the OS itself also would not show it
        // again after an explicit denial, but this local flag also covers
        // platforms/cases where the OS *would* otherwise re-prompt.
        return currentStatus();
      }

      final settings = await _messaging.requestPermission();
      await prefs.setBool(_alreadyAskedKey, true);
      return _fromAuthorizationStatus(settings.authorizationStatus);
    } catch (error, stackTrace) {
      _log(
        'requestIfNotAlreadyAsked failed to request permission.',
        error,
        stackTrace,
      );
      return PushPermissionStatus.notDetermined;
    }
  }

  PushPermissionStatus _fromAuthorizationStatus(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
        return PushPermissionStatus.authorized;
      case AuthorizationStatus.denied:
        return PushPermissionStatus.denied;
      case AuthorizationStatus.provisional:
        return PushPermissionStatus.provisional;
      case AuthorizationStatus.notDetermined:
        return PushPermissionStatus.notDetermined;
    }
  }

  void _log(String message, Object error, StackTrace stackTrace) {
    developer.log(
      message,
      name: 'vestipro.push_permission_service',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
