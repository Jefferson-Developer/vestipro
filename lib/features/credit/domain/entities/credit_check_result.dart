import '../value_objects/credit_status.dart';

/// Result of TASK-212's credit rule for one pedido/cliente — the exact
/// (masked, never a raw dollar figure) response `validateOrderCredit`
/// returns. [message] is already action-oriented and safe to render as-is,
/// same "nunca expõem detalhes técnicos" precedent `OrderSubmissionIssue`
/// already follows.
final class CreditCheckResult {
  const CreditCheckResult({
    required this.status,
    required this.blocked,
    required this.approvalRequired,
    required this.message,
    required this.dataStale,
    this.sensitive,
  });

  final CreditStatus status;
  final bool blocked;
  final bool approvalRequired;
  final String message;

  /// Whether the underlying `CustomerCreditProfile` has not been refreshed
  /// in a while (TASK-212's own "dado financeiro desatualizado" alert) —
  /// advisory only, never blocks by itself.
  final bool dataStale;

  /// Only populated for callers whose role has `finance.view`
  /// (OWNER/ADMIN/FINANCE) — `null` for everyone else, exactly like the
  /// server's own [ValidateOrderCreditResponse.sensitive] (TASK-212's
  /// "dados financeiros sensíveis são visíveis apenas para perfis
  /// autorizados" rule).
  final CreditCheckSensitiveDetail? sensitive;

  bool get isReleased => status == CreditStatus.released;

  @override
  bool operator ==(Object other) =>
      other is CreditCheckResult &&
      other.status == status &&
      other.blocked == blocked &&
      other.approvalRequired == approvalRequired &&
      other.message == message &&
      other.dataStale == dataStale &&
      other.sensitive == sensitive;

  @override
  int get hashCode => Object.hash(
    status,
    blocked,
    approvalRequired,
    message,
    dataStale,
    sensitive,
  );
}

/// Raw financial figures behind a [CreditCheckResult] — only ever populated
/// for a financially-authorized caller (TASK-212).
final class CreditCheckSensitiveDetail {
  const CreditCheckSensitiveDetail({
    required this.creditLimit,
    required this.openBalance,
    required this.overdueBalance,
    required this.financialScore,
    required this.dataUpdatedAt,
  });

  final double creditLimit;
  final double openBalance;
  final double overdueBalance;
  final double? financialScore;
  final DateTime dataUpdatedAt;

  double get availableCredit => creditLimit - openBalance;

  @override
  bool operator ==(Object other) =>
      other is CreditCheckSensitiveDetail &&
      other.creditLimit == creditLimit &&
      other.openBalance == openBalance &&
      other.overdueBalance == overdueBalance &&
      other.financialScore == financialScore &&
      other.dataUpdatedAt == dataUpdatedAt;

  @override
  int get hashCode => Object.hash(
    creditLimit,
    openBalance,
    overdueBalance,
    financialScore,
    dataUpdatedAt,
  );
}
