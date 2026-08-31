import 'package:bloc/bloc.dart';
// `injectable` also exports an `Order` annotation (unrelated to this
// feature's `Order` entity) — hidden here, same precedent every other Orders
// bloc already follows.
import 'package:injectable/injectable.dart' hide Order;

import '../../../../core/utils/utils.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_approval_decision_result.dart';
import '../../domain/entities/order_list_filters.dart';
import '../../domain/entities/order_list_page_result.dart';
import '../../domain/usecases/decide_order_approval_use_case.dart';
import '../../domain/usecases/list_orders_use_case.dart';
import '../../domain/value_objects/order_status.dart';
import 'order_approval_queue_event.dart';
import 'order_approval_queue_state.dart';

/// Drives the fila de aprovação screen (TASK-103) — combines
/// [ListOrdersUseCase] (fixed to [OrderStatus.underReview], never a filter
/// the approver can widen away, same "fila só mostra o que precisa de
/// decisão" contract) with [DecideOrderApprovalUseCase] for the
/// aprovar/rejeitar action itself.
///
/// Reuses [ListOrdersUseCase] instead of a bespoke query so this queue's own
/// visibility scope (a `SALES_MANAGER` only ever sees their own teams'
/// pedidos, never the whole organization's) never drifts from the pedidos
/// listing screen's (`OrderListBloc`) — one [OrderVisibilityService]
/// decision, read from two screens.
@injectable
final class OrderApprovalQueueBloc
    extends Bloc<OrderApprovalQueueEvent, OrderApprovalQueueState> {
  OrderApprovalQueueBloc({
    required this.listOrders,
    required this.decideOrderApproval,
  }) : super(const OrderApprovalQueueState()) {
    on<OrderApprovalQueueStarted>(_onStarted);
    on<OrderApprovalQueueRefreshRequested>(_onRefreshRequested);
    on<OrderApprovalQueueNextPageRequested>(_onNextPageRequested);
    on<OrderApprovalQueueDecided>(_onDecided);
  }

  final ListOrdersUseCase listOrders;
  final DecideOrderApprovalUseCase decideOrderApproval;

  int _requestToken = 0;

  Future<void> _onStarted(
    OrderApprovalQueueStarted event,
    Emitter<OrderApprovalQueueState> emit,
  ) async {
    emit(
      OrderApprovalQueueState(
        loadStatus: OrderApprovalQueueLoadStatus.loading,
        organizationId: event.organizationId,
        companyId: event.companyId,
        userId: event.userId,
      ),
    );
    await _loadFirstPage(emit);
  }

  Future<void> _onRefreshRequested(
    OrderApprovalQueueRefreshRequested event,
    Emitter<OrderApprovalQueueState> emit,
  ) async {
    if (state.organizationId.isEmpty) return;
    emit(
      state.copyWith(
        loadStatus: OrderApprovalQueueLoadStatus.loading,
        orders: const <Order>[],
        hasMore: false,
        clearNextCursor: true,
        clearFailure: true,
      ),
    );
    await _loadFirstPage(emit);
  }

  Future<void> _onNextPageRequested(
    OrderApprovalQueueNextPageRequested event,
    Emitter<OrderApprovalQueueState> emit,
  ) async {
    if (!state.hasMore || state.isLoadingMore || state.isInitialLoading) {
      return;
    }
    final requestToken = ++_requestToken;
    emit(state.copyWith(isLoadingMore: true, clearFailure: true));

    final result = await listOrders(
      organizationId: state.organizationId,
      companyId: state.companyId,
      userId: state.userId,
      limit: kOrderApprovalQueuePageSize,
      before: state.nextCursor,
      filters: _queueFilters,
    );
    if (emit.isDone || requestToken != _requestToken) return;

    switch (result) {
      case AppSuccess<OrderListPageResult>(value: final page):
        final seenIds = state.orders.map((order) => order.id).toSet();
        final merged = <Order>[
          ...state.orders,
          for (final order in page.orders)
            if (seenIds.add(order.id)) order,
        ];
        emit(
          state.copyWith(
            loadStatus: OrderApprovalQueueLoadStatus.ready,
            orders: merged,
            hasMore: page.hasMore,
            isLoadingMore: false,
            nextCursor: page.nextCursor,
            clearNextCursor: page.nextCursor == null,
            clearFailure: true,
          ),
        );
      case AppFailure<OrderListPageResult>(failure: final failure):
        emit(state.copyWith(isLoadingMore: false, failure: failure));
    }
  }

  Future<void> _onDecided(
    OrderApprovalQueueDecided event,
    Emitter<OrderApprovalQueueState> emit,
  ) async {
    emit(
      state.copyWith(
        decidingOrderId: event.orderId,
        clearDecisionFailure: true,
      ),
    );

    final result = await decideOrderApproval(
      organizationId: state.organizationId,
      companyId: state.companyId,
      orderId: event.orderId,
      userId: state.userId,
      decision: event.decision,
      reason: event.reason,
    );
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<OrderApprovalDecisionResult>():
        // A decided pedido is no longer `underReview` — it simply leaves the
        // queue instead of a full page reload, same "optimistic removal"
        // precedent `LeadListBloc` sets after disqualifying a lead.
        emit(
          state.copyWith(
            orders: state.orders
                .where((order) => order.id != event.orderId)
                .toList(growable: false),
            clearDecidingOrderId: true,
            clearDecisionFailure: true,
          ),
        );
      case AppFailure<OrderApprovalDecisionResult>(failure: final failure):
        emit(
          state.copyWith(clearDecidingOrderId: true, decisionFailure: failure),
        );
    }
  }

  Future<void> _loadFirstPage(Emitter<OrderApprovalQueueState> emit) async {
    final requestToken = ++_requestToken;
    final result = await listOrders(
      organizationId: state.organizationId,
      companyId: state.companyId,
      userId: state.userId,
      limit: kOrderApprovalQueuePageSize,
      filters: _queueFilters,
    );
    if (emit.isDone || requestToken != _requestToken) return;

    switch (result) {
      case AppSuccess<OrderListPageResult>(value: final page):
        emit(
          state.copyWith(
            loadStatus: OrderApprovalQueueLoadStatus.ready,
            orders: page.orders,
            hasMore: page.hasMore,
            isLoadingMore: false,
            nextCursor: page.nextCursor,
            clearNextCursor: page.nextCursor == null,
            clearFailure: true,
          ),
        );
      case AppFailure<OrderListPageResult>(failure: final failure):
        emit(
          state.copyWith(
            loadStatus: OrderApprovalQueueLoadStatus.failure,
            orders: const <Order>[],
            hasMore: false,
            isLoadingMore: false,
            clearNextCursor: true,
            failure: failure,
          ),
        );
    }
  }

  static const _queueFilters = OrderListFilters(
    status: OrderStatus.underReview,
  );
}
