import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_portfolio_page_result.dart';
import '../../domain/usecases/list_customer_portfolio_use_case.dart';
import 'customer_portfolio_event.dart';
import 'customer_portfolio_state.dart';

@injectable
final class CustomerPortfolioBloc
    extends Bloc<CustomerPortfolioEvent, CustomerPortfolioState> {
  CustomerPortfolioBloc({required this.listCustomerPortfolio})
    : super(const CustomerPortfolioState()) {
    on<CustomerPortfolioStarted>(_onStarted);
    on<CustomerPortfolioSearchChanged>(_onSearchChanged);
    on<CustomerPortfolioSearchDebounced>(_onSearchDebounced);
    on<CustomerPortfolioFiltersChanged>(_onFiltersChanged);
    on<CustomerPortfolioNextPageRequested>(_onNextPageRequested);
    on<CustomerPortfolioRetried>(_onRetried);
  }

  static const pageSize = 20;
  static const searchDebounce = Duration(milliseconds: 300);

  final ListCustomerPortfolioUseCase listCustomerPortfolio;
  Timer? _searchTimer;
  int _searchToken = 0;
  int _requestToken = 0;

  Future<void> _onStarted(
    CustomerPortfolioStarted event,
    Emitter<CustomerPortfolioState> emit,
  ) async {
    emit(
      const CustomerPortfolioState().copyWith(
        status: CustomerPortfolioLoadStatus.loading,
        organizationId: event.organizationId,
        companyId: event.companyId,
        userId: event.userId,
        searchQuery: event.searchQuery,
        filters: event.filters.normalized(),
        customers: const <Never>[],
        hasMore: false,
        clearNextCursor: true,
        clearFailure: true,
      ),
    );
    await _loadFirstPage(emit);
  }

  void _onSearchChanged(
    CustomerPortfolioSearchChanged event,
    Emitter<CustomerPortfolioState> emit,
  ) {
    final token = ++_searchToken;
    _requestToken += 1;
    _searchTimer?.cancel();
    emit(state.copyWith(searchQuery: event.searchQuery, clearFailure: true));
    _searchTimer = Timer(searchDebounce, () {
      if (!isClosed) add(CustomerPortfolioSearchDebounced(token));
    });
  }

  Future<void> _onSearchDebounced(
    CustomerPortfolioSearchDebounced event,
    Emitter<CustomerPortfolioState> emit,
  ) async {
    if (event.token != _searchToken) return;
    emit(
      state.copyWith(
        status: CustomerPortfolioLoadStatus.loading,
        customers: const <Never>[],
        hasMore: false,
        clearNextCursor: true,
        clearFailure: true,
      ),
    );
    await _loadFirstPage(emit);
  }

  Future<void> _onFiltersChanged(
    CustomerPortfolioFiltersChanged event,
    Emitter<CustomerPortfolioState> emit,
  ) async {
    _searchTimer?.cancel();
    _searchToken += 1;
    emit(
      state.copyWith(
        status: CustomerPortfolioLoadStatus.loading,
        filters: event.filters.normalized(),
        customers: const <Never>[],
        hasMore: false,
        clearNextCursor: true,
        clearFailure: true,
      ),
    );
    await _loadFirstPage(emit);
  }

  Future<void> _onNextPageRequested(
    CustomerPortfolioNextPageRequested event,
    Emitter<CustomerPortfolioState> emit,
  ) async {
    if (!state.hasMore || state.isLoadingMore || state.isInitialLoading) {
      return;
    }

    final requestToken = ++_requestToken;
    emit(
      state.copyWith(
        status: CustomerPortfolioLoadStatus.loadingMore,
        clearFailure: true,
      ),
    );
    final result = await listCustomerPortfolio(
      organizationId: state.organizationId,
      companyId: state.companyId,
      userId: state.userId,
      filters: state.filters,
      searchQuery: state.searchQuery,
      cursor: state.nextCursor,
      limit: pageSize,
    );
    if (emit.isDone || requestToken != _requestToken) return;
    switch (result) {
      case AppSuccess<CustomerPortfolioPageResult>(value: final page):
        emit(
          state.copyWith(
            status: CustomerPortfolioLoadStatus.ready,
            customers: <Customer>[...state.customers, ...page.customers],
            hasMore: page.hasMore,
            nextCursor: page.nextCursor,
            isFromLocalCache: page.isFromLocalCache,
            clearFailure: true,
          ),
        );
      case AppFailure<CustomerPortfolioPageResult>(failure: final failure):
        emit(
          state.copyWith(
            status: CustomerPortfolioLoadStatus.ready,
            failure: failure,
          ),
        );
    }
  }

  Future<void> _onRetried(
    CustomerPortfolioRetried event,
    Emitter<CustomerPortfolioState> emit,
  ) async {
    emit(
      state.copyWith(
        status: CustomerPortfolioLoadStatus.loading,
        customers: const <Never>[],
        hasMore: false,
        clearNextCursor: true,
        clearFailure: true,
      ),
    );
    await _loadFirstPage(emit);
  }

  Future<void> _loadFirstPage(Emitter<CustomerPortfolioState> emit) async {
    final requestToken = ++_requestToken;
    final result = await listCustomerPortfolio(
      organizationId: state.organizationId,
      companyId: state.companyId,
      userId: state.userId,
      filters: state.filters,
      searchQuery: state.searchQuery,
      limit: pageSize,
    );
    if (emit.isDone || requestToken != _requestToken) return;
    switch (result) {
      case AppSuccess<CustomerPortfolioPageResult>(value: final page):
        emit(
          state.copyWith(
            status: CustomerPortfolioLoadStatus.ready,
            customers: page.customers,
            hasMore: page.hasMore,
            nextCursor: page.nextCursor,
            isFromLocalCache: page.isFromLocalCache,
            clearFailure: true,
          ),
        );
      case AppFailure<CustomerPortfolioPageResult>(failure: final failure):
        emit(
          state.copyWith(
            status: CustomerPortfolioLoadStatus.failure,
            customers: const <Never>[],
            hasMore: false,
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
