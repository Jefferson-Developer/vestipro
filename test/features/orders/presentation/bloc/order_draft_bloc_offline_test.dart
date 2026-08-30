import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/orders/orders.dart';

/// TASK-096's own "criação e edição de rascunho sem conectividade simulada"
/// test: mocks `connectivity_plus`'s platform channel to report
/// [ConnectivityResult.none] and drives `OrderDraftBloc` through creating and
/// then editing (autosave) a draft — proving neither path ever depends on
/// connectivity, since nothing in this flow ever calls
/// `Connectivity()`/Firestore/Storage in the first place (`OrderDraftRepository`
/// is Drift-only).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dev.fluttercommunity.plus/connectivity');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'check') return <String>['none'];
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test(
    'creates and edits an order draft while the device reports no connectivity',
    () async {
      final connectivityResults = await Connectivity().checkConnectivity();
      expect(connectivityResults, <ConnectivityResult>[
        ConnectivityResult.none,
      ]);

      final now = DateTime.utc(2026, 6, 1);
      final order = _order(now);
      final saveOrderDraft = _FakeSaveOrderDraftUseCase(<AppResult<void>>[
        const AppSuccess<void>(null),
      ]);
      final bloc = OrderDraftBloc(
        getOrderDraft: _FakeGetOrderDraftUseCase(
          const AppSuccess<Order?>(null),
        ),
        startOrderDraftForCustomer: _FakeStartOrderDraftForCustomerUseCase(
          AppSuccess<Order>(order),
        ),
        saveOrderDraft: saveOrderDraft,
        analyticsService: FakeAnalyticsService(),
      );

      bloc.add(
        const OrderDraftStarted(
          organizationId: 'org-1',
          companyId: 'company-1',
          sellerId: 'seller-1',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.loadStatus, OrderDraftLoadStatus.awaitingCustomer);

      bloc.add(OrderDraftCustomerSelected(_customer()));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.loadStatus, OrderDraftLoadStatus.ready);
      expect(bloc.state.order?.id, 'order-1');
      expect(bloc.state.failure, isNull);

      bloc.add(const OrderDraftNotesChanged('Entregar de manhã'));
      await Future<void>.delayed(OrderDraftBloc.autoSaveDebounce * 2);
      expect(bloc.state.saveStatus, OrderDraftSaveStatus.saved);
      expect(bloc.state.order?.notes, 'Entregar de manhã');
      expect(saveOrderDraft.savedOrders, isNotEmpty);

      await bloc.close();
    },
  );
}

Order _order(DateTime now) {
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
    status: OrderStatus.draft,
    statusHistory: <OrderStatusHistoryEntry>[
      OrderStatusHistoryEntry(
        newStatus: OrderStatus.draft,
        changedAt: now,
        actorId: 'seller-1',
      ),
    ],
    createdAt: now,
    createdBy: 'seller-1',
    updatedAt: now,
    updatedBy: 'seller-1',
    version: 1,
    syncStatus: OrderSyncStatus.pending,
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
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: CustomerSyncStatus.pending,
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
  _FakeSaveOrderDraftUseCase(this._results);

  final List<AppResult<void>> _results;
  int _callIndex = 0;
  final List<Order> savedOrders = <Order>[];

  @override
  Future<AppResult<void>> call({required Order order}) async {
    savedOrders.add(order);
    final result = _results[_callIndex.clamp(0, _results.length - 1)];
    _callIndex += 1;
    return result;
  }
}
