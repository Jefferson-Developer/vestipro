import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/auth/auth.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/favorites/favorites.dart';
import 'package:vestipro/features/products/products.dart';

class _MockSessionService extends Mock implements SessionService {}

void main() {
  group('FavoritesBloc', () {
    late FakeAnalyticsService analyticsService;
    late _MockSessionService sessionService;

    const signedInUser = SessionUser(uid: 'user-1', emailVerified: true);

    setUp(() {
      analyticsService = FakeAnalyticsService();
      sessionService = _MockSessionService();
      when(() => sessionService.currentUser).thenReturn(signedInUser);
    });

    FavoritesBloc buildBloc({
      required _ScriptedFavoriteRepository favoriteRepository,
      required _ScriptedFavoritesProductRepository productRepository,
    }) {
      return FavoritesBloc(
        listFavoriteProducts: ListFavoriteProductsUseCase(
          favoriteRepository,
          productRepository,
          GetVariantAvailabilityUseCase(
            const _FakeVariantAvailabilityRepository(),
          ),
        ),
        analyticsService: analyticsService,
        sessionService: sessionService,
      );
    }

    blocTest<FavoritesBloc, FavoritesState>(
      'loads the favorited products, already hydrated',
      build: () => buildBloc(
        favoriteRepository: _ScriptedFavoriteRepository(
          FavoriteProductPage(
            items: <FavoriteProduct>[
              _favorite(productId: 'product-1'),
              _favorite(productId: 'product-2'),
            ],
            hasMore: false,
          ),
        ),
        productRepository:
            _ScriptedFavoritesProductRepository(<String, Product>{
              'product-1': _buildProduct(id: 'product-1'),
              'product-2': _buildProduct(id: 'product-2'),
            }),
      ),
      act: (bloc) => bloc.add(const FavoritesStarted(organizationId: 'org-1')),
      expect: () => <Object>[
        isA<FavoritesState>().having(
          (state) => state.status,
          'status',
          FavoritesLoadStatus.loading,
        ),
        isA<FavoritesState>()
            .having(
              (state) => state.status,
              'status',
              FavoritesLoadStatus.success,
            )
            .having(
              (state) => state.products.map((p) => p.id).toList(),
              'products',
              <String>['product-1', 'product-2'],
            )
            .having((state) => state.unavailableCount, 'unavailableCount', 0),
      ],
      verify: (_) {
        expect(
          analyticsService.loggedEvents.map((event) => event.name),
          contains(AnalyticsEvents.favoritesViewed),
        );
      },
    );

    blocTest<FavoritesBloc, FavoritesState>(
      'drops a favorited product that no longer exists and surfaces it as '
      'unavailableCount, instead of a broken card (TASK-079)',
      build: () => buildBloc(
        favoriteRepository: _ScriptedFavoriteRepository(
          FavoriteProductPage(
            items: <FavoriteProduct>[
              _favorite(productId: 'product-1'),
              _favorite(productId: 'product-removed'),
            ],
            hasMore: false,
          ),
        ),
        productRepository: _ScriptedFavoritesProductRepository(
          <String, Product>{'product-1': _buildProduct(id: 'product-1')},
        ),
      ),
      act: (bloc) => bloc.add(const FavoritesStarted(organizationId: 'org-1')),
      skip: 1,
      expect: () => <Object>[
        isA<FavoritesState>()
            .having(
              (state) => state.status,
              'status',
              FavoritesLoadStatus.success,
            )
            .having(
              (state) => state.products.map((p) => p.id).toList(),
              'products',
              <String>['product-1'],
            )
            .having((state) => state.unavailableCount, 'unavailableCount', 1),
      ],
    );

    blocTest<FavoritesBloc, FavoritesState>(
      'emits empty when there are no favorites at all',
      build: () => buildBloc(
        favoriteRepository: _ScriptedFavoriteRepository(
          const FavoriteProductPage(items: <FavoriteProduct>[], hasMore: false),
        ),
        productRepository: _ScriptedFavoritesProductRepository(
          const <String, Product>{},
        ),
      ),
      act: (bloc) => bloc.add(const FavoritesStarted(organizationId: 'org-1')),
      skip: 1,
      expect: () => <Object>[
        isA<FavoritesState>().having(
          (state) => state.status,
          'status',
          FavoritesLoadStatus.empty,
        ),
      ],
    );

    blocTest<FavoritesBloc, FavoritesState>(
      'fails closed instead of loading favorites for nobody when there is '
      'no signed-in user',
      build: () {
        when(() => sessionService.currentUser).thenReturn(null);
        return buildBloc(
          favoriteRepository: _ScriptedFavoriteRepository(
            const FavoriteProductPage(
              items: <FavoriteProduct>[],
              hasMore: false,
            ),
          ),
          productRepository: _ScriptedFavoritesProductRepository(
            const <String, Product>{},
          ),
        );
      },
      act: (bloc) => bloc.add(const FavoritesStarted(organizationId: 'org-1')),
      skip: 1,
      expect: () => <Object>[
        isA<FavoritesState>().having(
          (state) => state.status,
          'status',
          FavoritesLoadStatus.failure,
        ),
      ],
    );
  });
}

FavoriteProduct _favorite({required String productId}) {
  return FavoriteProduct(
    productId: productId,
    userId: 'user-1',
    organizationId: 'org-1',
    createdAt: DateTime.utc(2026, 1, 1),
    syncStatus: FavoriteSyncStatus.synced,
  );
}

Product _buildProduct({required String id}) {
  final now = DateTime.utc(2026, 1, 1);
  return Product(
    id: id,
    organizationId: 'org-1',
    sku: Sku.parse('SKU-$id'),
    reference: 'REF-$id',
    name: 'Produto $id',
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

/// A [FavoriteRepository] whose `listFavorites` always answers with one
/// pre-scripted [FavoriteProductPage] — only what `ListFavoriteProductsUseCase`
/// needs for these bloc tests.
final class _ScriptedFavoriteRepository implements FavoriteRepository {
  _ScriptedFavoriteRepository(this._page);

  final FavoriteProductPage _page;

  @override
  Future<AppResult<FavoriteProductPage>> listFavorites({
    required String organizationId,
    required String userId,
    int offset = 0,
    int limit = 20,
  }) async => AppSuccess<FavoriteProductPage>(_page);

  @override
  Stream<Set<String>> watchFavoriteProductIds({
    required String organizationId,
    required String userId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<FavoriteProduct>> addFavorite({
    required String organizationId,
    required String userId,
    required String productId,
    String? companyId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<void>> removeFavorite({
    required String organizationId,
    required String userId,
    required String productId,
  }) => throw UnimplementedError();
}

/// A [ProductRepository] whose `getByIds` answers from a fixed map, silently
/// skipping any id absent from it — mirroring the real contract's "a stale
/// favorited id is dropped, never a broken card" behavior.
final class _ScriptedFavoritesProductRepository implements ProductRepository {
  _ScriptedFavoritesProductRepository(this._productsById);

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
    CatalogFilter? filter,
  }) => throw UnimplementedError();
}
