/// Workflow status of a `ReturnRequest` (TASK-199, EPIC-30, `tasks.md`'s own
/// "status: solicitada/em análise/aprovada/recusada/concluída").
///
/// [requested] covers both "solicitada" and "em análise" — this codebase's
/// devolução flow does not model a separate, no-side-effect "iniciar
/// análise" transition (a single decision, approve or reject, is what
/// `resolveReturnRequest` applies); [approved] doubles as "concluída" too,
/// since stock reintegration and the pedido's own status update are applied
/// atomically the moment the decision is recorded, never as a later,
/// separate step. Valid transitions are enforced by `resolveReturnRequest`
/// (Cloud Function) — never inferred ad hoc from UI code — and are strictly
/// one-way: `requested -> approved | rejected`, both terminal.
enum ReturnRequestStatus {
  requested,
  approved,
  rejected;

  static ReturnRequestStatus fromCode(String code) => switch (code) {
    'approved' => ReturnRequestStatus.approved,
    'rejected' => ReturnRequestStatus.rejected,
    _ => ReturnRequestStatus.requested,
  };

  String get code => switch (this) {
    ReturnRequestStatus.requested => 'requested',
    ReturnRequestStatus.approved => 'approved',
    ReturnRequestStatus.rejected => 'rejected',
  };

  String get label => switch (this) {
    ReturnRequestStatus.requested => 'Solicitada',
    ReturnRequestStatus.approved => 'Aprovada',
    ReturnRequestStatus.rejected => 'Recusada',
  };
}

/// The decision an approver may ever apply to a `ReturnRequest` still
/// [ReturnRequestStatus.requested] — never [ReturnRequestStatus.requested]
/// itself, which is only ever the request's own initial status.
enum ReturnRequestDecisionValue {
  approved,
  rejected;

  String get code => switch (this) {
    ReturnRequestDecisionValue.approved => 'approved',
    ReturnRequestDecisionValue.rejected => 'rejected',
  };
}
