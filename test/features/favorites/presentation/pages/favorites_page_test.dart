import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/auth/auth.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/favorites/favorites.dart';
import 'package:vestipro/features/products/products.dart';

class _MockSessionService extends Mock implements SessionService {}

void main() {
  group('FavoritesPage', () {
    late _MockSessionService sessionService;

    const signedInUser = SessionUser(uid: 'user-1', emailVerified: true);

    setUp(() {
      sessionService = _MockSessionService();
      when(() => sessionService.currentUser).thenReturn(signedInUser);
    });

    testWidgets(
      'shows an explanatory empty state guiding the seller back to the '
      'catalog when there is nothing favorited yet (TASK-079)',
      (tester) async {
        final favoriteRepository = _FakeFavoriteRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: FavoritesPage(
              organizationId: 'org-1',
              createFavoritesBloc: () => FavoritesBloc(
                listFavoriteProducts: ListFavoriteProductsUseCase(
                  favoriteRepository,
                  _FakeProductRepository(const <String, Product>{}),
                  GetVariantAvailabilityUseCase(
                    const _FakeVariantAvailabilityRepository(),
                  ),
                ),
                analyticsService: FakeAnalyticsService(),
                sessionService: sessionService,
              ),
              createFavoriteStatusCubit: () => FavoriteStatusCubit(
                watchFavoriteProductIds: WatchFavoriteProductIdsUseCase(
                  favoriteRepository,
                ),
                addFavoriteProduct: AddFavoriteProductUseCase(
                  favoriteRepository,
                ),
                removeFavoriteProduct: RemoveFavoriteProductUseCase(
                  favoriteRepository,
                ),
                analyticsService: FakeAnalyticsService(),
                sessionService: sessionService,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Nenhum favorito ainda'), findsOneWidget);
        expect(
          find.textContaining('Toque no coração de um produto no catálogo'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows favorited products and an explicit notice for a favorite that '
      'no longer resolves to a product, instead of a broken card',
      (tester) async {
        final favoriteRepository = _FakeFavoriteRepository(
          seeded: <String>{'product-1', 'product-removed'},
        );

        await mockNetworkImagesFor(() async {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              home: FavoritesPage(
                organizationId: 'org-1',
                createFavoritesBloc: () => FavoritesBloc(
                  listFavoriteProducts: ListFavoriteProductsUseCase(
                    favoriteRepository,
                    _FakeProductRepository(<String, Product>{
                      'product-1': _buildProduct(
                        id: 'product-1',
                        name: 'Camisa Essential',
                      ),
                    }),
                    GetVariantAvailabilityUseCase(
                      const _FakeVariantAvailabilityRepository(),
                    ),
                  ),
                  analyticsService: FakeAnalyticsService(),
                  sessionService: sessionService,
                ),
                createFavoriteStatusCubit: () => FavoriteStatusCubit(
                  watchFavoriteProductIds: WatchFavoriteProductIdsUseCase(
                    favoriteRepository,
                  ),
                  addFavoriteProduct: AddFavoriteProductUseCase(
                    favoriteRepository,
                  ),
                  removeFavoriteProduct: RemoveFavoriteProductUseCase(
                    favoriteRepository,
                  ),
                  analyticsService: FakeAnalyticsService(),
                  sessionService: sessionService,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Camisa Essential'), findsOneWidget);
          expect(
            find.textContaining('1 favorito não está mais disponível'),
            findsOneWidget,
          );
        });
      },
    );

    testWidgets(
      'unfavoriting a card from the favorites screen itself removes it '
      'immediately (optimistic UI)',
      (tester) async {
        final favoriteRepository = _FakeFavoriteRepository(
          seeded: <String>{'product-1'},
        );

        await mockNetworkImagesFor(() async {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              home: FavoritesPage(
                organizationId: 'org-1',
                createFavoritesBloc: () => FavoritesBloc(
                  listFavoriteProducts: ListFavoriteProductsUseCase(
                    favoriteRepository,
                    _FakeProductRepository(<String, Product>{
                      'product-1': _buildProduct(
                        id: 'product-1',
                        name: 'Camisa Essential',
                      ),
                    }),
                    GetVariantAvailabilityUseCase(
                      const _FakeVariantAvailabilityRepository(),
                    ),
                  ),
                  analyticsService: FakeAnalyticsService(),
                  sessionService: sessionService,
                ),
                createFavoriteStatusCubit: () => FavoriteStatusCubit(
                  watchFavoriteProductIds: WatchFavoriteProductIdsUseCase(
                    favoriteRepository,
                  ),
                  addFavoriteProduct: AddFavoriteProductUseCase(
                    favoriteRepository,
                  ),
                  removeFavoriteProduct: RemoveFavoriteProductUseCase(
                    favoriteRepository,
                  ),
                  analyticsService: FakeAnalyticsService(),
                  sessionService: sessionService,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Camisa Essential'), findsOneWidget);

          await tester.tap(find.byIcon(Icons.favorite));
          await tester.pumpAndSettle();

          expect(find.text('Camisa Essential'), findsNothing);
          expect(find.text('Nenhum favorito ainda'), findsOneWidget);
        });
      },
    );
  });
}

Product _buildProduct({required String id, required String name}) {
  final now = DateTime.utc(2026, 1, 1);
  return Product(
    id: id,
    organizationId: 'org-1',
    sku: Sku.parse('SKU-$id'),
    reference: 'REF-$id',
    name: name,
    status: ProductStatus.active,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: ProductSyncStatus.synced,
  );
}

final class _FakeVariantAvailabilityRepository
    implements VariantAvailabilityRepository {
  const _FakeVariantAvailabilityRepository();

  @override
  Future<AppResult<List<VariantAvailability>>> listByProductIds({
    required String organizationId,
    required Iterable<String> productIds,
  }) async {
    return const AppSuccess<List<VariantAvailability>>(<VariantAvailability>[]);
  }

  @override
  Future<AppResult<List<VariantAvailability>>> listByVariantIds({
    required String organizationId,
    required Iterable<String> variantIds,
  }) async {
    return const AppSuccess<List<VariantAvailability>>(<VariantAvailability>[]);
  }
}

final class _FakeProductRepository implements ProductRepository {
  _FakeProductRepository(this._productsById);

  final Map<String, Product> _productsById;

  @override
  Future<AppResult<List<Product>>> getByIds({
    required String organizationId,
    required List<String> ids,
  }) async {
    return AppSuccess<List<Product>>(
      ids
          .map((id) => _productsById[id])
          .whereType<Product>()
          .toList(growable: false),
    );
  }

  @override
  Future<AppResult<bool>> existsBySku({
    required String organizationId,
    required Sku sku,
    String? excludingProductId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<Product>> create({required Product product}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<Product>> update({required Product product}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<Product>> getById({
    required String organizationId,
    required String id,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<List<Product>>> listRecentlyLaunched({
    required String organizationId,
    String? companyId,
    int limit = 12,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<ProductCatalogPage>> listCatalog({
    required String organizationId,
    String? companyId,
    String? cursor,
    int limit = 20,
  }) => throw UnimplementedError();
}

/// In-memory [FavoriteRepository] fake for widget tests: [seeded] ids start
/// already favorited, `watchFavoriteProductIds` replays the current set
/// immediately (mirroring Drift's own reactivity), and `listFavorites`
/// returns every seeded id as a single, newest-first page.
final class _FakeFavoriteRepository implements FavoriteRepository {
  _FakeFavoriteRepository({Set<String> seeded = const <String>{}})
    : _favoriteIds = Set<String>.of(seeded);

  Set<String> _favoriteIds;
  final _updates = StreamController<Set<String>>.broadcast();

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

  @override
  Future<AppResult<FavoriteProduct>> addFavorite({
    required String organizationId,
    required String userId,
    required String productId,
    String? companyId,
  }) async {
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
  }) async {
    final items = _favoriteIds
        .map(
          (productId) => FavoriteProduct(
            productId: productId,
            userId: userId,
            organizationId: organizationId,
            createdAt: DateTime.utc(2026, 1, 1),
            syncStatus: FavoriteSyncStatus.synced,
          ),
        )
        .toList(growable: false);
    return AppSuccess<FavoriteProductPage>(
      FavoriteProductPage(items: items, hasMore: false),
    );
  }
}
