import '../../../../core/errors/errors.dart';
import '../../domain/entities/billing_status_check.dart';
import '../../domain/entities/receivable.dart';

enum CustomerBillingLoadStatus { initial, loading, ready, failure }

enum CustomerBillingActionStatus { idle, submitting, success, failure }

/// Owns both the finance-only full-detail view ([receivables], via
/// [CustomerBillingLoadStatus]) and the masked status view ([maskedCheck]) of
/// TASK-213's billing section — mirrors `CustomerCreditState` (TASK-212)
/// exactly: which one is populated depends only on which method the widget
/// called ([watchFullDetail] vs. [loadMaskedStatus]), gated by the caller's
/// own `finance.view`, never re-decided by this state itself.
final class CustomerBillingState {
  const CustomerBillingState({
    this.loadStatus = CustomerBillingLoadStatus.initial,
    this.receivables = const <Receivable>[],
    this.maskedCheck,
    this.loadFailure,
    this.actionStatus = CustomerBillingActionStatus.idle,
    this.actionFailure,
  });

  final CustomerBillingLoadStatus loadStatus;
  final List<Receivable> receivables;
  final BillingStatusCheck? maskedCheck;
  final Failure? loadFailure;
  final CustomerBillingActionStatus actionStatus;
  final Failure? actionFailure;

  bool get isLoading =>
      loadStatus == CustomerBillingLoadStatus.initial ||
      loadStatus == CustomerBillingLoadStatus.loading;
  bool get isSubmitting =>
      actionStatus == CustomerBillingActionStatus.submitting;
}
