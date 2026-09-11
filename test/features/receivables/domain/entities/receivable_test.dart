import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/receivables/receivables.dart';

Receivable _build({
  required double amount,
  required double paidAmount,
  required ReceivableStatus status,
  DateTime? dueDate,
}) {
  return Receivable(
    id: 'r1',
    organizationId: 'org-1',
    customerId: 'customer-1',
    invoiceId: 'invoice-1',
    orderId: 'order-1',
    installmentNumber: 1,
    dueDate: dueDate ?? DateTime.utc(2026, 6, 1),
    amount: amount,
    paidAmount: paidAmount,
    currency: 'BRL',
    status: status,
  );
}

void main() {
  group('Receivable.outstandingAmount', () {
    test('is the difference between amount and paidAmount', () {
      final receivable = _build(
        amount: 100,
        paidAmount: 40,
        status: ReceivableStatus.partiallyPaid,
      );
      expect(receivable.outstandingAmount, 60);
    });

    test('never goes negative on an overpayment data mistake', () {
      final receivable = _build(
        amount: 100,
        paidAmount: 150,
        status: ReceivableStatus.paid,
      );
      expect(receivable.outstandingAmount, 0);
    });
  });

  group('ReceivableStatus.isSettled', () {
    test('is true only for paid/cancelled', () {
      expect(ReceivableStatus.paid.isSettled, isTrue);
      expect(ReceivableStatus.cancelled.isSettled, isTrue);
      expect(ReceivableStatus.open.isSettled, isFalse);
      expect(ReceivableStatus.overdue.isSettled, isFalse);
      expect(ReceivableStatus.partiallyPaid.isSettled, isFalse);
    });
  });

  group('ReceivableStatus.fromCode/code round-trip', () {
    test('round-trips every server-known code', () {
      for (final status in ReceivableStatus.values) {
        expect(ReceivableStatus.fromCode(status.code), status);
      }
    });
  });
}
