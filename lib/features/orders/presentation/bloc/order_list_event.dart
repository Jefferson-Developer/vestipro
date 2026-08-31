import '../../domain/entities/order_list_filters.dart';

sealed class OrderListEvent {
  const OrderListEvent();
}

final class OrderListStarted extends OrderListEvent {
  const OrderListStarted({
    required this.organizationId,
    required this.companyId,
    required this.userId,
  });

  final String organizationId;
  final String companyId;
  final String userId;
}

final class OrderListRefreshRequested extends OrderListEvent {
  const OrderListRefreshRequested();
}

final class OrderListSearchChanged extends OrderListEvent {
  const OrderListSearchChanged(this.searchQuery);

  final String searchQuery;
}

final class OrderListSearchDebounced extends OrderListEvent {
  const OrderListSearchDebounced(this.token);

  final int token;
}

final class OrderListFiltersChanged extends OrderListEvent {
  const OrderListFiltersChanged(this.filters);

  final OrderListFilters filters;
}

final class OrderListFiltersCleared extends OrderListEvent {
  const OrderListFiltersCleared();
}

final class OrderListNextPageRequested extends OrderListEvent {
  const OrderListNextPageRequested();
}

final class OrderListRetried extends OrderListEvent {
  const OrderListRetried();
}
