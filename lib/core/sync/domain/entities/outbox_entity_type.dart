/// Every domain entity that can currently enqueue an Outbox operation
/// (TASK-108, EPIC-14 — seção 5.4 de `tasks.md`).
///
/// Grows as each feature migrates its offline write path onto the Outbox —
/// only the entities actually wired to enqueue an operation today belong
/// here, mirroring `OfflinePackageEntityKind`'s own precedent.
enum OutboxEntityType { order, orderItem, crmActivity, customer }

extension OutboxEntityTypeCode on OutboxEntityType {
  /// Stable identifier persisted in `OutboxTable.entityType` — never the
  /// enum index, so reordering [OutboxEntityType] can never silently change
  /// what an already-persisted row means.
  String get code {
    return switch (this) {
      OutboxEntityType.order => 'order',
      OutboxEntityType.orderItem => 'order_item',
      OutboxEntityType.crmActivity => 'crm_activity',
      OutboxEntityType.customer => 'customer',
    };
  }

  static OutboxEntityType? fromCode(String code) {
    for (final type in OutboxEntityType.values) {
      if (type.code == code) {
        return type;
      }
    }
    return null;
  }
}
