/// Category of a `LogisticsIssue`/ocorrência de entrega (TASK-214, EPIC-32).
/// Mirrors `functions/src/fulfillment/fulfillment-shared.ts`'s own
/// `LogisticsIssueType` union 1:1.
enum LogisticsIssueType {
  delay,
  damage,
  volumeDivergence,
  invalidAddress,
  carrierReturn,
  other;

  String get code {
    return switch (this) {
      LogisticsIssueType.delay => 'delay',
      LogisticsIssueType.damage => 'damage',
      LogisticsIssueType.volumeDivergence => 'volume_divergence',
      LogisticsIssueType.invalidAddress => 'invalid_address',
      LogisticsIssueType.carrierReturn => 'carrier_return',
      LogisticsIssueType.other => 'other',
    };
  }

  static LogisticsIssueType fromCode(String code) {
    return switch (code) {
      'delay' => LogisticsIssueType.delay,
      'damage' => LogisticsIssueType.damage,
      'volume_divergence' => LogisticsIssueType.volumeDivergence,
      'invalid_address' => LogisticsIssueType.invalidAddress,
      'carrier_return' => LogisticsIssueType.carrierReturn,
      'other' => LogisticsIssueType.other,
      _ => throw ArgumentError.value(
        code,
        'code',
        'Unknown LogisticsIssueType code',
      ),
    };
  }

  String get label {
    return switch (this) {
      LogisticsIssueType.delay => 'Atraso',
      LogisticsIssueType.damage => 'Avaria',
      LogisticsIssueType.volumeDivergence => 'Divergência de volume',
      LogisticsIssueType.invalidAddress => 'Endereço inválido',
      LogisticsIssueType.carrierReturn => 'Devolução pela transportadora',
      LogisticsIssueType.other => 'Outro',
    };
  }
}

/// Status of a `LogisticsIssue`/ocorrência (TASK-214).
enum LogisticsIssueStatus {
  open,
  inProgress,
  resolved;

  String get code {
    return switch (this) {
      LogisticsIssueStatus.open => 'open',
      LogisticsIssueStatus.inProgress => 'in_progress',
      LogisticsIssueStatus.resolved => 'resolved',
    };
  }

  static LogisticsIssueStatus fromCode(String code) {
    return switch (code) {
      'open' => LogisticsIssueStatus.open,
      'in_progress' => LogisticsIssueStatus.inProgress,
      'resolved' => LogisticsIssueStatus.resolved,
      _ => throw ArgumentError.value(
        code,
        'code',
        'Unknown LogisticsIssueStatus code',
      ),
    };
  }

  String get label {
    return switch (this) {
      LogisticsIssueStatus.open => 'Aberta',
      LogisticsIssueStatus.inProgress => 'Em andamento',
      LogisticsIssueStatus.resolved => 'Resolvida',
    };
  }
}
