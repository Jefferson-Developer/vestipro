import '../../../../core/errors/errors.dart';
import '../../domain/entities/credit_check_result.dart';
import '../../domain/entities/customer_credit_profile.dart';

enum CustomerCreditLoadStatus { idle, loading, ready, failure }

enum CustomerCreditActionStatus { idle, submitting, success, failure }

/// State of `CustomerCreditPanel` (TASK-212) — the customer 360º screen's
/// credit section. Exactly one of [profile]/[maskedCheck] is ever populated
/// at a time, driven by which one the panel asked for: [profile] (full raw
/// detail, live Firestore watch) only for a caller with `finance.view`,
/// [maskedCheck] (status-only, one-shot) for everyone else who can still see
/// the "Indicadores comerciais sensíveis" section (`report.viewSensitive`).
final class CustomerCreditState {
  const CustomerCreditState({
    this.loadStatus = CustomerCreditLoadStatus.idle,
    this.profile,
    this.maskedCheck,
    this.loadFailure,
    this.actionStatus = CustomerCreditActionStatus.idle,
    this.actionFailure,
  });

  final CustomerCreditLoadStatus loadStatus;
  final CustomerCreditProfile? profile;
  final CreditCheckResult? maskedCheck;
  final Failure? loadFailure;
  final CustomerCreditActionStatus actionStatus;
  final Failure? actionFailure;

  bool get isLoading => loadStatus == CustomerCreditLoadStatus.loading;
  bool get isSubmitting =>
      actionStatus == CustomerCreditActionStatus.submitting;
}
