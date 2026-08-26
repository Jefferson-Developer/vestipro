import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/auth/domain/services/session_service.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/variant_availability.dart';
import '../../domain/entities/favorite_catalog_page.dart';
import '../../domain/usecases/list_favorite_products_use_case.dart';
import 'favorites_event.dart';
import 'favorites_state.dart';

/// Orchestrates the favorites screen (TASK-079) — the offset-paginated
/// listing of the signed-in user's favorited products, rendered through the
/// same `AppProductGrid`/`AppProductCardData` the catalog grid
/// (`ProductGridBloc`, TASK-077) uses.
///
/// Resolves the current user from [SessionService] rather than an event
/// field, same precedent `FavoriteStatusCubit` already sets — favorites are
/// always "mine", there is no caller that would ever pass a different
/// `userId` in.
@injectable
final class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  FavoritesBloc({
    required this.listFavoriteProducts,
    required this.analyticsService,
    required this.sessionService,
  }) : super(const FavoritesState()) {
    on<FavoritesStarted>(_onStarted, transformer: restartable());
    on<FavoritesNextPageRequested>(
      _onNextPageRequested,
      transformer: droppable(),
    );
    on<FavoritesRetried>(_onRetried, transformer: droppable());
    on<FavoritesProductOpened>(_onProductOpened);
  }

  final ListFavoriteProductsUseCase listFavoriteProducts;
  final AnalyticsService analyticsService;
  final SessionService sessionService;

  Future<void> _onStarted(
    FavoritesStarted event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(
      FavoritesState(
        status: FavoritesLoadStatus.loading,
        organizationId: event.organizationId,
        companyId: event.companyId,
      ),
    );
    await _loadPage(emit, offset: 0, replace: true);
  }

  Future<void> _onNextPageRequested(
    FavoritesNextPageRequested event,
    Emitter<FavoritesState> emit,
  ) async {
    if (state.isLoadingMore ||
        !state.hasMore ||
        state.status != FavoritesLoadStatus.success) {
      return;
    }
    emit(state.copyWith(isLoadingMore: true));
    await _loadPage(emit, offset: state.offset, replace: false);
  }

  Future<void> _onRetried(
    FavoritesRetried event,
    Emitter<FavoritesState> emit,
  ) async {
    if (state.organizationId.isEmpty) return;
    emit(state.copyWith(status: FavoritesLoadStatus.loading));
    await _loadPage(emit, offset: 0, replace: true);
  }

  Future<void> _onProductOpened(
    FavoritesProductOpened event,
    Emitter<FavoritesState> emit,
  ) async {
    await analyticsService.logEvent(
      AnalyticsEvents.productViewed,
      parameters: <String, Object?>{
        'organization_id': state.organizationId,
        'product_id': event.product.id,
        'source': 'favorites',
      },
    );
  }

  Future<void> _loadPage(
    Emitter<FavoritesState> emit, {
    required int offset,
    required bool replace,
  }) async {
    final userId = sessionService.currentUser?.uid;
    if (userId == null) {
      emit(
        state.copyWith(
          status: FavoritesLoadStatus.failure,
          isLoadingMore: false,
          failure: const AuthenticationFailure(
            'No signed-in user to load favorites for.',
            code: 'favorites_no_signed_in_user',
          ),
        ),
      );
      return;
    }

    final result = await listFavoriteProducts(
      organizationId: state.organizationId,
      userId: userId,
      offset: offset,
    );
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<FavoriteCatalogPage>(value: final page):
        final mergedProducts = replace
            ? page.products
            : _mergeProducts(state.products, page.products);
        final mergedAvailability = replace
            ? page.availabilityByProductId
            : <String, VariantAvailability>{
                ...state.availabilityByProductId,
                ...page.availabilityByProductId,
              };
        final mergedUnavailable = replace
            ? page.unavailableCount
            : state.unavailableCount + page.unavailableCount;

        final shouldLogViewed =
            !state.hasLoggedViewed && mergedProducts.isNotEmpty;
        if (shouldLogViewed) {
          await analyticsService.logEvent(
            AnalyticsEvents.favoritesViewed,
            parameters: <String, Object?>{
              'organization_id': state.organizationId,
              'favorites_count': mergedProducts.length,
            },
          );
        }
        if (emit.isDone) return;

        emit(
          state.copyWith(
            status: mergedProducts.isEmpty
                ? FavoritesLoadStatus.empty
                : FavoritesLoadStatus.success,
            products: mergedProducts,
            availabilityByProductId: mergedAvailability,
            offset: page.nextOffset,
            hasMore: page.hasMore,
            isLoadingMore: false,
            unavailableCount: mergedUnavailable,
            clearFailure: true,
            hasLoggedViewed: shouldLogViewed ? true : null,
          ),
        );
      case AppFailure<FavoriteCatalogPage>(failure: final failure):
        if (replace) {
          emit(
            state.copyWith(
              status: FavoritesLoadStatus.failure,
              isLoadingMore: false,
              failure: failure,
            ),
          );
        } else {
          // A later page failing never wipes what is already on screen —
          // same "carregar mais falhando preserva itens já exibidos"
          // contract `ProductGridBloc` already has.
          emit(state.copyWith(isLoadingMore: false));
        }
    }
  }

  List<Product> _mergeProducts(List<Product> current, List<Product> nextPage) {
    final existingIds = current.map((product) => product.id).toSet();
    final newProducts = nextPage.where(
      (product) => !existingIds.contains(product.id),
    );
    return <Product>[...current, ...newProducts];
  }
}
