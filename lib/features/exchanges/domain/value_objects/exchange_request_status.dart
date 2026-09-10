/// Workflow status of an `ExchangeRequest` (TASK-200, EPIC-30) — same
/// two-outcome shape `ReturnRequestStatus` (TASK-199) already sets:
/// [requested] covers both "solicitada" and "em análise" (a single decision,
/// approve or reject, is what `resolveExchangeRequest` applies); [approved]
/// doubles as "concluída" too, since stock reintegration/débito and the
/// price-difference calculation are applied atomically the moment the
/// decision is recorded, never as a later, separate step. Valid transitions
/// are enforced by `resolveExchangeRequest` (Cloud Function) — never
/// inferred ad hoc from UI code — and are strictly one-way:
/// `requested -> approved | rejected`, both terminal.
enum ExchangeRequestStatus {
  requested,
  approved,
  rejected;

  static ExchangeRequestStatus fromCode(String code) => switch (code) {
    'approved' => ExchangeRequestStatus.approved,
    'rejected' => ExchangeRequestStatus.rejected,
    _ => ExchangeRequestStatus.requested,
  };

  String get code => switch (this) {
    ExchangeRequestStatus.requested => 'requested',
    ExchangeRequestStatus.approved => 'approved',
    ExchangeRequestStatus.rejected => 'rejected',
  };

  String get label => switch (this) {
    ExchangeRequestStatus.requested => 'Solicitada',
    ExchangeRequestStatus.approved => 'Aprovada',
    ExchangeRequestStatus.rejected => 'Recusada',
  };
}

/// The decision an approver may ever apply to an `ExchangeRequest` still
/// [ExchangeRequestStatus.requested] — never [ExchangeRequestStatus.requested]
/// itself, which is only ever the request's own initial status.
enum ExchangeRequestDecisionValue {
  approved,
  rejected;

  String get code => switch (this) {
    ExchangeRequestDecisionValue.approved => 'approved',
    ExchangeRequestDecisionValue.rejected => 'rejected',
  };
}
