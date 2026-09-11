import '../../../../core/errors/errors.dart';

/// Masked (no monetary figure) situação financeira of a customer (or one of
/// their pedidos) — the exact "vendedor/gestor enxerga o status acionável
/// sem acessar dado financeiro sensível" split TASK-212's `CreditStatus`
/// already established, applied here to faturas/títulos instead of limite de
/// crédito. Mirrors the server's own `BillingStatus`
/// (`functions/src/receivables/receivables-shared.ts`).
enum BillingStatus {
  upToDate,
  hasOpen,
  hasOverdue;

  static BillingStatus fromCode(String code) => switch (code) {
    'up_to_date' => BillingStatus.upToDate,
    'has_open' => BillingStatus.hasOpen,
    'has_overdue' => BillingStatus.hasOverdue,
    _ => throw ValidationException(
      'Invalid billing status: $code',
      code: 'invalid_billing_status',
    ),
  };
}
