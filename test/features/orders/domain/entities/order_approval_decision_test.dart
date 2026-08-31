import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/orders/orders.dart';

void main() {
  final now = DateTime.utc(2026, 1, 1, 12);

  Order buildOrder({
    required OrderStatus status,
    List<OrderStatusHistoryEntry> statusHistory =
        const <OrderStatusHistoryEntry>[],
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
  }) {
    return Order(
      id: 'order-1',
      organizationId: 'org-1',
      companyId: 'company-1',
      branchId: 'branch-1',
      customerId: 'customer-1',
      sellerId: 'rep-1',
      deliveryAddress: const OrderAddress(
        street: 'Rua das Flores',
        city: 'Blumenau',
        state: 'SC',
        zipCode: '89010000',
      ),
      billingAddress: const OrderAddress(
        street: 'Rua das Flores',
        city: 'Blumenau',
        state: 'SC',
        zipCode: '89010000',
      ),
      priceListId: 'price-list-1',
      paymentTermId: 'term-1',
      status: status,
      statusHistory: statusHistory,
      approvedBy: approvedBy,
      approvedAt: approvedAt,
      rejectionReason: rejectionReason,
      createdAt: now,
      createdBy: 'rep-1',
      updatedAt: now,
      updatedBy: 'rep-1',
      version: 1,
      syncStatus: OrderSyncStatus.synced,
    );
  }

  group('Order.approvalReason', () {
    test('is null when the order was never routed to underReview', () {
      final order = buildOrder(
        status: OrderStatus.submitted,
        statusHistory: <OrderStatusHistoryEntry>[
          OrderStatusHistoryEntry(
            newStatus: OrderStatus.submitted,
            changedAt: now,
            actorId: 'rep-1',
          ),
        ],
      );

      expect(order.approvalReason, isNull);
    });

    test('returns the reason of the underReview status history entry', () {
      final order = buildOrder(
        status: OrderStatus.approved,
        statusHistory: <OrderStatusHistoryEntry>[
          OrderStatusHistoryEntry(
            newStatus: OrderStatus.underReview,
            changedAt: now,
            actorId: 'rep-1',
            reason: 'Desconto manual de 12.00% excede o limite de 10.00%.',
          ),
          OrderStatusHistoryEntry(
            previousStatus: OrderStatus.underReview,
            newStatus: OrderStatus.approved,
            changedAt: now,
            actorId: 'manager-1',
          ),
        ],
      );

      expect(
        order.approvalReason,
        'Desconto manual de 12.00% excede o limite de 10.00%.',
      );
    });
  });

  group('OrderApprovalDecision.fromOrder', () {
    test('is null while the order is still underReview', () {
      final order = buildOrder(status: OrderStatus.underReview);

      expect(OrderApprovalDecision.fromOrder(order), isNull);
    });

    test('derives an approved decision from approvedBy/approvedAt', () {
      final order = buildOrder(
        status: OrderStatus.approved,
        approvedBy: 'manager-1',
        approvedAt: now,
        statusHistory: <OrderStatusHistoryEntry>[
          OrderStatusHistoryEntry(
            previousStatus: OrderStatus.underReview,
            newStatus: OrderStatus.approved,
            changedAt: now,
            actorId: 'manager-1',
          ),
        ],
      );

      final decision = OrderApprovalDecision.fromOrder(order);

      expect(decision, isNotNull);
      expect(decision!.approverId, 'manager-1');
      expect(decision.decision, OrderApprovalDecisionValue.approved);
      expect(decision.decidedAt, now);
      expect(decision.reason, isNull);
    });

    test('derives a rejected decision from rejectionReason and the matching '
        'status history entry actor/timestamp', () {
      final decidedAt = now.add(const Duration(hours: 1));
      final order = buildOrder(
        status: OrderStatus.rejected,
        rejectionReason: 'Fora da política de desconto.',
        statusHistory: <OrderStatusHistoryEntry>[
          OrderStatusHistoryEntry(
            previousStatus: OrderStatus.underReview,
            newStatus: OrderStatus.rejected,
            changedAt: decidedAt,
            actorId: 'manager-1',
            reason: 'Fora da política de desconto.',
          ),
        ],
      );

      final decision = OrderApprovalDecision.fromOrder(order);

      expect(decision, isNotNull);
      expect(decision!.approverId, 'manager-1');
      expect(decision.decision, OrderApprovalDecisionValue.rejected);
      expect(decision.decidedAt, decidedAt);
      expect(decision.reason, 'Fora da política de desconto.');
    });
  });
}
