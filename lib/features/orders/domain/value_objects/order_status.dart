/// Commercial workflow status of an `Order` (EPIC-13, TASK-095, `tasks.md`
/// seção 9.1).
///
/// This is the business/domain status — independent from [OrderSyncStatus],
/// the technical offline replication status every sync-aware entity in this
/// codebase already carries (`CustomerSyncStatus`, `PriceListSyncStatus`).
/// [pendingSync] here means "created/edited offline, not yet reached the
/// backend", which is itself a step inside the domain workflow (the order is
/// still a draft-like document until it is actually [submitted]) — it is not
/// the same concept as `OrderSyncStatus.pending`, which any of these
/// statuses can carry while a given mutation has not synced yet.
///
/// Valid transitions between these statuses are enforced by
/// `OrderStatusTransitionValidator`, never inferred ad hoc from UI code.
///
/// [partiallyReturned] and [returned] were added by EPIC-30/TASK-199
/// (devoluções): reachable from every post-fulfillment status
/// ([invoiced], [partiallyInvoiced], [shipped], [delivered]) once at least
/// one `ReturnRequest` for the order is approved by `resolveReturnRequest`
/// (Cloud Function, Admin SDK — bypasses this client-side validator, same
/// precedent `decideOrderApproval` already sets for [approved]/[rejected]).
/// [returned] is terminal; [partiallyReturned] may still transition to
/// [returned] once every remaining item is eventually returned too.
enum OrderStatus {
  draft,
  pendingSync,
  submitted,
  underReview,
  approved,
  rejected,
  processing,
  invoiced,
  partiallyInvoiced,
  shipped,
  delivered,
  cancelled,
  partiallyReturned,
  returned,
}
