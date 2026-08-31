import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/orders/orders.dart';
import 'package:vestipro/features/pricing/pricing.dart';
import 'package:vestipro/features/products/products.dart';

/// TASK-100's own unit tests for `OrderSubmissionValidator`: every rule is
/// asserted in isolation first (each fixture otherwise fully valid, only the
/// one condition under test broken), then combined to prove multiple
/// pendencies are reported together, never only the first one found.
void main() {
  const validator = OrderSubmissionValidator();
  final now = DateTime.utc(2026, 6, 1);

  group('OrderSubmissionValidator', () {
    test('reports no issue for a fully valid draft', () {
      final issues = validator.validate(
        order: _order(),
        context: _validContext(),
        pricingSummary: _pricingSummary(),
        now: now,
      );

      expect(issues, isEmpty);
    });

    test('blocks an order with no items', () {
      final issues = validator.validate(
        order: _order(items: const <OrderItem>[]),
        context: _validContext(),
        now: now,
      );

      expect(
        issues,
        contains(
          predicate<OrderSubmissionIssue>(
            (issue) =>
                issue.type == OrderSubmissionIssueType.itemsEmpty &&
                issue.isBlocking,
          ),
        ),
      );
    });

    test('blocks when the customer could not be confirmed', () {
      final context = _validContext();
      final issues = validator.validate(
        order: _order(),
        context: OrderSubmissionContext(
          customer: null,
          priceList: context.priceList,
          paymentTerm: context.paymentTerm,
          availabilityByVariantId: context.availabilityByVariantId,
        ),
        now: now,
      );

      expect(issues.single.type, OrderSubmissionIssueType.customerNotConfirmed);
      expect(issues.single.isBlocking, isTrue);
    });

    for (final entry in <CustomerStatus, OrderSubmissionIssueType>{
      CustomerStatus.inactive: OrderSubmissionIssueType.customerInactive,
      CustomerStatus.blocked: OrderSubmissionIssueType.customerBlocked,
      CustomerStatus.prospect: OrderSubmissionIssueType.customerInactive,
    }.entries) {
      test('blocks a ${entry.key.name} customer', () {
        final context = _validContext();
        final issues = validator.validate(
          order: _order(),
          context: OrderSubmissionContext(
            customer: _customer(status: entry.key),
            priceList: context.priceList,
            paymentTerm: context.paymentTerm,
            availabilityByVariantId: context.availabilityByVariantId,
          ),
          now: now,
        );

        expect(issues.single.type, entry.value);
        expect(issues.single.isBlocking, isTrue);
        // Never a technical detail — every message is action-oriented.
        expect(issues.single.message, isNot(contains('CustomerStatus')));
      });
    }

    test('allows an active customer', () {
      final issues = validator.validate(
        order: _order(),
        context: _validContext(),
        now: now,
      );
      expect(issues, isEmpty);
    });

    test('blocks when the price list could not be confirmed', () {
      final context = _validContext();
      final issues = validator.validate(
        order: _order(),
        context: OrderSubmissionContext(
          customer: context.customer,
          priceList: null,
          paymentTerm: context.paymentTerm,
          availabilityByVariantId: context.availabilityByVariantId,
        ),
        now: now,
      );

      expect(
        issues.single.type,
        OrderSubmissionIssueType.priceListNotConfirmed,
      );
    });

    test('blocks an expired price list even if still flagged active', () {
      final context = _validContext();
      final expired = _priceList(
        validFrom: DateTime.utc(2020, 1, 1),
        validTo: DateTime.utc(2025, 1, 1),
      );
      final issues = validator.validate(
        order: _order(),
        context: OrderSubmissionContext(
          customer: context.customer,
          priceList: expired,
          paymentTerm: context.paymentTerm,
          availabilityByVariantId: context.availabilityByVariantId,
        ),
        now: now,
      );

      expect(issues.single.type, OrderSubmissionIssueType.priceListExpired);
      expect(issues.single.isBlocking, isTrue);
    });

    test('blocks when the payment term could not be confirmed', () {
      final context = _validContext();
      final issues = validator.validate(
        order: _order(),
        context: OrderSubmissionContext(
          customer: context.customer,
          priceList: context.priceList,
          paymentTerm: null,
          availabilityByVariantId: context.availabilityByVariantId,
        ),
        now: now,
      );

      expect(
        issues.single.type,
        OrderSubmissionIssueType.paymentTermNotConfirmed,
      );
    });

    test('blocks an inactive payment term', () {
      final context = _validContext();
      final issues = validator.validate(
        order: _order(),
        context: OrderSubmissionContext(
          customer: context.customer,
          priceList: context.priceList,
          paymentTerm: _paymentTerm(status: PaymentTermStatus.inactive),
          availabilityByVariantId: context.availabilityByVariantId,
        ),
        now: now,
      );

      expect(issues.single.type, OrderSubmissionIssueType.paymentTermInactive);
    });

    test(
      'blocks a payment term not compatible with the order\'s price list',
      () {
        final context = _validContext();
        final issues = validator.validate(
          order: _order(),
          context: OrderSubmissionContext(
            customer: context.customer,
            priceList: context.priceList,
            paymentTerm: _paymentTerm(
              priceListIds: const <String>['some-other-price-list'],
            ),
            availabilityByVariantId: context.availabilityByVariantId,
          ),
          now: now,
        );

        expect(
          issues.single.type,
          OrderSubmissionIssueType.paymentTermIncompatibleWithPriceList,
        );
      },
    );

    test('blocks an item whose variant became unavailable', () {
      final context = _validContext();
      final issues = validator.validate(
        order: _order(),
        context: OrderSubmissionContext(
          customer: context.customer,
          priceList: context.priceList,
          paymentTerm: context.paymentTerm,
          availabilityByVariantId: <String, VariantAvailability>{
            'variant-1': const VariantAvailability(
              variantId: 'variant-1',
              productId: 'product-1',
              status: VariantAvailabilityStatus.unavailable,
            ),
          },
        ),
        now: now,
      );

      expect(issues.single.type, OrderSubmissionIssueType.itemUnavailable);
      expect(issues.single.productId, 'product-1');
      expect(issues.single.variantId, 'variant-1');
    });

    test('blocks a quantity greater than what is available', () {
      final context = _validContext();
      final issues = validator.validate(
        order: _order(quantity: 5),
        context: OrderSubmissionContext(
          customer: context.customer,
          priceList: context.priceList,
          paymentTerm: context.paymentTerm,
          availabilityByVariantId: <String, VariantAvailability>{
            'variant-1': const VariantAvailability(
              variantId: 'variant-1',
              productId: 'product-1',
              status: VariantAvailabilityStatus.readyStock,
              availableQuantity: 2,
            ),
          },
        ),
        productNamesById: const <String, String>{'product-1': 'Vestido Aurora'},
        now: now,
      );

      expect(
        issues.single.type,
        OrderSubmissionIssueType.itemQuantityExceedsAvailability,
      );
      expect(issues.single.message, contains('Vestido Aurora'));
      expect(issues.single.message, contains('5'));
      expect(issues.single.message, contains('2'));
    });

    test('never blocks on a variant with no resolved availability yet', () {
      final issues = validator.validate(
        order: _order(quantity: 999),
        context: _validContext(),
        now: now,
      );

      expect(issues, isEmpty);
    });

    test('blocks a discount outside the seller\'s policy (RBAC)', () {
      final issues = validator.validate(
        order: _order(),
        context: _validContext(),
        pricingSummary: _pricingSummary(blocked: true),
        now: now,
      );

      expect(issues.single.type, OrderSubmissionIssueType.discountBlocked);
      expect(issues.single.isBlocking, isTrue);
    });

    test('never blocks by itself a discount that only requires approval — it '
        'is a warning that routes to the approval flow instead', () {
      final issues = validator.validate(
        order: _order(),
        context: _validContext(),
        pricingSummary: _pricingSummary(approvalRequired: true),
        now: now,
      );

      expect(
        issues.single.type,
        OrderSubmissionIssueType.discountRequiresApproval,
      );
      expect(issues.single.isBlocking, isFalse);
    });

    test('ignores pricing entirely when no summary was resolved yet', () {
      final issues = validator.validate(
        order: _order(),
        context: _validContext(),
        now: now,
      );

      expect(issues, isEmpty);
    });

    test('reports every pendency at once, not only the first one found', () {
      final issues = validator.validate(
        order: _order(quantity: 5),
        context: OrderSubmissionContext(
          customer: _customer(status: CustomerStatus.inactive),
          priceList: null,
          paymentTerm: _paymentTerm(status: PaymentTermStatus.inactive),
          availabilityByVariantId: <String, VariantAvailability>{
            'variant-1': const VariantAvailability(
              variantId: 'variant-1',
              productId: 'product-1',
              status: VariantAvailabilityStatus.readyStock,
              availableQuantity: 1,
            ),
          },
        ),
        pricingSummary: _pricingSummary(blocked: true),
        now: now,
      );

      final types = issues.map((issue) => issue.type).toSet();
      expect(types, contains(OrderSubmissionIssueType.customerInactive));
      expect(types, contains(OrderSubmissionIssueType.priceListNotConfirmed));
      expect(types, contains(OrderSubmissionIssueType.paymentTermInactive));
      expect(
        types,
        contains(OrderSubmissionIssueType.itemQuantityExceedsAvailability),
      );
      expect(types, contains(OrderSubmissionIssueType.discountBlocked));
      expect(issues.every((issue) => issue.isBlocking), isTrue);
    });
  });
}

