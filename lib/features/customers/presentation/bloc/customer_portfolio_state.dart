import '../../../../core/errors/errors.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_portfolio_filters.dart';

enum CustomerPortfolioLoadStatus {
  initial,
  loading,
  ready,
  loadingMore,
  failure,
}

final class CustomerPortfolioState {
  const CustomerPortfolioState({
    this.status = CustomerPortfolioLoadStatus.initial,
    this.organizationId = '',
    this.companyId = '',
    this.userId = '',
    this.searchQuery = '',
    this.filters = CustomerPortfolioFilters.empty,
    this.customers = const <Customer>[],
    this.hasMore = false,
    this.nextCursor,
    this.isFromLocalCache = false,
    this.failure,
  });

  final CustomerPortfolioLoadStatus status;
  final String organizationId;
  final String companyId;
  final String userId;
  final String searchQuery;
  final CustomerPortfolioFilters filters;
  final List<Customer> customers;
  final bool hasMore;
  final String? nextCursor;
  final bool isFromLocalCache;
  final Failure? failure;

  bool get isInitialLoading =>
      status == CustomerPortfolioLoadStatus.initial ||
      status == CustomerPortfolioLoadStatus.loading;

  bool get isLoadingMore => status == CustomerPortfolioLoadStatus.loadingMore;

  CustomerPortfolioState copyWith({
    CustomerPortfolioLoadStatus? status,
    String? organizationId,
    String? companyId,
    String? userId,
    String? searchQuery,
    CustomerPortfolioFilters? filters,
    List<Customer>? customers,
    bool? hasMore,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? isFromLocalCache,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return CustomerPortfolioState(
      status: status ?? this.status,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      searchQuery: searchQuery ?? this.searchQuery,
      filters: filters ?? this.filters,
      customers: customers ?? this.customers,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
      isFromLocalCache: isFromLocalCache ?? this.isFromLocalCache,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}
