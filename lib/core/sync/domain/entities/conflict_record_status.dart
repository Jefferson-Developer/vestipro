/// Lifecycle of a persisted [ConflictRecord] (TASK-110, EPIC-14).
///
/// A record is created already in [conflict] — [ConflictResolutionService]
/// never persists one in any other status — and only ever moves to
/// [resolved] once a human has made an explicit choice for it (TASK-111's
/// "Manter minha versão" / "Usar versão do servidor" / "Mesclar campo a
/// campo" actions), never automatically.
enum ConflictRecordStatus { conflict, resolved }

extension ConflictRecordStatusCode on ConflictRecordStatus {
  /// Stable identifier persisted in the local `conflict_records` table —
  /// never the enum index, same convention as `OutboxStatus`.
  String get code {
    return switch (this) {
      ConflictRecordStatus.conflict => 'conflict',
      ConflictRecordStatus.resolved => 'resolved',
    };
  }

  static ConflictRecordStatus? fromCode(String code) {
    for (final status in ConflictRecordStatus.values) {
      if (status.code == code) return status;
    }
    return null;
  }
}
