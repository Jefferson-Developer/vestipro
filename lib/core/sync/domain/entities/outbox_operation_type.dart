/// The kind of write an Outbox operation represents (TASK-108, EPIC-14).
enum OutboxOperationType { create, update, delete }

extension OutboxOperationTypeCode on OutboxOperationType {
  /// Stable identifier persisted in `OutboxTable.operationType` — never the
  /// enum index, same convention as [OutboxOperationType]'s siblings.
  String get code {
    return switch (this) {
      OutboxOperationType.create => 'create',
      OutboxOperationType.update => 'update',
      OutboxOperationType.delete => 'delete',
    };
  }

  static OutboxOperationType? fromCode(String code) {
    for (final type in OutboxOperationType.values) {
      if (type.code == code) {
        return type;
      }
    }
    return null;
  }
}
