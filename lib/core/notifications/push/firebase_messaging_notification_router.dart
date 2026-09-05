import 'dart:async' show StreamController, StreamSubscription;
import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:injectable/injectable.dart';

import 'push_notification_payload.dart';
import 'push_notification_router.dart';

/// [PushNotificationRouter] backed by the real `firebase_messaging` SDK.
///
/// Subscribes to `onMessage`/`onMessageOpenedApp` once, at construction —
/// `bootstrap.dart`'s `configurePushNotificationLifecycle` resolves this
/// eagerly on app start specifically so those subscriptions exist before
/// any push could arrive, since being a lazy `@LazySingleton` like every
/// other DI-registered service here would otherwise only start listening
/// the first time some future UI (TASK-151) happens to resolve it.
@LazySingleton(as: PushNotificationRouter)
final class FirebaseMessagingNotificationRouter
    implements PushNotificationRouter {
  FirebaseMessagingNotificationRouter(this._messaging) {
    // `onMessage`/`onMessageOpenedApp` are static streams on the SDK class
    // itself (unlike `getToken`/`getInitialMessage`, which are instance
    // methods) — `_messaging` is still held for `getInitialMessage()` below.
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _handleMessage,
    );
    _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleMessage,
    );
  }

  final FirebaseMessaging _messaging;
  final StreamController<PushNotificationPayload> _controller =
      StreamController<PushNotificationPayload>.broadcast();
  late final StreamSubscription<RemoteMessage> _foregroundSubscription;
  late final StreamSubscription<RemoteMessage> _openedAppSubscription;

  /// Cancels both subscriptions and closes [_controller]. Never called in
  /// production — this router is a process-lifetime singleton, same as
  /// every other Firebase-backed `@LazySingleton` service in this codebase
  /// — but keeps them reachable/disposable from a test.
  @visibleForTesting
  Future<void> dispose() async {
    await _foregroundSubscription.cancel();
    await _openedAppSubscription.cancel();
    await _controller.close();
  }

  @override
  Stream<PushNotificationPayload> get messages => _controller.stream;

  @override
  Future<PushNotificationPayload?> consumeInitialMessage() async {
    try {
      final message = await _messaging.getInitialMessage();
      return message == null ? null : _toPayload(message);
    } catch (error, stackTrace) {
      developer.log(
        'consumeInitialMessage failed to read the initial message.',
        name: 'vestipro.push_notification_router',
        level: 900,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  void _handleMessage(RemoteMessage message) {
    if (_controller.isClosed) return;
    _controller.add(_toPayload(message));
  }

  PushNotificationPayload _toPayload(RemoteMessage message) {
    final data = message.data.map(
      (key, value) => MapEntry(key, value.toString()),
    );
    return PushNotificationPayload(
      messageId: message.messageId,
      organizationId: data['organizationId'],
      deepLink: data['deepLink'],
      category: data['category'],
      data: data,
    );
  }
}
