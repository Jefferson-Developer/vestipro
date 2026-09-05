import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/repositories/order_commercial_alert_dispatch_repository.dart';
import '../../domain/value_objects/order_commercial_alert_classification.dart';

/// [OrderCommercialAlertDispatchRepository] backed by
/// [SharedPreferences] — same local-only, per-device dedup store
/// `SharedPreferencesTargetAlertDispatchRepository` (TASK-149) and
/// `SharedPreferencesCrmReminderDispatchRepository` (TASK-152) already use
/// for their own alert kinds. Local-only is an accepted limitation here too:
/// reinstalling the app (or acting from a second device) may re-surface an
/// already-seen pedido alert once, which is far preferable to ever silently
/// dropping a real "pedido rejeitado"/"falha crítica de sincronização"
/// notification.
@LazySingleton(as: OrderCommercialAlertDispatchRepository)
final class SharedPreferencesOrderCommercialAlertDispatchRepository
    implements OrderCommercialAlertDispatchRepository {
  const SharedPreferencesOrderCommercialAlertDispatchRepository();

  String _keyFor(String organizationId) =>
      'order_commercial_alert_dispatch_$organizationId';

  @override
  Future<AppResult<DateTime?>> getLastDispatchedAt({
    required String organizationId,
    required String orderId,
    required String recipientUserId,
    required OrderCommercialAlertClassification classification,
  }) async {
    try {
      final payload = await _load(organizationId);
      final raw = payload[_entryKey(orderId, recipientUserId, classification)];
      if (raw == null) return const AppSuccess<DateTime?>(null);
      if (raw is! String) {
        throw const ValidationException(
          'Invalid local order commercial alert dispatch payload.',
          code: 'invalid_order_commercial_alert_dispatch_payload',
        );
      }
      return AppSuccess<DateTime?>(DateTime.parse(raw).toUtc());
    } catch (exception) {
      return AppFailure<DateTime?>(
        UnexpectedFailure(
          'Unexpected error loading order commercial alert dispatch '
          'metadata locally.',
          code: 'order_commercial_alert_dispatch_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<DateTime>> markDispatched({
    required String organizationId,
    required String orderId,
    required String recipientUserId,
    required OrderCommercialAlertClassification classification,
    required DateTime dispatchedAt,
  }) async {
    try {
      final payload = await _load(organizationId);
      payload[_entryKey(orderId, recipientUserId, classification)] =
          dispatchedAt.toUtc().toIso8601String();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyFor(organizationId), jsonEncode(payload));
      return AppSuccess<DateTime>(dispatchedAt);
    } catch (exception) {
      return AppFailure<DateTime>(
        UnexpectedFailure(
          'Unexpected error saving order commercial alert dispatch '
          'metadata locally.',
          code: 'order_commercial_alert_dispatch_save_unexpected',
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
        'Invalid local order commercial alert dispatch payload.',
        code: 'invalid_order_commercial_alert_dispatch_payload',
      );
    }
    return Map<String, dynamic>.from(decoded);
  }

  String _entryKey(
    String orderId,
    String recipientUserId,
    OrderCommercialAlertClassification classification,
  ) => '$orderId::$recipientUserId::${classification.name}';
}
