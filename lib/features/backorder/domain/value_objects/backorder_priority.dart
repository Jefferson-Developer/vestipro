/// Priority a `BackorderRequest` (TASK-215, EPIC-32) is queued with — mirrors
/// 1:1 `functions/src/backorder/backorder-shared.ts`'s own `BackorderPriority`
/// union. Deliberately a small closed set (not a raw numeric score) so the
/// UI always renders one of exactly four unambiguous labels/colors.
enum BackorderPriority {
  low,
  normal,
  high,
  urgent;

  /// The exact string persisted in Firestore.
  String get code {
    return switch (this) {
      BackorderPriority.low => 'low',
      BackorderPriority.normal => 'normal',
      BackorderPriority.high => 'high',
      BackorderPriority.urgent => 'urgent',
    };
  }

  static BackorderPriority fromCode(String code) {
    return switch (code) {
      'low' => BackorderPriority.low,
      'normal' => BackorderPriority.normal,
      'high' => BackorderPriority.high,
      'urgent' => BackorderPriority.urgent,
      _ => throw ArgumentError.value(
        code,
        'code',
        'Unknown BackorderPriority code',
      ),
    };
  }

  /// Ordering weight used to sort the atendimento queue — mirrors
  /// `backorder-shared.ts`'s own `priorityWeight`, and the exact value
  /// persisted server-side alongside `status`/`createdAt`
  /// (`Firestore.orderBy('priorityWeight', descending: true)`).
  int get weight {
    return switch (this) {
      BackorderPriority.urgent => 3,
      BackorderPriority.high => 2,
      BackorderPriority.normal => 1,
      BackorderPriority.low => 0,
    };
  }

  String get label {
    return switch (this) {
      BackorderPriority.low => 'Baixa',
      BackorderPriority.normal => 'Normal',
      BackorderPriority.high => 'Alta',
      BackorderPriority.urgent => 'Urgente',
    };
  }
}
