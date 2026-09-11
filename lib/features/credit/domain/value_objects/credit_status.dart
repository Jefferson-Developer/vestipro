import '../../../../core/errors/errors.dart';

/// Outcome of TASK-212's credit rule for one pedido/cliente — mirrors,
/// value for value, the server's own `CreditEvaluationStatus`
/// (`functions/src/credit/credit-shared.ts`). Never computed client-side:
/// always the exact status `validateOrderCredit`/`submitOrder` returned,
/// so the seller/gestor never sees a status the backend would not also
/// enforce.
enum CreditStatus {
  released,
  nearLimit,
  blocked,
  approvalRequired;

  static CreditStatus fromCode(String code) => switch (code) {
    'released' => CreditStatus.released,
    'near_limit' => CreditStatus.nearLimit,
    'blocked' => CreditStatus.blocked,
    'approval_required' => CreditStatus.approvalRequired,
    _ => throw ValidationException(
      'Invalid credit status: $code',
      code: 'invalid_credit_status',
    ),
  };

  String get code => switch (this) {
    CreditStatus.released => 'released',
    CreditStatus.nearLimit => 'near_limit',
    CreditStatus.blocked => 'blocked',
    CreditStatus.approvalRequired => 'approval_required',
  };
}
