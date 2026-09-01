import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/target_alert_assessment.dart';
import '../../domain/repositories/target_alert_dispatch_repository.dart';

@LazySingleton(as: TargetAlertDispatchRepository)
final class SharedPreferencesTargetAlertDispatchRepository
    implements TargetAlertDispatchRepository {
  const SharedPreferencesTargetAlertDispatchRepository();

  String _keyFor(String organizationId) =>
      'target_alert_dispatch_$organizationId';

  @override
  Future<AppResult<DateTime?>> getLastDispatchedAt({
    required String organizationId,
    required String targetId,
    required TargetAlertClassification classification,
  }) async {
    try {
      final payload = await _load(organizationId);
      final raw = payload[_entryKey(targetId, classification)];
      if (raw == null) return const AppSuccess<DateTime?>(null);
      if (raw is! String) {
        throw const ValidationException(
          'Invalid local target alert dispatch payload.',
          code: 'invalid_target_alert_dispatch_payload',
        );
      }
      return AppSuccess<DateTime?>(DateTime.parse(raw).toUtc());
    } catch (exception) {
      return AppFailure<DateTime?>(
        UnexpectedFailure(
          'Unexpected error loading target alert dispatch metadata locally.',
          code: 'target_alert_dispatch_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<DateTime>> markDispatched({
    required String organizationId,
    required String targetId,
    required TargetAlertClassification classification,
    required DateTime dispatchedAt,
  }) async {
    try {
      final payload = await _load(organizationId);
      payload[_entryKey(targetId, classification)] = dispatchedAt
          .toUtc()
          .toIso8601String();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyFor(organizationId), jsonEncode(payload));
      return AppSuccess<DateTime>(dispatchedAt);
    } catch (exception) {
      return AppFailure<DateTime>(
        UnexpectedFailure(
          'Unexpected error saving target alert dispatch metadata locally.',
          code: 'target_alert_dispatch_save_unexpected',
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
        'Invalid local target alert dispatch payload.',
        code: 'invalid_target_alert_dispatch_payload',
      );
    }
    return Map<String, dynamic>.from(decoded);
  }

  String _entryKey(String targetId, TargetAlertClassification classification) =>
      '$targetId::${classification.name}';
}
