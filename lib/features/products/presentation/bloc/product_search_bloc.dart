import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../domain/entities/product_search_result.dart';
import '../../domain/services/product_search_normalizer.dart';
import '../../domain/usecases/search_products_use_case.dart';
import 'product_search_event.dart';
import 'product_search_state.dart';

@injectable
final class ProductSearchBloc
    extends Bloc<ProductSearchEvent, ProductSearchState> {
  ProductSearchBloc({required this.searchProducts})
    : debounceDuration = defaultDebounceDuration,
      super(const ProductSearchState()) {
    _registerHandlers();
  }

  ProductSearchBloc.testing({
    required this.searchProducts,
    required this.debounceDuration,
  }) : super(const ProductSearchState()) {
    _registerHandlers();
  }

  static const resultLimit = 20;
  static const defaultDebounceDuration = Duration(milliseconds: 350);

  final SearchProductsUseCase searchProducts;
  final Duration debounceDuration;

  int _requestToken = 0;

  void _registerHandlers() {
    on<ProductSearchStarted>(_onStarted, transformer: restartable());
    on<ProductSearchQueryChanged>(_onQueryChanged, transformer: restartable());
    on<ProductSearchSourceChanged>(
      _onSourceChanged,
      transformer: restartable(),
    );
    on<ProductSearchRetried>(_onRetried, transformer: restartable());
  }

  Future<void> _onStarted(
    ProductSearchStarted event,
    Emitter<ProductSearchState> emit,
  ) async {
    _requestToken += 1;
    emit(
      const ProductSearchState().copyWith(
        organizationId: event.organizationId,
        query: event.initialQuery,
        normalizedQuery: ProductSearchNormalizer.normalize(event.initialQuery),
        source: event.source,
        clearFailure: true,
      ),
    );
    if (event.initialQuery.trim().isNotEmpty) {
      await _runSearch(emit);
    }
  }

  Future<void> _onQueryChanged(
    ProductSearchQueryChanged event,
    Emitter<ProductSearchState> emit,
  ) async {
    _requestToken += 1;
    final normalizedQuery = ProductSearchNormalizer.normalize(event.query);
    emit(
      state.copyWith(
        status: normalizedQuery.isEmpty
            ? ProductSearchStatus.idle
            : ProductSearchStatus.loading,
        query: event.query,
        normalizedQuery: normalizedQuery,
        products: const <Never>[],
        clearFailure: true,
      ),
    );

    if (normalizedQuery.isEmpty) return;
    await Future<void>.delayed(debounceDuration);
    if (emit.isDone) return;
    await _runSearch(emit);
  }

  Future<void> _onSourceChanged(
    ProductSearchSourceChanged event,
    Emitter<ProductSearchState> emit,
  ) async {
    _requestToken += 1;
    emit(state.copyWith(source: event.source, clearFailure: true));
    if (state.normalizedQuery.isEmpty) return;
    await _runSearch(emit);
  }

  Future<void> _onRetried(
    ProductSearchRetried event,
    Emitter<ProductSearchState> emit,
  ) async {
    if (state.normalizedQuery.isEmpty) return;
    _requestToken += 1;
    await _runSearch(emit);
  }

  Future<void> _runSearch(Emitter<ProductSearchState> emit) async {
    final requestToken = ++_requestToken;
    emit(
      state.copyWith(
        status: ProductSearchStatus.loading,
        products: const <Never>[],
        clearFailure: true,
      ),
    );
    final result = await searchProducts(
      organizationId: state.organizationId,
      query: state.query,
      source: state.source,
      limit: resultLimit,
    );
    if (emit.isDone || requestToken != _requestToken) return;

    switch (result) {
      case AppSuccess<ProductSearchResult>(value: final searchResult):
        emit(
          state.copyWith(
            status: searchResult.products.isEmpty
                ? ProductSearchStatus.empty
                : ProductSearchStatus.success,
            products: searchResult.products,
            normalizedQuery: searchResult.normalizedQuery,
            source: searchResult.source,
            clearFailure: true,
          ),
        );
      case AppFailure<ProductSearchResult>(failure: final failure):
        emit(
          state.copyWith(
            status: ProductSearchStatus.failure,
            products: const <Never>[],
            failure: failure,
          ),
        );
    }
  }
}
