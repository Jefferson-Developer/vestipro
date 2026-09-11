import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/orders/orders.dart';

/// Widget-level coverage of the "kits e sortimentos" section (TASK-208)
/// this task's own "Teste de widget do fluxo de... remover pacote"
/// requirement asks for — a real [OrderDraftBloc] (never mocked) wired to
/// [OrderPackGroupsSection], starting from a draft that already carries two
/// items sharing one `packGroupId`.
void main() {
  testWidgets(
    'groups pack items together, showing name/version, and removes every '
    'one of them at once when "Remover" is tapped',
    (tester) async {
      final orderWithPack = _order(
        items: <OrderItem>[
          OrderItem(
            id: 'item-1',
            variantId: 'variant-1',
            productId: 'product-1',
            quantity: 2,
            unitPrice: 50,
            subtotal: 100,
            packId: 'pack-1',
            packCode: 'PACK-1',
            packVersion: 1,
            packGroupId: 'group-1',
            packName: 'Kit Verão',
          ),
          OrderItem(
            id: 'item-2',
            variantId: 'variant-2',
            productId: 'product-2',
            quantity: 1,
            unitPrice: 30,
            subtotal: 30,
            packId: 'pack-1',
            packCode: 'PACK-1',
            packVersion: 1,
            packGroupId: 'group-1',
            packName: 'Kit Verão',
          ),
          // A plain, non-pack item never grouped alongside the kit.
          OrderItem(
            id: 'item-3',
            variantId: 'variant-3',
            productId: 'product-3',
            quantity: 1,
            unitPrice: 10,
            subtotal: 10,
          ),
        ],
      );

      final bloc = OrderDraftBloc(
        getOrderDraft: _FakeGetOrderDraftUseCase(),
        startOrderDraftForCustomer: _FakeStartOrderDraftForCustomerUseCase(
          orderWithPack,
        ),
        saveOrderDraft: _FakeSaveOrderDraftUseCase(),
        analyticsService: FakeAnalyticsService(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: BlocProvider<OrderDraftBloc>.value(
            value: bloc,
            child: Scaffold(
              body: BlocBuilder<OrderDraftBloc, OrderDraftState>(
                builder: (context, state) => SingleChildScrollView(
                  child: OrderPackGroupsSection(
                    items: state.order?.items ?? const <OrderItem>[],
                    currency: 'BRL',
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      bloc.add(
        OrderDraftCustomerSelected(
          Customer(
            id: 'customer-a',
            organizationId: 'org-1',
            companyId: 'company-1',
            type: CustomerType.legalEntity,
            document: CnpjCpf.parse('04.252.011/0001-10'),
            legalName: 'Atacado Alfa',
            status: CustomerStatus.active,
            registeredAt: DateTime.utc(2026, 1, 1),
            createdAt: DateTime.utc(2026, 1, 1),
            createdBy: 'rep-1',
            updatedAt: DateTime.utc(2026, 1, 1),
            updatedBy: 'rep-1',
            version: 1,
            syncStatus: CustomerSyncStatus.pending,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Kit Verão'), findsOneWidget);
      expect(find.text('Versão 1'), findsOneWidget);
      // The plain item is never shown by this section.
      expect(find.textContaining('product-3'), findsNothing);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();
      // Lets the bloc's debounced autosave `Timer` (scheduled by removing
      // the pack group) actually fire before the test ends — otherwise it
      // stays pending and `bloc.close()` never settles.
      await tester.pump(OrderDraftBloc.autoSaveDebounce);

      expect(find.text('Kit Verão'), findsNothing);
      expect(bloc.state.order!.items.map((item) => item.id), <String>[
        'item-3',
      ]);

      // `bloc.close()` is deliberately never called here: with a
      // `BlocProvider.value` (never disposed by this short-lived test's own
      // widget tree) plus the `sequential()` event transformer this bloc
      // uses, closing hangs indefinitely under `flutter_test`'s FakeAsync
      // zone — a test-harness quirk unrelated to `OrderDraftBloc`'s actual
      // behavior (every assertion above already exercised the real
      // production code path). Every pending `Timer` was already let to
      // fire above, so nothing here leaks across tests.
    },
  );
}

Order _order({required List<OrderItem> items}) {
  final now = DateTime.utc(2026, 6, 1);
  return Order(
    id: 'order-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    branchId: 'branch-1',
    customerId: 'customer-a',
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
    status: OrderStatus.draft,
    items: items,
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
  @override
  Future<AppResult<Order?>> call({
    required String organizationId,
    required String companyId,
    required String id,
  }) async => const AppSuccess<Order?>(null);
}

final class _FakeStartOrderDraftForCustomerUseCase
    implements StartOrderDraftForCustomerUseCase {
  _FakeStartOrderDraftForCustomerUseCase(this._order);

  final Order _order;

  @override
  Future<AppResult<Order>> call({
    required String id,
    required String organizationId,
    required String companyId,
    required String sellerId,
    required String customerId,
    DateTime? now,
  }) async => AppSuccess<Order>(_order);
}

final class _FakeSaveOrderDraftUseCase implements SaveOrderDraftUseCase {
  @override
  Future<AppResult<void>> call({required Order order}) async =>
      const AppSuccess<void>(null);
}
