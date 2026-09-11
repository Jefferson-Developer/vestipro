import '../value_objects/billing_status.dart';

/// Read-only, masked preview of a customer's (or one pedido's) situação
/// financeira — the exact response `checkBillingStatus` returns, safe to
/// render as-is regardless of the caller's role (TASK-213, mirrors TASK-212's
/// `CreditCheckResult`). Never carries a monetary figure by itself; a
/// financially-authorized caller (`finance.view`) uses the live
/// `WatchReceivablesUseCase` for full detail instead of this masked check.
final class BillingStatusCheck {
  const BillingStatusCheck({required this.status, required this.message});

  final BillingStatus status;
  final String message;

  bool get isUpToDate => status == BillingStatus.upToDate;

  @override
  bool operator ==(Object other) =>
      other is BillingStatusCheck &&
      other.status == status &&
      other.message == message;

  @override
  int get hashCode => Object.hash(status, message);
}
