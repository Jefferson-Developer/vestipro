import 'package:freezed_annotation/freezed_annotation.dart';

import 'order.dart';
import 'order_status_history_entry.dart';
import '../value_objects/order_status.dart';

part 'order_approval_decision.freezed.dart';

/// Whether an approver approved or rejected an `Order` under review
/// (TASK-103).
enum OrderApprovalDecisionValue { approved, rejected }

/// The recorded outcome of an `Order`'s approval flow (TASK-103):
/// [approverId]/[decision]/[decidedAt] and, for a rejection, the mandatory
/// [reason] the seller sees back (`tasks.md`'s own "pedido rejeitado retorna
/// ao vendedor com o motivo").
///
/// Deliberately never persisted as a Firestore document of its own:
/// `decideOrderApproval` (the only Cloud Function allowed to produce one)
/// writes the exact same information straight onto the order's own
/// [Order.approvedBy]/[Order.approvedAt]/[Order.rejectionReason] fields and
/// its [Order.statusHistory] trail — one more document to keep in sync would
/// only risk drifting from that already-authoritative trail for no benefit.
/// [fromOrder] simply derives this value object from it, so the rest of the
/// app (approval queue, order detail/history) never has to read those raw
/// fields ad hoc.
@freezed
abstract class OrderApprovalDecision with _$OrderApprovalDecision {
  const factory OrderApprovalDecision({
    required String approverId,
    required OrderApprovalDecisionValue decision,
    String? reason,
    required DateTime decidedAt,
  }) = _OrderApprovalDecision;

  const OrderApprovalDecision._();

  /// The decision already recorded on [order], or `null` while it has not
  /// yet been approved/rejected (still `draft` through `underReview`, or any
  /// status past the approval flow entirely, e.g. `cancelled`).
  static OrderApprovalDecision? fromOrder(Order order) {
    final decisionValue = switch (order.status) {
      OrderStatus.approved => OrderApprovalDecisionValue.approved,
      OrderStatus.rejected => OrderApprovalDecisionValue.rejected,
      _ => null,
    };
    if (decisionValue == null) return null;

    final entry = _lastEntryFor(order.statusHistory, order.status);
    return OrderApprovalDecision(
      approverId: order.approvedBy ?? entry?.actorId ?? '',
      decision: decisionValue,
      reason: order.rejectionReason ?? entry?.reason,
      decidedAt: order.approvedAt ?? entry?.changedAt ?? order.updatedAt,
    );
  }

  static OrderStatusHistoryEntry? _lastEntryFor(
    List<OrderStatusHistoryEntry> history,
    OrderStatus status,
  ) {
    for (final entry in history.reversed) {
      if (entry.newStatus == status) return entry;
    }
    return null;
  }
}
