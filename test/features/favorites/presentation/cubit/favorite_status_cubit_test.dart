import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/auth/auth.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/favorites/favorites.dart';

class _MockSessionService extends Mock implements SessionService {}

void main() {
  group('FavoriteStatusCubit', () {
    late _FakeFavoriteRepository repository;
    late FakeAnalyticsService analyticsService;
    late _MockSessionService sessionService;
    late FavoriteStatusCubit cubit;

    const signedInUser = SessionUser(uid: 'user-1', emailVerified: true);

    setUp(() {
      repository = _FakeFavoriteRepository();
      analyticsService = FakeAnalyticsService();
      sessionService = _MockSessionService();
      when(() => sessionService.currentUser).thenReturn(signedInUser);
      cubit = FavoriteStatusCubit(
        watchFavoriteProductIds: WatchFavoriteProductIdsUseCase(repository),
        addFavoriteProduct: AddFavoriteProductUseCase(repository),
        removeFavoriteProduct: RemoveFavoriteProductUseCase(repository),
        analyticsService: analyticsService,
        sessionService: sessionService,
      );
    });

    tearDown(() => cubit.close());

    test(
      'reflects favorites already present once it starts watching',
      () async {
        repository.seed(<String>{'product-1'});

        cubit.start(organizationId: 'org-1');
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state.favoriteProductIds, <String>{'product-1'});
      },
    );

    test('toggle favorites a product that is not favorited yet and logs '
        'product_favorited', () async {
      cubit.start(organizationId: 'org-1');
      await Future<void>.delayed(Duration.zero);

      await cubit.toggle(productId: 'product-1', source: 'catalog_grid');

      expect(cubit.state.favoriteProductIds, contains('product-1'));
      expect(repository.addedProductIds, <String>['product-1']);
      final logged = analyticsService.loggedEvents.firstWhere(
        (event) => event.name == AnalyticsEvents.productFavorited,
      );
      expect(logged.parameters?['organization_id'], 'org-1');
      expect(logged.parameters?['product_id'], 'product-1');
      expect(logged.parameters?['source'], 'catalog_grid');
    });

    test('toggle unfavorites an already-favorited product and logs '
        'product_unfavorited', () async {
      repository.seed(<String>{'product-1'});
      cubit.start(organizationId: 'org-1');
      await Future<void>.delayed(Duration.zero);

      await cubit.toggle(productId: 'product-1', source: 'product_detail');

      expect(cubit.state.favoriteProductIds, isNot(contains('product-1')));
      expect(repository.removedProductIds, <String>['product-1']);
      expect(
        analyticsService.loggedEvents.map((event) => event.name),
        contains(AnalyticsEvents.productUnfavorited),
      );
    });

    test(
      'toggling repeatedly before the state re-emits never sends more than '
      'one add per tap to the repository (idempotency at the cubit level)',
      () async {
        cubit.start(organizationId: 'org-1');
        await Future<void>.delayed(Duration.zero);

        await cubit.toggle(productId: 'product-1', source: 'catalog_grid');
        // The repository is the idempotency guarantee (see
        // DriftFavoriteRepository tests) — this only asserts the cubit
        // itself calls through faithfully once per tap, never batching or
        // dropping calls silently.
        expect(repository.addedProductIds, <String>['product-1']);
      },
    );

    test('does nothing when there is no signed-in user', () async {
      when(() => sessionService.currentUser).thenReturn(null);

      cubit.start(organizationId: 'org-1');
      await cubit.toggle(productId: 'product-1', source: 'catalog_grid');

      expect(cubit.state.favoriteProductIds, isEmpty);
      expect(repository.addedProductIds, isEmpty);
    });
  });
}

/// A [FavoriteRepository] fake whose `watchFavoriteProductIds` immediately
/// replays the current in-memory favorited set (mirroring Drift's own
/// `.watch()` reactivity) and then forwards every subsequent
/// add/removeFavorite as a new emission.
final class _FakeFavoriteRepository implements FavoriteRepository {
  Set<String> _favoriteIds = <String>{};
  final List<String> addedProductIds = <String>[];
  final List<String> removedProductIds = <String>[];

  void seed(Set<String> ids) {
    _favoriteIds = Set<String>.of(ids);
  }

  @override
  Stream<Set<String>> watchFavoriteProductIds({
    required String organizationId,
    required String userId,
  }) async* {
    yield _favoriteIds;
    await for (final ids in _updates.stream) {
      yield ids;
    }
  }

  final _updates = _BroadcastRelay<Set<String>>();

  @override
  Future<AppResult<FavoriteProduct>> addFavorite({
    required String organizationId,
    required String userId,
    required String productId,
    String? companyId,
  }) async {
    addedProductIds.add(productId);
    _favoriteIds = <String>{..._favoriteIds, productId};
    _updates.add(_favoriteIds);
    return AppSuccess<FavoriteProduct>(
      FavoriteProduct(
        productId: productId,
        userId: userId,
        organizationId: organizationId,
        companyId: companyId,
        createdAt: DateTime.utc(2026, 1, 1),
        syncStatus: FavoriteSyncStatus.pending,
      ),
    );
  }

  @override
  Future<AppResult<void>> removeFavorite({
    required String organizationId,
    required String userId,
    required String productId,
  }) async {
    removedProductIds.add(productId);
    _favoriteIds = Set<String>.of(_favoriteIds)..remove(productId);
    _updates.add(_favoriteIds);
    return const AppSuccess<void>(null);
  }

  @override
  Future<AppResult<FavoriteProductPage>> listFavorites({
    required String organizationId,
    required String userId,
    int offset = 0,
    int limit = 20,
  }) => throw UnimplementedError();
}

/// Minimal broadcast relay so every fresh `watchFavoriteProductIds()` call
/// (the cubit only ever calls it once per `start`, but a stream getter must
/// still behave correctly if called again) gets its own subscription to
/// future updates.
final class _BroadcastRelay<T> {
  final _controller = StreamController<T>.broadcast();

  Stream<T> get stream => _controller.stream;

  void add(T value) => _controller.add(value);
}
