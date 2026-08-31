import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/orders/orders.dart';
import 'package:vestipro/features/pricing/pricing.dart';
import 'package:vestipro/features/products/products.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockCustomerRepository extends Mock implements CustomerRepository {}

class _MockPriceListRepository extends Mock implements PriceListRepository {}

class _MockPaymentTermRepository extends Mock
    implements PaymentTermRepository {}

class _MockVariantAvailabilityRepository extends Mock
    implements VariantAvailabilityRepository {}

class _MockOrderPricingRepository extends Mock
    implements OrderPricingRepository {}

/// TASK-100's own widget tests for `OrderDraftPage`'s "Enviar pedido" CTA
/// and "Antes de enviar, resolva:" pendencies panel: the CTA stays disabled
/// while any blocking pendency exists (never acted on a stale/missing
/// validation, `OrderSubmissionValidationState.canSubmit`'s own contract),
/// enables once every one of them is resolved, and re-evaluates
/// automatically as the draft itself changes.
void main() {
  group('OrderDraftPage — TASK-100 pre-submit validation', () {
    late _MockMembershipRepository membershipRepository;
    late PermissionService permissionService;

    setUp(() {
      membershipRepository = _MockMembershipRepository();
      permissionService = PermissionService(membershipRepository);
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'rep-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(
          Membership(
            id: 'rep-1',
            organizationId: 'org-1',
            userId: 'rep-1',
            roleId: 'SALES_REP',
            roleName: 'SALES_REP',
            status: MembershipStatus.active,
            version: 1,
            createdAt: DateTime.utc(2026, 1, 1),
            createdBy: 'owner-1',
            updatedAt: DateTime.utc(2026, 1, 1),
            updatedBy: 'owner-1',
          ),
        ),
      );
    });

    testWidgets(
      'enables "Enviar pedido" and calls onSubmitOrder once every pendency '
      'is resolved',
      (tester) async {
        Order? submitted;
        await _pumpPage(
          tester,
          permissionService: permissionService,
          customer: _customer(),
          priceList: _priceList(),
          paymentTerm: _paymentTerm(),
          pricingResult: AppSuccess<OrderPricingSummary>(_pricingSummary()),
          onSubmitOrder: (order) async => submitted = order,
        );
        await _settleValidation(tester);

        expect(find.text('Antes de enviar, resolva:'), findsNothing);
        final button = _submitButton(tester);
        expect(button.onPressed, isNotNull);

        final submitButtonFinder = find.widgetWithText(
          AppButton,
          'Enviar pedido',
        );
        await tester.ensureVisible(submitButtonFinder);
        await tester.pumpAndSettle();
        await tester.tap(submitButtonFinder);
        await tester.pump();

        expect(submitted?.id, 'order-1');
      },
    );

    testWidgets(
      'keeps "Enviar pedido" disabled and shows the pendency when the '
      'price list has expired',
      (tester) async {
        await _pumpPage(
          tester,
          permissionService: permissionService,
          customer: _customer(),
          priceList: _priceList(
            validFrom: DateTime.utc(2020, 1, 1),
            validTo: DateTime.utc(2025, 1, 1),
          ),
          paymentTerm: _paymentTerm(),
          pricingResult: AppSuccess<OrderPricingSummary>(_pricingSummary()),
          onSubmitOrder: (order) async {},
        );
        await _settleValidation(tester);

        expect(find.text('Antes de enviar, resolva:'), findsOneWidget);
        expect(
          find.textContaining('tabela de preço deste pedido venceu'),
          findsOneWidget,
        );
        expect(_submitButton(tester).onPressed, isNull);
      },
    );

    testWidgets(
      'keeps "Enviar pedido" disabled (RBAC) when a discount is outside the '
      'seller\'s policy, without an approval flow resolving it on its own',
      (tester) async {
        await _pumpPage(
          tester,
          permissionService: permissionService,
          customer: _customer(),
          priceList: _priceList(),
          paymentTerm: _paymentTerm(),
          pricingResult: AppSuccess<OrderPricingSummary>(
            _pricingSummary(blocked: true),
          ),
          onSubmitOrder: (order) async {},
        );
        await _settleValidation(tester);

        expect(find.textContaining('fora do limite permitido'), findsOneWidget);
        expect(_submitButton(tester).onPressed, isNull);
      },
    );

    testWidgets(
      'never blocks submission by itself over a discount that only needs '
      'approval — it is only ever surfaced as a warning',
      (tester) async {
        await _pumpPage(
          tester,
          permissionService: permissionService,
          customer: _customer(),
          priceList: _priceList(),
          paymentTerm: _paymentTerm(),
          pricingResult: AppSuccess<OrderPricingSummary>(
            _pricingSummary(approvalRequired: true),
          ),
          onSubmitOrder: (order) async {},
        );
        await _settleValidation(tester);

        expect(find.text('Antes de enviar, resolva:'), findsNothing);
        expect(find.text('Avisos'), findsOneWidget);
        expect(_submitButton(tester).onPressed, isNotNull);
      },
    );

    testWidgets(
      're-evaluates automatically once the only item is removed from the '
      'draft',
      (tester) async {
        await _pumpPage(
          tester,
          permissionService: permissionService,
          customer: _customer(),
          priceList: _priceList(),
          paymentTerm: _paymentTerm(),
          pricingResult: AppSuccess<OrderPricingSummary>(_pricingSummary()),
          onSubmitOrder: (order) async {},
        );
        await _settleValidation(tester);
        expect(_submitButton(tester).onPressed, isNotNull);

        // The single item's `Product` was never resolved (no
        // `getProductById` wired in this suite), so it falls back to the
        // plain quantity-stepper row — its delete icon is the only one on
        // screen with a single item on the draft.
        await tester.tap(find.byIcon(Icons.delete_outline));
        await _settleValidation(tester);

        expect(
          find.text('Adicione ao menos um produto para enviar o pedido.'),
          findsOneWidget,
        );
        expect(_submitButton(tester).onPressed, isNull);
      },
    );
  });
}

