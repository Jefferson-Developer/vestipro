import '../value_objects/return_request_status.dart';

/// One recorded decision on a `ReturnRequest` (TASK-199, EPIC-30) — author,
/// timestamp and motivo, always appended (never overwritten) to
/// `ReturnRequest.decisions` by `resolveReturnRequest`, so the request's own
/// audit trail is complete even if a future task allows re-deciding it under
/// a different rule than today's "once decided, terminal".
final class ReturnRequestDecision {
  const ReturnRequestDecision({
    required this.decision,
    required this.actorId,
    this.actorName,
    this.reason,
    required this.decidedAt,
  });

  final ReturnRequestDecisionValue decision;
  final String actorId;
  final String? actorName;
  final String? reason;
  final DateTime decidedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReturnRequestDecision &&
          other.decision == decision &&
          other.actorId == actorId &&
          other.actorName == actorName &&
          other.reason == reason &&
          other.decidedAt == decidedAt);

  @override
  int get hashCode =>
      Object.hash(decision, actorId, actorName, reason, decidedAt);
}
