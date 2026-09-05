import '../../../../core/utils/utils.dart';
import '../value_objects/order_commercial_alert_classification.dart';

/// Tracks which (order, classification, recipient) commercial alert
/// combinations (TASK-153) were already dispatched, so
/// `ProcessOrderCommercialAlertUseCase` never floods the same recipient with
/// the same pedido problem on every list reload — mirrors
/// `TargetAlertDispatchRepository` (TASK-149), keyed by [orderId] instead of
/// `targetId` and additionally by [recipientUserId], since two different
/// viewers of the same order (e.g. the seller and their manager) must each
/// get their own notification once, not share a single dedup slot.
///
/// Unlike `TargetAlertDispatchRepository`, there is no cooldown here: an
/// order only transitions into `rejected`/sync-`failed` once per real-world
/// occurrence (it is not re-evaluated every minute like a meta's pace), so
/// "already dispatched" is a permanent fact for that exact combination —
/// never re-notified, even after a long time, unless the order changes
/// state again in a way that produces a new [OrderCommercialAlertClassification].
abstract interface class OrderCommercialAlertDispatchRepository {
  Future<AppResult<DateTime?>> getLastDispatchedAt({
    required String organizationId,
    required String orderId,
    required String recipientUserId,
    required OrderCommercialAlertClassification classification,
  });

  Future<AppResult<DateTime>> markDispatched({
    required String organizationId,
    required String orderId,
    required String recipientUserId,
    required OrderCommercialAlertClassification classification,
    required DateTime dispatchedAt,
  });
}