/// `OrderSubmissionValidationCubit.evaluate()` re-runs on its own 500ms
/// debounce, and once more every time `OrderPricingSummarySection` resolves
/// a fresh summary (also debounced 500ms) — `pumpAndSettle` alone can time
/// out waiting on these bloc/cubit async gaps, so every scenario advances
/// past both cascaded debounces explicitly instead.
Future<void> _settleValidation(WidgetTester tester) async {
  for (var round = 0; round < 4; round++) {
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    await tester.pump();
  }
}

AppButton _submitButton(WidgetTester tester) =>
    tester.widget<AppButton>(find.widgetWithText(AppButton, 'Enviar pedido'));

Future<void> _pumpPage(
  WidgetTester tester, {
  required PermissionService permissionService,
  required Customer customer,
  required PriceList priceList,
  required PaymentTerm paymentTerm,
  required AppResult<OrderPricingSummary> pricingResult,
  required Future<void> Function(Order order) onSubmitOrder,
}) {
  final customerRepository = _MockCustomerRepository();
  when(
    () => customerRepository.getById(
      organizationId: any(named: 'organizationId'),
      id: any(named: 'id'),
    ),
  ).thenAnswer((_) async => AppSuccess<Customer>(customer));

  final priceListRepository = _MockPriceListRepository();
  when(
    () => priceListRepository.getById(
      organizationId: any(named: 'organizationId'),
      id: any(named: 'id'),
    ),
  ).thenAnswer((_) async => AppSuccess<PriceList?>(priceList));

  final paymentTermRepository = _MockPaymentTermRepository();
  when(
    () => paymentTermRepository.getById(
      organizationId: any(named: 'organizationId'),
      id: any(named: 'id'),
    ),
  ).thenAnswer((_) async => AppSuccess<PaymentTerm?>(paymentTerm));

  final availabilityRepository = _MockVariantAvailabilityRepository();
  when(
    () => availabilityRepository.listByVariantIds(
      organizationId: any(named: 'organizationId'),
      variantIds: any(named: 'variantIds'),
    ),
  ).thenAnswer((_) async => const AppSuccess<List<VariantAvailability>>([]));

  final pricingRepository = _MockOrderPricingRepository();
  when(
    () => pricingRepository.calculate(
      organizationId: any(named: 'organizationId'),
      companyId: any(named: 'companyId'),
      customerSegment: any(named: 'customerSegment'),
      priceListId: any(named: 'priceListId'),
      paymentTermId: any(named: 'paymentTermId'),
      idempotencyKey: any(named: 'idempotencyKey'),
      shippingAmount: any(named: 'shippingAmount'),
      items: any(named: 'items'),
    ),
  ).thenAnswer((_) async => pricingResult);

  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: OrderDraftPage(
        organizationId: 'org-1',
        companyId: 'company-1',
        sellerId: 'rep-1',
        permissionService: permissionService,
        createBloc: () => OrderDraftBloc(
          getOrderDraft: _FakeGetOrderDraftUseCase(
            AppSuccess<Order?>(_order()),
          ),
          startOrderDraftForCustomer: _FakeStartOrderDraftForCustomerUseCase(
            AppSuccess<Order>(_order()),
          ),
          saveOrderDraft: _FakeSaveOrderDraftUseCase(),
          analyticsService: FakeAnalyticsService(),
        ),
        createCustomerPortfolioBloc: () => throw UnimplementedError(
          'Not exercised: this suite always resumes an existing draftId.',
        ),
        createOrderItemsGridCubit: () => throw UnimplementedError(
          'Not exercised: no grid cell is edited in this suite.',
        ),
        createOrderPricingSummaryCubit: () => OrderPricingSummaryCubit(
          GetOrderPricingSummaryUseCase(
            pricingRepository,
            GetCustomerByIdUseCase(customerRepository),
          ),
        ),
        createOrderSubmissionValidationCubit: () =>
            OrderSubmissionValidationCubit(
              GetOrderSubmissionContextUseCase(
                GetCustomerByIdUseCase(customerRepository),
                priceListRepository,
                paymentTermRepository,
                GetVariantAvailabilityUseCase(availabilityRepository),
              ),
              const OrderSubmissionValidator(),
            ),
        draftId: 'order-1',
        onSubmitOrder: onSubmitOrder,
      ),
    ),
  );
}

