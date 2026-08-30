import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

/// Firestore-embedded shape of an `OrderStatusHistoryEntry` (TASK-095) —
/// nested inside [OrderDto], never its own top-level document.
final class OrderStatusHistoryEntryDto {
  const OrderStatusHistoryEntryDto({
    this.previousStatus,
    required this.newStatus,
    required this.changedAt,
    required this.actorId,
    this.reason,
  });

  factory OrderStatusHistoryEntryDto.fromJson(Map<String, dynamic> json) {
    final previousStatus = json['previousStatus'];
    final newStatus = json['newStatus'];
    final changedAt = json['changedAt'];
    final actorId = json['actorId'];
    final reason = json['reason'];

    if ((previousStatus != null && previousStatus is! String) ||
        newStatus is! String ||
        changedAt is! Timestamp ||
        actorId is! String ||
        (reason != null && reason is! String)) {
      throw const ValidationException(
        'Invalid order status history entry payload.',
        code: 'invalid_order_payload',
      );
    }

    return OrderStatusHistoryEntryDto(
      previousStatus: previousStatus as String?,
      newStatus: newStatus,
      changedAt: changedAt.toDate(),
      actorId: actorId,
      reason: reason as String?,
    );
  }

  final String? previousStatus;
  final String newStatus;
  final DateTime changedAt;
  final String actorId;
  final String? reason;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (previousStatus != null) 'previousStatus': previousStatus,
      'newStatus': newStatus,
      'changedAt': Timestamp.fromDate(changedAt),
      'actorId': actorId,
      if (reason != null) 'reason': reason,
    };
  }
}
