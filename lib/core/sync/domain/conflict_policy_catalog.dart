import 'entities/conflict_policy.dart';
import 'entities/outbox_entity_type.dart';

/// Single, centralized source of truth for "which [ConflictPolicy] applies
/// to which `OutboxEntityType`" (TASK-110, EPIC-14 — seção 5.5 de
/// `tasks.md`: "definir política por entidade").
///
/// This is deliberately the *only* place that decides this mapping — no
/// repository, handler or UI is ever allowed to inline its own policy
/// decision for an entity, so the policy stays auditable and testable in one
/// spot (`ConflictPolicyCatalogTest` asserts every `OutboxEntityType` value
/// maps to the exact policy expected, so a financial entity can never
/// accidentally fall back to [ConflictPolicy.lastWriteWins]).
///
/// The `switch` below is intentionally exhaustive with no `default` case:
/// adding a new [OutboxEntityType] value without extending this switch is a
/// compile error, forcing whoever wires a new entity into the Outbox to make
/// an explicit, reviewable policy decision for it instead of silently
/// inheriting an unsafe default.
abstract final class ConflictPolicyCatalog {
  static ConflictPolicy policyFor(OutboxEntityType entityType) {
    return switch (entityType) {
      // Orders and order items carry pricing/discount/payment-condition
      // implications — never resolved automatically (`tasks.md`, seção 5.5:
      // "bloqueio e resolução manual para pedidos ou informações críticas").
      OutboxEntityType.order => ConflictPolicy.manualResolution,
      OutboxEntityType.orderItem => ConflictPolicy.manualResolution,

      // A Customer's fields (address, contacts, ...) are typically edited
      // independently by different actors (the seller in the field vs. a
      // back-office update) — safe to merge field by field, falling back to
      // manual resolution only when the very same field changed on both
      // sides (see `ConflictResolutionService`/`ConflictFieldMerge`).
      OutboxEntityType.customer => ConflictPolicy.fieldMerge,

      // A CRM activity log entry (a note/interaction record) has no
      // financial implication and is not expected to be edited
      // field-by-field from two sides at once — the most recent write is
      // safe to keep automatically, with the losing version always
      // discarded audibly (never silently).
      OutboxEntityType.crmActivity => ConflictPolicy.lastWriteWins,
    };
  }
}
