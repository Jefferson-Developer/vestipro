import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/orders/orders.dart';

void main() {
  testWidgets('shows offline feedback that the order remains saved locally', (
    tester,
  ) async {
    final submitOrderUseCase = SubmitOrderUseCase(
      _FakeOrderSubmissionRepository(
        result: const AppFailure<OrderSubmissionResult>(
          ConnectivityFailure('Sem conexão agora.'),
        ),
      ),
      FakeAnalyticsService(),
    );
    final saveOrderDraftUseCase = SaveOrderDraftUseCase(
      _FakeOrderDraftRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: AppButton(
                label: 'Enviar',
                onPressed: () => submitOrderFromDraft(
                  context: context,
                  order: _order(),
                  submitOrderUseCase: submitOrderUseCase,
                  saveOrderDraftUseCase: saveOrderDraftUseCase,
                  navigateTo: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(AppButton, 'Enviar'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.text(
        'Sem conexão. O pedido continua salvo localmente neste dispositivo e pode ser enviado quando a conexão voltar.',
      ),
      findsOneWidget,
    );
  });
}

final class _FakeOrderSubmissionRepository
    implements OrderSubmissionRepository {
  _FakeOrderSubmissionRepository({required this.result});

  final AppResult<OrderSubmissionResult> result;

  @override
  Future<AppResult<OrderSubmissionResult>> submit({
    required Order order,
    required String idempotencyKey,
  }) async {
    return result;
  }
}

final class _FakeOrderDraftRepository implements OrderDraftRepository {
  @override
  Future<AppResult<Order?>> getDraftById({
    required String organizationId,
    required String companyId,
    required String id,
  }) async {
    return const AppSuccess<Order?>(null);
  }

  @override
  Future<AppResult<List<Order>>> getLocalOrdersForCompany({
    required String organizationId,
    required String companyId,
  }) async {
    return const AppSuccess<List<Order>>(<Order>[]);
  }

  @override
  Future<AppResult<void>> saveDraft({required Order order}) async {
    return const AppSuccess<void>(null);
  }
}

Order _order() {
  final now = DateTime.utc(2026, 9, 1);
  return Order(
    id: 'order-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    branchId: 'branch-1',
    customerId: 'customer-1',
    sellerId: 'seller-1',
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
    items: const <OrderItem>[
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
    createdAt: now,
    createdBy: 'seller-1',
    updatedAt: now,
    updatedBy: 'seller-1',
    version: 1,
    syncStatus: OrderSyncStatus.pending,
  );
}
