import '../../../../core/errors/errors.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_list_filters.dart';

enum OrderListLoadStatus { initial, loading, ready, loadingMore, failure }

const int kOrderListPageSize = 20;

/// Drives `OrderListPageResult` (TASK-102). [orders] is only ever the server's own
/// paginated, [filters]-scoped page; [localPendingOrders] is a separate,
/// unpaginated slice — every Order still on this device with
/// `syncStatus != synced` (draft/pendingSync/syncing/failed/conflict) — that
/// the page renders in its own "pendente de sincronização" section instead
/// of interleaving it into [orders], since it never has a page/cursor of its
/// own.
final class OrderListState {
  const OrderListState({
    this.loadStatus = OrderListLoadStatus.initial,
    this.organizationId = '',
    this.companyId = '',
    this.userId = '',
    this.searchQuery = '',
    this.filters = OrderListFilters.empty,
    this.orders = const <Order>[],
    this.localPendingOrders = const <Order>[],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.nextCursor,
    this.failure,
  });

  final OrderListLoadStatus loadStatus;
  final String organizationId;
  final String companyId;
  final String userId;
  final String searchQuery;
  final OrderListFilters filters;
  final List<Order> orders;
  final List<Order> localPendingOrders;
  final bool hasMore;
  final bool isLoadingMore;
  final DateTime? nextCursor;
  final Failure? failure;

  bool get isInitialLoading =>
      loadStatus == OrderListLoadStatus.initial ||
      loadStatus == OrderListLoadStatus.loading;

  bool get hasActiveFilters =>
      !filters.isEmpty || searchQuery.trim().isNotEmpty;

  OrderListState copyWith({
    OrderListLoadStatus? loadStatus,
    String? organizationId,
    String? companyId,
    String? userId,
    String? searchQuery,
    OrderListFilters? filters,
    List<Order>? orders,
    List<Order>? localPendingOrders,
    bool? hasMore,
    bool? isLoadingMore,
    DateTime? nextCursor,
    bool clearNextCursor = false,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return OrderListState(
      loadStatus: loadStatus ?? this.loadStatus,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      searchQuery: searchQuery ?? this.searchQuery,
      filters: filters ?? this.filters,
      orders: orders ?? this.orders,
      localPendingOrders: localPendingOrders ?? this.localPendingOrders,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}