OrderSubmissionContext _validContext() {
  return OrderSubmissionContext(
    customer: _customer(),
    priceList: _priceList(),
    paymentTerm: _paymentTerm(),
    availabilityByVariantId: const <String, VariantAvailability>{},
  );
}

Customer _customer({CustomerStatus status = CustomerStatus.active}) {
  final registeredAt = DateTime.utc(2026, 1, 1);
  return Customer(
    id: 'customer-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    type: CustomerType.individual,
    document: CnpjCpf.parse('529.982.247-25'),
    fullName: 'Ciclano da Silva',
    status: status,
    registeredAt: registeredAt,
    createdAt: registeredAt,
    createdBy: 'user-1',
    updatedAt: registeredAt,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: CustomerSyncStatus.pending,
  );
}

PriceList _priceList({DateTime? validFrom, DateTime? validTo}) {
  final createdAt = DateTime.utc(2026, 1, 1);
  return PriceList(
    id: 'price-list-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    name: 'Tabela padrão',
    currency: 'BRL',
    validFrom: validFrom ?? DateTime.utc(2020, 1, 1),
    validTo: validTo,
    status: PriceListStatus.active,
    scope: PriceListScopeType.company,
    createdAt: createdAt,
    createdBy: 'user-1',
    updatedAt: createdAt,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: PriceListSyncStatus.synced,
  );
}

