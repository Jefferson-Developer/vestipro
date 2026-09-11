import '../../../../core/errors/errors.dart';

/// How a `CustomerCreditProfile` reacts once a pedido would push the
/// customer past its limit or the customer already carries an overdue
/// balance (TASK-212) — mirrors, value for value, the server's own
/// `CreditBlockPolicy` (`functions/src/credit/credit-shared.ts`). Set only
/// by whoever holds `finance.manage` (OWNER/ADMIN/FINANCE), never by a
/// seller.
enum CreditBlockPolicy {
  /// Nunca altera o resultado da submissão — nenhum alerta é sequer
  /// mostrado além do "liberado".
  none,

  /// Mostra um alerta ("próximo do limite"/"cliente com pendência") mas
  /// nunca bloqueia nem exige aprovação.
  alert,

  /// O pedido ainda é enviado, mas entra no fluxo de aprovação multinível
  /// (`OrderApprovalQueue`) em vez de ir direto para `submitted`.
  requireApproval,

  /// O pedido é rejeitado na submissão — só uma exceção (`CreditOverride`)
  /// concedida pelo financeiro permite prosseguir.
  block;

  static CreditBlockPolicy fromCode(String code) => switch (code) {
    'none' => CreditBlockPolicy.none,
    'alert' => CreditBlockPolicy.alert,
    'require_approval' => CreditBlockPolicy.requireApproval,
    'block' => CreditBlockPolicy.block,
    _ => throw ValidationException(
      'Invalid credit block policy: $code',
      code: 'invalid_credit_block_policy',
    ),
  };

  String get code => switch (this) {
    CreditBlockPolicy.none => 'none',
    CreditBlockPolicy.alert => 'alert',
    CreditBlockPolicy.requireApproval => 'require_approval',
    CreditBlockPolicy.block => 'block',
  };

  String get label => switch (this) {
    CreditBlockPolicy.none => 'Sem restrição',
    CreditBlockPolicy.alert => 'Somente alertar',
    CreditBlockPolicy.requireApproval => 'Exigir aprovação',
    CreditBlockPolicy.block => 'Bloquear pedido',
  };
}
