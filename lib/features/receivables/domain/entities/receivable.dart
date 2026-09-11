import '../value_objects/aging_bucket.dart';
import '../value_objects/receivable_status.dart';

/// One título a receber (parcela de uma fatura) — TASK-213, EPIC-32. Only
/// ever read directly by a caller whose Membership holds `finance.view`
/// (`firestore.rules`'s `receivables` match block denies the read outright
/// for anyone else); every other role only ever sees [BillingStatusCheck]'s
/// masked status.
final class Receivable {
  const Receivable({
    required this.id,
    required this.organizationId,
    required this.customerId,
    required this.invoiceId,
    required this.orderId,
    required this.installmentNumber,
    required this.dueDate,
    required this.amount,
    required this.paidAmount,
    required this.currency,
    required this.status,
  });

  final String id;
  final String organizationId;
  final String customerId;
  final String invoiceId;
  final String? orderId;
  final int installmentNumber;
  final DateTime dueDate;
  final double amount;
  final double paidAmount;
  final String currency;
  final ReceivableStatus status;

  /// Never negative, even on a data-entry mistake that let [paidAmount]
  /// exceed [amount] — mirrors the server's own `computeOutstandingAmount`.
  double get outstandingAmount => (amount - paidAmount).clamp(0, amount);

  AgingBucket agingBucketAt(DateTime now) =>
      agingBucketFor(dueDate: dueDate, isSettled: status.isSettled, now: now);

  @override
  bool operator ==(Object other) =>
      other is Receivable &&
      other.id == id &&
      other.organizationId == organizationId &&
      other.customerId == customerId &&
      other.invoiceId == invoiceId &&
      other.orderId == orderId &&
      other.installmentNumber == installmentNumber &&
      other.dueDate == dueDate &&
      other.amount == amount &&
      other.paidAmount == paidAmount &&
      other.currency == currency &&
      other.status == status;

  @override
  int get hashCode => Object.hash(
    id,
    organizationId,
    customerId,
    invoiceId,
    orderId,
    installmentNumber,
    dueDate,
    amount,
    paidAmount,
    currency,
    status,
  );
}
