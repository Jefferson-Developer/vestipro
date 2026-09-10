import '../value_objects/exchange_request_status.dart';

/// One recorded decision on an `ExchangeRequest` (TASK-200, EPIC-30) —
/// author, timestamp and motivo, always appended (never overwritten) to
/// `ExchangeRequest.decisions` by `resolveExchangeRequest`, mirroring
/// `ReturnRequestDecision`'s own audit-trail contract (TASK-199).
final class ExchangeRequestDecision {
  const ExchangeRequestDecision({
    required this.decision,
    required this.actorId,
    this.actorName,
    this.reason,
    required this.decidedAt,
  });

  final ExchangeRequestDecisionValue decision;
  final String actorId;
  final String? actorName;
  final String? reason;
  final DateTime decidedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExchangeRequestDecision &&
          other.decision == decision &&
          other.actorId == actorId &&
          other.actorName == actorName &&
          other.reason == reason &&
          other.decidedAt == decidedAt);

  @override
  int get hashCode =>
      Object.hash(decision, actorId, actorName, reason, decidedAt);
}
