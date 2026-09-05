import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/repositories/crm_reminder_dispatch_repository.dart';
import '../../domain/value_objects/crm_task_reminder_classification.dart';

/// Local, offline-first dedup/cooldown ledger for CRM task/follow-up
/// reminders (TASK-152) — same storage strategy as
/// `SharedPreferencesTargetAlertDispatchRepository` (TASK-149): CRM tasks
/// themselves are local-only today (`SharedPreferencesCrmTaskRepository`,
/// TASK-060), so this dedup ledger never needs to be more durable/shared
/// than the data it is deduping against.
@LazySingleton(as: CrmReminderDispatchRepository)
final class SharedPreferencesCrmReminderDispatchRepository
    implements CrmReminderDispatchRepository {
  const SharedPreferencesCrmReminderDispatchRepository();

  String _keyFor(String organizationId) =>
      'crm_reminder_dispatch_$organizationId';

  @override
  Future<AppResult<DateTime?>> getLastDispatchedAt({
    required String organizationId,
    required String taskId,
    required String recipientUserId,
    required CrmTaskReminderClassification classification,
  }) async {
    try {
      final payload = await _load(organizationId);
      final raw = payload[_entryKey(taskId, recipientUserId, classification)];
      if (raw == null) return const AppSuccess<DateTime?>(null);
      if (raw is! String) {
        throw const ValidationException(
          'Invalid local CRM reminder dispatch payload.',
          code: 'invalid_crm_reminder_dispatch_payload',
        );
      }
      return AppSuccess<DateTime?>(DateTime.parse(raw).toUtc());
    } catch (exception) {
      return AppFailure<DateTime?>(
        UnexpectedFailure(
          'Unexpected error loading CRM reminder dispatch metadata locally.',
          code: 'crm_reminder_dispatch_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<DateTime>> markDispatched({
    required String organizationId,
    required String taskId,
    required String recipientUserId,
    required CrmTaskReminderClassification classification,
    required DateTime dispatchedAt,
  }) async {
    try {
      final payload = await _load(organizationId);
      payload[_entryKey(taskId, recipientUserId, classification)] = dispatchedAt
          .toUtc()
          .toIso8601String();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyFor(organizationId), jsonEncode(payload));
      return AppSuccess<DateTime>(dispatchedAt);
    } catch (exception) {
      return AppFailure<DateTime>(
        UnexpectedFailure(
          'Unexpected error saving CRM reminder dispatch metadata locally.',
          code: 'crm_reminder_dispatch_save_unexpected',
          cause: exception,
        ),
      );
    }
  }

  Future<Map<String, dynamic>> _load(String organizationId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(organizationId));
    if (raw == null) return <String, dynamic>{};
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const ValidationException(
        'Invalid local CRM reminder dispatch payload.',
        code: 'invalid_crm_reminder_dispatch_payload',
      );
    }
    return Map<String, dynamic>.from(decoded);
  }

  String _entryKey(
    String taskId,
    String recipientUserId,
    CrmTaskReminderClassification classification,
  ) => '$taskId::$recipientUserId::${classification.name}';
}