PaymentTerm _paymentTerm({
  PaymentTermStatus status = PaymentTermStatus.active,
  List<String> priceListIds = const <String>[],
}) {
  final createdAt = DateTime.utc(2026, 1, 1);
  return PaymentTerm(
    id: 'term-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    name: 'À vista',
    installments: const <PaymentInstallment>[
      PaymentInstallment(percentage: 100, dueInDays: 0),
    ],
    averageTermDays: 0,
    status: status,
    priceListIds: priceListIds,
    createdAt: createdAt,
    createdBy: 'user-1',
    updatedAt: createdAt,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: PaymentTermSyncStatus.synced,
  );
}

OrderPricingSummary _pricingSummary({
  bool blocked = false,
  bool approvalRequired = false,
}) {
  return OrderPricingSummary(
    currency: 'BRL',
    subtotal: 200,
    campaignDiscountTotal: 0,
    manualDiscountTotal: 0,
    paymentTermAdjustmentTotal: 0,
    shippingAmount: 0,
    total: 200,
    blocked: blocked,
    approvalRequired: approvalRequired,
  );
}

Order _order({int quantity = 2, List<OrderItem>? items}) {
  final now = DateTime.utc(2026, 6, 1);
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
    items:
        items ??
        <OrderItem>[
          OrderItem(
            id: 'item-1',
            variantId: 'variant-1',
            productId: 'product-1',
            quantity: quantity,
            unitPrice: 100,
            subtotal: quantity * 100,
          ),
        ],
    status: OrderStatus.draft,
    statusHistory: <OrderStatusHistoryEntry>[
      OrderStatusHistoryEntry(
        newStatus: OrderStatus.draft,
        changedAt: now,
        actorId: 'rep-1',
      ),
    ],
    createdAt: now,
    createdBy: 'rep-1',
    updatedAt: now,
    updatedBy: 'rep-1',
    version: 1,
    syncStatus: OrderSyncStatus.pending,
  );
}
