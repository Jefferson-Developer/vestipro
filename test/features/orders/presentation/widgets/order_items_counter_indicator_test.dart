import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/orders/orders.dart';

void main() {
  group('OrderItemsCounterIndicator', () {
    testWidgets('renders nothing for the empty-order state', (tester) async {
      final cubit = OrderItemsCounterCubit(
        _FakeGetOrderDraftUseCase(AppSuccess<Order?>(_order(items: const []))),
      );
      await cubit.load(
        organizationId: 'org-1',
        companyId: 'company-1',
        draftId: 'order-1',
      );

      await tester.pumpWidget(_wrap(cubit: cubit));

      expect(find.byIcon(Icons.shopping_bag_outlined), findsNothing);
      expect(find.textContaining('no pedido atual'), findsNothing);
    });

    testWidgets(
      'shows the item count and forwards the tap once the draft has items',
      (tester) async {
        final cubit = OrderItemsCounterCubit(
          _FakeGetOrderDraftUseCase(
            AppSuccess<Order?>(
              _order(
                items: const <OrderItem>[
                  OrderItem(
                    id: 'item-1',
                    variantId: 'variant-1',
                    productId: 'product-1',
                    quantity: 2,
                    unitPrice: 10,
                    subtotal: 20,
                  ),
                  OrderItem(
                    id: 'item-2',
                    variantId: 'variant-2',
                    productId: 'product-1',
                    quantity: 1,
                    unitPrice: 15,
                    subtotal: 15,
                  ),
                ],
              ),
            ),
          ),
        );
        await cubit.load(
          organizationId: 'org-1',
          companyId: 'company-1',
          draftId: 'order-1',
        );

        var tapped = false;
        await tester.pumpWidget(
          _wrap(cubit: cubit, onTap: () => tapped = true),
        );

        expect(find.text('2 produtos no pedido atual'), findsOneWidget);

        await tester.tap(find.byType(InkWell));
        expect(tapped, isTrue);
      },
    );
  });
}

Widget _wrap({required OrderItemsCounterCubit cubit, VoidCallback? onTap}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: BlocProvider<OrderItemsCounterCubit>.value(
      value: cubit,
      child: Scaffold(body: OrderItemsCounterIndicator(onTap: onTap)),
    ),
  );
}

Order _order({required List<OrderItem> items}) {
  final now = DateTime.utc(2026, 6, 1);
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
    items: items,
    status: OrderStatus.draft,
    createdAt: now,
    createdBy: 'seller-1',
    updatedAt: now,
    updatedBy: 'seller-1',
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