Customer _customer() {
  final now = DateTime.utc(2026, 1, 1);
  return Customer(
    id: 'customer-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    type: CustomerType.individual,
    document: CnpjCpf.parse('529.982.247-25'),
    fullName: 'Ciclano da Silva',
    status: CustomerStatus.active,
    registeredAt: now,
    createdAt: now,
    createdBy: 'rep-1',
    updatedAt: now,
    updatedBy: 'rep-1',
    version: 1,
    syncStatus: CustomerSyncStatus.pending,
  );
}

PriceList _priceList({DateTime? validFrom, DateTime? validTo}) {
  final now = DateTime.utc(2026, 1, 1);
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
    createdAt: now,
    createdBy: 'rep-1',
    updatedAt: now,
    updatedBy: 'rep-1',
    version: 1,
    syncStatus: PriceListSyncStatus.synced,
  );
}

PaymentTerm _paymentTerm() {
  final now = DateTime.utc(2026, 1, 1);
  return PaymentTerm(
    id: 'term-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    name: 'À vista',
    installments: const <PaymentInstallment>[
      PaymentInstallment(percentage: 100, dueInDays: 0),
    ],
    averageTermDays: 0,
    status: PaymentTermStatus.active,
    createdAt: now,
    createdBy: 'rep-1',
    updatedAt: now,
    updatedBy: 'rep-1',
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

Order _order() {
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
    items: <OrderItem>[
      OrderItem(
        id: 'item-1',
        variantId: 'variant-1',
        productId: 'product-1',
        quantity: 2,
        unitPrice: 100,
        subtotal: 200,
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

final class _FakeGetOrderDraftUseCase implements GetOrderDraftUseCase {
  _FakeGetOrderDraftUseCase(this._result);

  final AppResult<Order?> _result;

  @override
  Future<AppResult<Order?>> call({
    required String organizationId,
    required String companyId,
    required String id,
  }) async {
    return _result;
  }
}

final class _FakeStartOrderDraftForCustomerUseCase
    implements StartOrderDraftForCustomerUseCase {
  _FakeStartOrderDraftForCustomerUseCase(this._result);

  final AppResult<Order> _result;

  @override
  Future<AppResult<Order>> call({
    required String id,
    required String organizationId,
    required String companyId,
    required String sellerId,
    required String customerId,
    DateTime? now,
  }) async {
    return _result;
  }
}

final class _FakeSaveOrderDraftUseCase implements SaveOrderDraftUseCase {
  @override
  Future<AppResult<void>> call({required Order order}) async {
    return const AppSuccess<void>(null);
  }
}
