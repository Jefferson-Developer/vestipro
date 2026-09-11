import '../../../../core/errors/errors.dart';

/// Status of one título a receber (parcela) — mirrors, value for value, the
/// server's own `ReceivableStatus` (`functions/src/receivables/receivables-shared.ts`).
/// Never computed client-side: always the exact status the backend already
/// persisted, so a seller/gestor/financeiro never sees a status the backend
/// itself would disagree with (TASK-213's own "situação financeira
/// atualizada e rastreável").
enum ReceivableStatus {
  open,
  overdue,
  partiallyPaid,
  paid,
  cancelled;

  static ReceivableStatus fromCode(String code) => switch (code) {
    'open' => ReceivableStatus.open,
    'overdue' => ReceivableStatus.overdue,
    'partially_paid' => ReceivableStatus.partiallyPaid,
    'paid' => ReceivableStatus.paid,
    'cancelled' => ReceivableStatus.cancelled,
    _ => throw ValidationException(
      'Invalid receivable status: $code',
      code: 'invalid_receivable_status',
    ),
  };

  String get code => switch (this) {
    ReceivableStatus.open => 'open',
    ReceivableStatus.overdue => 'overdue',
    ReceivableStatus.partiallyPaid => 'partially_paid',
    ReceivableStatus.paid => 'paid',
    ReceivableStatus.cancelled => 'cancelled',
  };

  String get label => switch (this) {
    ReceivableStatus.open => 'Em aberto',
    ReceivableStatus.overdue => 'Vencida',
    ReceivableStatus.partiallyPaid => 'Parcialmente paga',
    ReceivableStatus.paid => 'Paga',
    ReceivableStatus.cancelled => 'Estornada/cancelada',
  };

  bool get isSettled =>
      this == ReceivableStatus.paid || this == ReceivableStatus.cancelled;
}
