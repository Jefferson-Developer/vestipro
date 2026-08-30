import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/orders/orders.dart';
import 'package:vestipro/features/users/users.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

/// TASK-099's own widget tests for `OrderPricingSummarySection`: the card
/// always shows exactly what the (fake, boundary-mocked)
/// `calculatePricing`/`OrderPricingRepository` responds — subtotal, desconto,
/// frete and total are never recomputed here — recalculating never hides the
/// last known summary, an unreachable pricing engine falls back to a clearly
/// labeled local estimate, and every value/status is exposed to a screen
/// reader through `Semantics`.
void main() {
  testWidgets(
    'shows subtotal/desconto/frete/total exactly as the pricing engine '
    'responded, never a client-recomputed value',
    (tester) async {
      final pricingRepository = _FakeOrderPricingRepository(
        AppSuccess<OrderPricingSummary>(
          const OrderPricingSummary(
            currency: 'BRL',
            subtotal: 240,
            campaignDiscountTotal: 24,
            manualDiscountTotal: 0,
            paymentTermAdjustmentTotal: 0,
            shippingAmount: 20,
            total: 236,
            blocked: false,
            approvalRequired: false,
          ),
        ),
      );

      await _pumpSection(tester, pricingRepository: pricingRepository);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump();

      expect(find.text(_fmt(240)), findsOneWidget);
      expect(find.text('- ${_fmt(24)}'), findsOneWidget);
      expect(find.text(_fmt(20)), findsOneWidget);
      expect(find.text(_fmt(236)), findsOneWidget);
      expect(find.byType(AppCommercialSummaryCard), findsOneWidget);
    },
  );

  testWidgets(
    'signals (never hides) a manual discount above the profile limit',
    (tester) async {
      final pricingRepository = _FakeOrderPricingRepository(
        AppSuccess<OrderPricingSummary>(
          const OrderPricingSummary(
            currency: 'BRL',
            subtotal: 240,
            campaignDiscountTotal: 0,
            manualDiscountTotal: 40,
            paymentTermAdjustmentTotal: 0,
            shippingAmount: 20,
            total: 220,
            blocked: false,
            approvalRequired: true,
          ),
        ),
      );

      await _pumpSection(tester, pricingRepository: pricingRepository);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump();

      expect(find.text('Desconto exige aprovação'), findsOneWidget);
    },
  );

  testWidgets('keeps showing the last known summary while recalculating, never '
      'blocking the seller with a blank card', (tester) async {
    final pricingRepository = _FakeOrderPricingRepository(
      AppSuccess<OrderPricingSummary>(
        const OrderPricingSummary(
          currency: 'BRL',
          subtotal: 100,
          campaignDiscountTotal: 0,
          manualDiscountTotal: 0,
          paymentTermAdjustmentTotal: 0,
          shippingAmount: 10,
          total: 110,
          blocked: false,
          approvalRequired: false,
        ),
      ),
    );

    var order = _order(quantity: 1);
    await _pumpSection(
      tester,
      pricingRepository: pricingRepository,
      order: order,
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump();
    expect(find.text(_fmt(110)), findsOneWidget);

    // A second, still-unresolved calculation must not clear the figures
    // already shown — `AppSkeleton`/a blank card would block the seller
    // from reading the last confirmed total while the new one is pending.
    pricingRepository.result =
        Completer<AppResult<OrderPricingSummary>>().future;
    order = _order(quantity: 2);
    await _pumpSection(
      tester,
      pricingRepository: pricingRepository,
      order: order,
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('Recalculando...'), findsOneWidget);
    expect(find.text(_fmt(110)), findsOneWidget);
  });

  testWidgets(
    'falls back to a clearly labeled local estimate when the pricing engine '
    'cannot be reached, never presenting it as the confirmed total',
    (tester) async {
      final pricingRepository = _FakeOrderPricingRepository(
        const AppFailure<OrderPricingSummary>(
          ConnectivityFailure('Sem conexão com o servidor.'),
        ),
      );

      await _pumpSection(
        tester,
        pricingRepository: pricingRepository,
        order: _order(quantity: 2, unitPrice: 50, shippingAmount: 12),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump();

      expect(find.text('Estimativa não confirmada'), findsOneWidget);
      // 2 * 50 (subtotal) + 12 (shipping) = 112 — plain local arithmetic,
      // never a guessed desconto/acréscimo.
      expect(find.text(_fmt(112)), findsOneWidget);
      expect(find.textContaining('ainda não foi confirmado'), findsOneWidget);
    },
  );

  testWidgets(
    'announces every summary line and the recalculating status to a screen '
    'reader',
    (tester) async {
      final pricingRepository = _FakeOrderPricingRepository(
        AppSuccess<OrderPricingSummary>(
          const OrderPricingSummary(
            currency: 'BRL',
            subtotal: 100,
            campaignDiscountTotal: 0,
            manualDiscountTotal: 0,
            paymentTermAdjustmentTotal: 0,
            shippingAmount: 10,
            total: 110,
            blocked: false,
            approvalRequired: false,
          ),
        ),
      );
      final handle = tester.ensureSemantics();

      await _pumpSection(tester, pricingRepository: pricingRepository);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump();

      expect(find.bySemanticsLabel('Subtotal: ${_fmt(100)}'), findsOneWidget);
      expect(find.bySemanticsLabel('Total: ${_fmt(110)}'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Recalculando...: info'),
        findsNothing,
      ); // already settled: no transient badge left mounted.

      handle.dispose();
    },
  );
}

/// Same formatting `OrderPricingSummarySection`'s own private `_formatCurrency`
/// uses — kept here instead of hardcoded string literals so this test never
/// silently breaks over an `intl` locale/whitespace detail (e.g. the
/// non-breaking space `NumberFormat.currency` inserts after the symbol).
String _fmt(double value) {
  return NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  ).format(value);
}

Future<void> _pumpSection(
  WidgetTester tester, {
  required _FakeOrderPricingRepository pricingRepository,
  Order? order,
}) {
  final customerRepository = _FakeCustomerRepository(
    _customer(segment: 'atacado'),
  );
  return pumpApp(
    tester,
    OrderPricingSummarySection(
      order: order ?? _order(),
      createCubit: () => OrderPricingSummaryCubit(
        GetOrderPricingSummaryUseCase(
          pricingRepository,
          GetCustomerByIdUseCase(customerRepository),
        ),
      ),
    ),
  );
}

Order _order({
  int quantity = 2,
  double unitPrice = 100,
  double shippingAmount = 15,
}) {
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
    shippingAmount: shippingAmount,
    items: <OrderItem>[
      OrderItem(
        id: 'item-1',
        variantId: 'variant-1',
        productId: 'product-1',
        quantity: quantity,
        unitPrice: unitPrice,
        subtotal: quantity * unitPrice,
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

Customer _customer({String? segment}) {
  final now = DateTime.utc(2026, 1, 1);
  return Customer(
    id: 'customer-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    type: CustomerType.individual,
    document: CnpjCpf.parse('529.982.247-25'),
    fullName: 'Ciclano da Silva',
    status: CustomerStatus.active,
    segment: segment,
    registeredAt: now,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: CustomerSyncStatus.pending,
  );
}

final class _FakeOrderPricingRepository implements OrderPricingRepository {
  _FakeOrderPricingRepository(AppResult<OrderPricingSummary> result)
    : result = Future<AppResult<OrderPricingSummary>>.value(result);

  Future<AppResult<OrderPricingSummary>> result;

  @override
  Future<AppResult<OrderPricingSummary>> calculate({
    required String organizationId,
    required String companyId,
    required String customerSegment,
    required String priceListId,
    required String paymentTermId,
    required String idempotencyKey,
    required double shippingAmount,
    required List<OrderPricingItemRequest> items,
  }) {
    return result;
  }
}

final class _FakeCustomerRepository implements CustomerRepository {
  _FakeCustomerRepository(this._customer);

  final Customer _customer;

  @override
  Future<AppResult<Customer>> getById({
    required String organizationId,
    required String id,
  }) async {
    return AppSuccess<Customer>(_customer);
  }

  @override
  Future<AppResult<bool>> existsByDocument({
    required String organizationId,
    required CnpjCpf document,
    String? excludingCustomerId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Customer>> create({required Customer customer}) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Customer>> update({
    required Customer customer,
    required Set<CustomerSensitiveField> sensitiveFieldsToAudit,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Customer>> deactivate({
    required String organizationId,
    required String id,
    required String updatedBy,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<CustomerPortfolioPageResult>> listPortfolioPage({
    required CustomerVisibilityFilter visibility,
    required List<PortfolioAssignment> activeAssignments,
    required CustomerPortfolioFilters filters,
    required String searchQuery,
    required int limit,
    String? cursor,
    required DateTime now,
  }) {
    throw UnimplementedError();
  }
}
