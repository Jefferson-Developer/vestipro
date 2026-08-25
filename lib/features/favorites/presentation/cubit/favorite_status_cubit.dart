import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/auth/domain/services/session_service.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/favorite_product.dart';
import '../../domain/usecases/add_favorite_product_use_case.dart';
import '../../domain/usecases/remove_favorite_product_use_case.dart';
import '../../domain/usecases/watch_favorite_product_ids_use_case.dart';
import 'favorite_status_state.dart';

/// The single reactive source of "is this product favorited" every favorite
/// button reuses — the catalog grid card, the product detail screen and the
/// favorites screen itself all watch/toggle through one instance of this
/// cubit per (`organizationId`, `companyId`) scope (TASK-079), so favoriting
/// a product from one surface is reflected everywhere else instantly,
/// without any of them re-fetching.
///
/// [start] resolves the signed-in user from [SessionService] (the same
/// precedent `UserRoleEditBloc`/`AcceptInviteBloc` already set for a
/// BLoC/cubit that needs the current identity, not just what an event
/// carries) and subscribes to [WatchFavoriteProductIdsUseCase] — every local
/// favorite/unfavorite write re-emits on that stream almost immediately
/// (Drift's own reactivity), which is what gives [toggle] its optimistic,
/// offline-proof feel without this cubit tracking any state of its own
/// beyond what the stream already says.
@injectable
final class FavoriteStatusCubit extends Cubit<FavoriteStatusState> {
  FavoriteStatusCubit({
    required this.watchFavoriteProductIds,
    required this.addFavoriteProduct,
    required this.removeFavoriteProduct,
    required this.analyticsService,
    required this.sessionService,
  }) : super(const FavoriteStatusState());

  final WatchFavoriteProductIdsUseCase watchFavoriteProductIds;
  final AddFavoriteProductUseCase addFavoriteProduct;
  final RemoveFavoriteProductUseCase removeFavoriteProduct;
  final AnalyticsService analyticsService;
  final SessionService sessionService;

  StreamSubscription<Set<String>>? _subscription;
  String _organizationId = '';
  String? _companyId;

  /// Starts (or re-scopes) watching favorites for [organizationId]/
  /// [companyId]. A no-op when already watching the exact same scope, so a
  /// page rebuild calling this again (e.g. `createBloc()..start(...)` inside
  /// a `BlocProvider.create`) never resubscribes needlessly. Silently does
  /// nothing when there is no signed-in user — every screen that reaches
  /// this cubit sits behind `SessionAuthGuard` already.
  void start({required String organizationId, String? companyId}) {
    final userId = sessionService.currentUser?.uid;
    if (userId == null || organizationId.trim().isEmpty) return;
    if (_subscription != null &&
        _organizationId == organizationId &&
        _companyId == companyId) {
      return;
    }

    _organizationId = organizationId;
    _companyId = companyId;
    unawaited(_subscription?.cancel());
    _subscription =
        watchFavoriteProductIds(
          organizationId: organizationId,
          userId: userId,
        ).listen((favoriteProductIds) {
          if (isClosed) return;
          emit(state.copyWith(favoriteProductIds: favoriteProductIds));
        });
  }

  /// Favorites [productId] if it is not favorited yet, unfavorites it
  /// otherwise — the single handler every favorite button's `onTap` calls,
  /// deciding direction from the cubit's own current state so callers never
  /// have to pass an explicit "favorite or unfavorite" flag. [source]
  /// (`catalog_grid`, `product_detail`, `favorites`) is only carried into
  /// the `product_favorited`/`product_unfavorited` analytics event.
  Future<void> toggle({
    required String productId,
    String? companyId,
    required String source,
  }) async {
    final userId = sessionService.currentUser?.uid;
    if (userId == null || _organizationId.isEmpty) return;

    if (state.isFavorite(productId)) {
      final result = await removeFavoriteProduct(
        organizationId: _organizationId,
        userId: userId,
        productId: productId,
      );
      if (result is AppSuccess<void>) {
        await analyticsService.logEvent(
          AnalyticsEvents.productUnfavorited,
          parameters: <String, Object?>{
            'organization_id': _organizationId,
            'product_id': productId,
            'source': source,
          },
        );
      }
      return;
    }

    final result = await addFavoriteProduct(
      organizationId: _organizationId,
      userId: userId,
      productId: productId,
      companyId: companyId ?? _companyId,
    );
    if (result is AppSuccess<FavoriteProduct>) {
      await analyticsService.logEvent(
        AnalyticsEvents.productFavorited,
        parameters: <String, Object?>{
          'organization_id': _organizationId,
          'product_id': productId,
          'source': source,
        },
      );
    }
  }

  @override
  Future<void> close() {
    unawaited(_subscription?.cancel());
    return super.close();
  }
}
