import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../errors/errors.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_inbox_repository.dart';

/// Local, per-user/organization cache of the last
/// [kNotificationInboxRetentionLimit] internal notifications, so the
/// notification center (TASK-151) stays readable while offline instead of
/// depending on a live Firestore read.
///
/// This is an internal implementation detail of
/// `NotificationInboxRepositoryImpl` — nothing in `domain/`/`presentation/`
/// talks to it directly. It never fails a caller's whole operation: a
/// corrupt/unreadable cache degrades to an empty list rather than throwing,
/// since the cache is a convenience layer, not the source of truth.
@lazySingleton
final class NotificationInboxLocalCache {
  const NotificationInboxLocalCache();

  String _keyFor(String organizationId, String userId) =>
      'notification_inbox_${organizationId}_$userId';

  Future<List<AppNotification>> load({
    required String organizationId,
    required String userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyFor(organizationId, userId));
      if (raw == null) return const <AppNotification>[];

      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return const <AppNotification>[];

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_fromJsonOrNull)
          .whereType<AppNotification>()
          .toList(growable: false);
    } catch (_) {
      return const <AppNotification>[];
    }
  }

  Future<void> save({
    required String organizationId,
    required String userId,
    required List<AppNotification> notifications,
  }) async {
    try {
      final bounded = notifications.length > kNotificationInboxRetentionLimit
          ? notifications.sublist(0, kNotificationInboxRetentionLimit)
          : notifications;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keyFor(organizationId, userId),
        jsonEncode(bounded.map(_toJson).toList(growable: false)),
      );
    } catch (_) {
      // Best-effort only: losing the local cache never blocks the caller,
      // since it exists purely to serve offline reads.
    }
  }

  AppNotification? _fromJsonOrNull(Map<String, dynamic> json) {
    try {
      return AppNotification(
        id: _requiredString(json, 'id'),
        organizationId: _requiredString(json, 'organizationId'),
        userId: _requiredString(json, 'userId'),
        category: _categoryFromString(_requiredString(json, 'category')),
        title: _requiredString(json, 'title'),
        body: _requiredString(json, 'body'),
        deepLink: _requiredString(json, 'deepLink'),
        createdAt: _requiredDate(json, 'createdAt'),
        readAt: _optionalDate(json, 'readAt'),
        priority: _priorityFromString(json['priority']),
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _toJson(AppNotification notification) {
    return <String, dynamic>{
      'id': notification.id,
      'organizationId': notification.organizationId,
      'userId': notification.userId,
      'category': notification.category.name,
      'title': notification.title,
      'body': notification.body,
      'deepLink': notification.deepLink,
      'createdAt': notification.createdAt.toUtc().toIso8601String(),
      if (notification.readAt != null)
        'readAt': notification.readAt!.toUtc().toIso8601String(),
      'priority': notification.priority.name,
    };
  }

  AppNotificationCategory _categoryFromString(String value) {
    return AppNotificationCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () => AppNotificationCategory.system,
    );
  }

  /// Missing entirely (every notification cached before TASK-153) or
  /// unrecognized both degrade to `informative`, same "never let a corrupt/
  /// older cache entry throw" precedent [_categoryFromString]/[load] already
  /// follow.
  AppNotificationPriority _priorityFromString(Object? value) {
    if (value is! String) return AppNotificationPriority.informative;
    return AppNotificationPriority.values.firstWhere(
      (priority) => priority.name == value,
      orElse: () => AppNotificationPriority.informative,
    );
  }

  String _requiredString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is String) return value;
    throw ValidationException(
      'Invalid local notification string field.',
      code: 'invalid_notification_inbox_payload',
      cause: field,
    );
  }

  DateTime _requiredDate(Map<String, dynamic> json, String field) {
    return DateTime.parse(_requiredString(json, field)).toUtc();
  }

  DateTime? _optionalDate(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null) return null;
    if (value is String) return DateTime.parse(value).toUtc();
    throw ValidationException(
      'Invalid local notification date field.',
      code: 'invalid_notification_inbox_payload',
      cause: field,
    );
  }
}
