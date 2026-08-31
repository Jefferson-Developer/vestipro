import 'dart:async';

import 'package:bloc/bloc.dart';
// `injectable` also exports an `Order` annotation (unrelated to this
// feature's `Order` entity) — hidden here to avoid an ambiguous import, same
// precedent every other Orders file already follows.
import 'package:injectable/injectable.dart' hide Order;

import '../../../../core/utils/utils.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_list_filters.dart';
import '../../domain/entities/order_list_page_result.dart';
import '../../domain/usecases/list_local_pending_orders_use_case.dart';
import '../../domain/usecases/list_orders_use_case.dart';
import 'order_list_event.dart';
import 'order_list_state.dart';

/// Drives `OrderListPageResult` (TASK-102): combinable status/período/cliente/
/// vendedor filters, a debounced quick search over número de pedido/cliente,
/// cursor pagination and the merge with orders still pending sync on this
/// device — mirroring `LeadListBloc`/`AuditLogBloc`'s established shape for
/// this exact "filters + debounced search + cursor pagination" screen kind.
///
/// The quick search box has no dedicated backend field to match both
/// "número de pedido" and "cliente" at once: [_onSearchDebounced] resolves
/// the trimmed query as an [OrderListFilters.orderNumber] equality match
/// when it is digits-only (the shape of a `submitOrder`-generated order
/// number, TASK-101), otherwise as an [OrderListFilters.customerId] equality
/// match — the same two fields the filter panel's own dedicated controls
/// already expose, just reached through one box.
@injectable
final class OrderListBloc extends Bloc<OrderListEvent, OrderListState> {
  OrderListBloc({
    required this.listOrders,
    required this.listLocalPendingOrders,
  }) : super(const OrderListState()) {
    on<OrderListStarted>(_onStarted);
    on<OrderListRefreshRequested>(_onRefreshRequested);
    on<OrderListSearchChanged>(_onSearchChanged);
    on<OrderListSearchDebounced>(_onSearchDebounced);
    on<OrderListFiltersChanged>(_onFiltersChanged);
    on<OrderListFiltersCleared>(_onFiltersCleared);
    on<OrderListNextPageRequested>(_onNextPageRequested);
    on<OrderListRetried>(_onRetried);
  }

  static const searchDebounce = Duration(milliseconds: 300);

  final ListOrdersUseCase listOrders;
  final ListLocalPendingOrdersUseCase listLocalPendingOrders;

  Timer? _searchTimer;
  int _searchToken = 0;
  int _requestToken = 0;

  Future<void> _onStarted(
    OrderListStarted event,
    Emitter<OrderListState> emit,
  ) async {
    emit(
      const OrderListState().copyWith(
        loadStatus: OrderListLoadStatus.loading,
        organizationId: event.organizationId,
        companyId: event.companyId,
        userId: event.userId,
        orders: const <Order>[],
        hasMore: false,
        clearNextCursor: true,
        clearFailure: true,
      ),
    );
    await _loadLocalPendingOrders(emit);
    await _loadFirstPage(emit);
  }

  Future<void> _onRefreshRequested(
    OrderListRefreshRequested event,
    Emitter<OrderListState> emit,
  ) async {
    if (state.organizationId.isEmpty) return;
    emit(
      state.copyWith(
        loadStatus: OrderListLoadStatus.loading,
        orders: const <Order>[],
        hasMore: false,
        clearNextCursor: true,
        clearFailure: true,
      ),
    );
    await _loadLocalPendingOrders(emit);
    await _loadFirstPage(emit);
  }

  void _onSearchChanged(
    OrderListSearchChanged event,
    Emitter<OrderListState> emit,
  ) {
    final token = ++_searchToken;
    _requestToken += 1;
    _searchTimer?.cancel();
    emit(state.copyWith(searchQuery: event.searchQuery, clearFailure: true));
    _searchTimer = Timer(searchDebounce, () {
      if (!isClosed) add(OrderListSearchDebounced(token));
    });
  }

