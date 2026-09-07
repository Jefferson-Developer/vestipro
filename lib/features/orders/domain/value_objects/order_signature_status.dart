/// Lifecycle of an `OrderSignature` document itself (TASK-180) — distinct
/// from [OrderSignatureSyncStatus], which tracks offline replication.
///
/// A signature is never deleted and never overwritten in place ("Assinatura
/// capturada nunca pode ser removida ou substituída depois de anexada",
/// `tasks.md`/TASK-180's own restriction): the only state change allowed
/// after [valid] is [invalidated], always with a rastro (`invalidatedAt`/
/// `invalidatedReason`) — e.g. the signed order itself was cancelled. There
/// is deliberately no dedicated "invalidate signature" Cloud Function/use
/// case in this task's scope (see the CONCLUIDA doc's own "Decisões
/// técnicas"): today nothing in this codebase transitions a signature into
/// [invalidated] yet — it exists so a future order-cancellation flow can
/// without a schema change.
enum OrderSignatureStatus { valid, invalidated }
