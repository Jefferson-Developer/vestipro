import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/repositories/insight_alert_dispatch_repository.dart';

/// [InsightAlertDispatchRepository] backed by [SharedPreferences] — same
/// local-only, per-device dedup store
/// `SharedPreferencesTargetAlertDispatchRepository` (TASK-149) already uses.
@LazySingleton(as: InsightAlertDispatchRepository)
final class SharedPreferencesInsightAlertDispatchRepository
    implements InsightAlertDispatchRepository {
  const SharedPreferencesInsightAlertDispatchRepository();

  String _keyFor(String organizationId) =>
      'insight_alert_dispatch_$organizationId';

  @override
  Future<AppResult<DateTime?>> getLastDispatchedAt({
    required String organizationId,
    required String recipientUserId,
    required String deduplicationKey,
  }) async {
    try {
      final payload = await _load(organizationId);
      final raw = payload[_entryKey(recipientUserId, deduplicationKey)];
      if (raw == null) return const AppSuccess<DateTime?>(null);
      if (raw is! String) {
        throw const ValidationException(
          'Invalid local insight alert dispatch payload.',
          code: 'invalid_insight_alert_dispatch_payload',
        );
      }
      return AppSuccess<DateTime?>(DateTime.parse(raw).toUtc());
    } catch (exception) {
      return AppFailure<DateTime?>(
        UnexpectedFailure(
          'Unexpected error loading insight alert dispatch metadata '
          'locally.',
          code: 'insight_alert_dispatch_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<DateTime>> markDispatched({
    required String organizationId,
    required String recipientUserId,
    required String deduplicationKey,
    required DateTime dispatchedAt,
  }) async {
    try {
      final payload = await _load(organizationId);
      payload[_entryKey(recipientUserId, deduplicationKey)] = dispatchedAt
          .toUtc()
          .toIso8601String();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyFor(organizationId), jsonEncode(payload));
      return AppSuccess<DateTime>(dispatchedAt);
    } catch (exception) {
      return AppFailure<DateTime>(
        UnexpectedFailure(
          'Unexpected error saving insight alert dispatch metadata '
          'locally.',
          code: 'insight_alert_dispatch_save_unexpected',
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
        'Invalid local insight alert dispatch payload.',
        code: 'invalid_insight_alert_dispatch_payload',
      );
    }
    return Map<String, dynamic>.from(decoded);
  }

  String _entryKey(String recipientUserId, String deduplicationKey) =>
      '$recipientUserId::$deduplicationKey';
}