  Future<void> _onSearchDebounced(
    OrderListSearchDebounced event,
    Emitter<OrderListState> emit,
  ) async {
    if (event.token != _searchToken) return;
    final query = state.searchQuery.trim();
    final isOrderNumberLike =
        query.isNotEmpty && RegExp(r'^\d+$').hasMatch(query);
    final nextFilters = state.filters.copyWith(
      orderNumber: isOrderNumberLike ? query : '',
      customerId: !isOrderNumberLike ? query : '',
    );
    emit(
      state.copyWith(
        loadStatus: OrderListLoadStatus.loading,
        filters: nextFilters,
        orders: const <Order>[],
        hasMore: false,
        clearNextCursor: true,
        clearFailure: true,
      ),
    );
    await _loadFirstPage(emit);
  }

  Future<void> _onFiltersChanged(
    OrderListFiltersChanged event,
    Emitter<OrderListState> emit,
  ) async {
    _searchTimer?.cancel();
    _searchToken += 1;
    emit(
      state.copyWith(
        loadStatus: OrderListLoadStatus.loading,
        filters: event.filters,
        orders: const <Order>[],
        hasMore: false,
        clearNextCursor: true,
        clearFailure: true,
      ),
    );
    await _loadFirstPage(emit);
  }

  Future<void> _onFiltersCleared(
    OrderListFiltersCleared event,
    Emitter<OrderListState> emit,
  ) async {
    _searchTimer?.cancel();
    _searchToken += 1;
    emit(
      state.copyWith(
        loadStatus: OrderListLoadStatus.loading,
        searchQuery: '',
        filters: OrderListFilters.empty,
        orders: const <Order>[],
        hasMore: false,
        clearNextCursor: true,
        clearFailure: true,
      ),
    );
    await _loadFirstPage(emit);
  }

  Future<void> _onNextPageRequested(
    OrderListNextPageRequested event,
    Emitter<OrderListState> emit,
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
      limit: kOrderListPageSize,
      before: state.nextCursor,
      filters: state.filters,
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
            loadStatus: OrderListLoadStatus.ready,
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

  Future<void> _onRetried(
    OrderListRetried event,
    Emitter<OrderListState> emit,
  ) async {
    emit(
      state.copyWith(
        loadStatus: OrderListLoadStatus.loading,
        orders: const <Order>[],
        hasMore: false,
        clearNextCursor: true,
        clearFailure: true,
      ),
    );
    await _loadLocalPendingOrders(emit);
    await _loadFirstPage(emit);
  }

  Future<void> _loadLocalPendingOrders(Emitter<OrderListState> emit) async {
    final result = await listLocalPendingOrders(
      organizationId: state.organizationId,
      companyId: state.companyId,
      userId: state.userId,
    );
    if (emit.isDone) return;
    // A failure to read the local cache never blocks the (more important)
    // server page — it only means the "pendente de sincronização" section
    // stays empty, same "never let a secondary source block the primary
    // one" precedent `ListOrganizationUsersUseCase`'s team lookup already
    // sets for `LeadListBloc`.
    if (result case AppSuccess<List<Order>>(value: final orders)) {
      emit(state.copyWith(localPendingOrders: orders));
    }
  }

  Future<void> _loadFirstPage(Emitter<OrderListState> emit) async {
    final requestToken = ++_requestToken;
    final result = await listOrders(
      organizationId: state.organizationId,
      companyId: state.companyId,
      userId: state.userId,
      limit: kOrderListPageSize,
      filters: state.filters,
    );
    if (emit.isDone || requestToken != _requestToken) return;

    switch (result) {
      case AppSuccess<OrderListPageResult>(value: final page):
        emit(
          state.copyWith(
            loadStatus: OrderListLoadStatus.ready,
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
            loadStatus: OrderListLoadStatus.failure,
            orders: const <Order>[],
            hasMore: false,
            isLoadingMore: false,
            clearNextCursor: true,
            failure: failure,
          ),
        );
    }
  }

  @override
  Future<void> close() {
    _searchTimer?.cancel();
    return super.close();
  }
}
