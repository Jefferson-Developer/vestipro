import '../../../../core/utils/utils.dart';

/// Tracks when a commercial notification (TASK-153, EPIC-19) was last
/// dispatched for a given "oportunidade quente" — keyed by
/// [Insight.deduplicationKey] (type + related customer/product/seller), not
/// by `Insight.id`: the insights engine (TASK-121 a TASK-131) regenerates
/// `Insight`s on every run, so the same underlying opportunity can carry a
/// different `id` across runs while its `deduplicationKey` stays stable —
/// dedup must survive that regeneration, or the same "cliente pronto para
/// cross-sell" would notify the recipient again every single time the
/// engine re-evaluates it.
///
/// Mirrors `TargetAlertDispatchRepository` (TASK-149): a cooldown, not a
/// permanent one-time dedup, since an opportunity can legitimately still be
/// "quente" (and worth a fresh nudge) well after the first alert, unlike a
/// pedido's terminal `rejected`/sync-`failed` state.
abstract interface class InsightAlertDispatchRepository {
  Future<AppResult<DateTime?>> getLastDispatchedAt({
    required String organizationId,
    required String recipientUserId,
    required String deduplicationKey,
  });

  Future<AppResult<DateTime>> markDispatched({
    required String organizationId,
    required String recipientUserId,
    required String deduplicationKey,
    required DateTime dispatchedAt,
  });
}
