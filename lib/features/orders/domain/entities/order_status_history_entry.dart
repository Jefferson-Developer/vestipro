import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/order_status.dart';

part 'order_status_history_entry.freezed.dart';

/// One row of an `Order`'s status audit trail (EPIC-13, TASK-095).
///
/// [previousStatus] is null only for the very first entry recorded when the
/// order is created (there is no status to transition from yet). Every
/// subsequent entry must have both [previousStatus] and [newStatus] set, and
/// the pair must be a transition `OrderStatusTransitionValidator` accepts.
@freezed
abstract class OrderStatusHistoryEntry with _$OrderStatusHistoryEntry {
  const factory OrderStatusHistoryEntry({
    OrderStatus? previousStatus,
    required OrderStatus newStatus,
    required DateTime changedAt,
    required String actorId,
    String? reason,
  }) = _OrderStatusHistoryEntry;
}
