import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../errors/errors.dart';
import '../../../utils/utils.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_inbox_repository.dart';

@LazySingleton(as: NotificationInboxRepository)
final class SharedPreferencesNotificationInboxRepository
    implements NotificationInboxRepository {
  const SharedPreferencesNotificationInboxRepository();

  String _keyFor(String organizationId, String userId) =>
      'notification_inbox_${organizationId}_$userId';

  @override
  Future<AppResult<AppNotification>> create({
    required AppNotification notification,
  }) async {
    try {
      final current = await _load(
        organizationId: notification.organizationId,
        userId: notification.userId,
      );
      final next = <AppNotification>[notification, ...current];
      await _save(
        organizationId: notification.organizationId,
        userId: notification.userId,
        notifications: next,
      );
      return AppSuccess<AppNotification>(notification);
    } catch (exception) {
      return AppFailure<AppNotification>(
        UnexpectedFailure(
          'Unexpected error saving internal notification locally.',
          code: 'notification_inbox_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<AppNotification>>> listForUser({
    required String organizationId,
    required String userId,
  }) async {
    try {
      final notifications = await _load(
        organizationId: organizationId,
        userId: userId,
      );
      return AppSuccess<List<AppNotification>>(notifications);
    } catch (exception) {
      return AppFailure<List<AppNotification>>(
        UnexpectedFailure(
          'Unexpected error loading internal notifications locally.',
          code: 'notification_inbox_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  Future<List<AppNotification>> _load({
    required String organizationId,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(organizationId, userId));
    if (raw == null) return const <AppNotification>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      throw const ValidationException(
        'Invalid local notification inbox list.',
        code: 'invalid_notification_inbox_payload',
      );
    }

    return decoded
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ValidationException(
              'Invalid local notification inbox item.',
              code: 'invalid_notification_inbox_payload',
            );
          }
          return _fromJson(item);
        })
        .toList(growable: false);
  }

  Future<void> _save({
    required String organizationId,
    required String userId,
    required List<AppNotification> notifications,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFor(organizationId, userId),
      jsonEncode(notifications.map(_toJson).toList(growable: false)),
    );
  }

  AppNotification _fromJson(Map<String, dynamic> json) {
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
    );
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
    };
  }

  AppNotificationCategory _categoryFromString(String value) {
    return AppNotificationCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () => throw const ValidationException(
        'Invalid local notification category.',
        code: 'invalid_notification_inbox_payload',
      ),
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
