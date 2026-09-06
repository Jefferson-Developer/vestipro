import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/favorites/favorites.dart';
import 'package:vestipro/features/products/products.dart';

class _InMemoryFavoriteRepository implements FavoriteRepository {
  final List<FavoriteProduct> favorites = <FavoriteProduct>[];
  bool hasMore = false;

  @override
  Stream<Set<String>> watchFavoriteProductIds({
    required String organizationId,
    required String userId,
  }) => Stream<Set<String>>.value(
    favorites.map((favorite) => favorite.productId).toSet(),
  );

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

  @override
  Future<AppResult<FavoriteProductPage>> listFavorites({
    required String organizationId,
    required String userId,
    int offset = 0,
    int limit = 20,
  }) async {
    return AppSuccess<FavoriteProductPage>(
      FavoriteProductPage(items: favorites, hasMore: hasMore),
    );
  }
}

class _InMemoryProductRepository implements ProductRepository {
  final List<Product> products = <Product>[];

  @override
  Future<AppResult<bool>> existsBySku({
    required String organizationId,
    required Sku sku,
    String? excludingProductId,
  }) async => const AppSuccess<bool>(false);

  @override
  Future<AppResult<Product>> create({required Product product}) async {
    products.add(product);
    return AppSuccess<Product>(product);
  }

  @override
  Future<AppResult<Product>> update({required Product product}) async {
    final index = products.indexWhere((item) => item.id == product.id);
    products[index] = product;
    return AppSuccess<Product>(product);
  }

  @override
  Future<AppResult<Product>> getById({
    required String organizationId,
    required String id,
  }) async {
    for (final product in products) {
      if (product.id == id) return AppSuccess<Product>(product);
    }
    return const AppFailure<Product>(
      NotFoundFailure('Product not found.', code: 'product_not_found'),
    );
  }

  @override
  Future<AppResult<List<Product>>> getByIds({
    required String organizationId,
    required List<String> ids,
  }) async {
    final wanted = ids.toSet();
    return AppSuccess<List<Product>>(
      products.where((product) => wanted.contains(product.id)).toList(),
    );
  }

  @override
  Future<AppResult<List<Product>>> listRecentlyLaunched({
    required String organizationId,
    String? companyId,
    int limit = 12,
  }) async => const AppSuccess<List<Product>>(<Product>[]);

  @override
  Future<AppResult<ProductCatalogPage>> listCatalog({
    required String organizationId,
    String? companyId,
    String? cursor,
    int limit = 20,
    CatalogFilter? filter,
  }) async => const AppSuccess<ProductCatalogPage>(
    ProductCatalogPage(products: <Product>[], hasMore: false),
  );
}

class _InMemoryVariantAvailabilityRepository
    implements VariantAvailabilityRepository {
  final List<VariantAvailability> availabilities = <VariantAvailability>[];

  @override
  Future<AppResult<List<VariantAvailability>>> listByVariantIds({
    required String organizationId,
    required Iterable<String> variantIds,
  }) async {
    final wanted = variantIds.toSet();
    return AppSuccess<List<VariantAvailability>>(
      availabilities
          .where((availability) => wanted.contains(availability.variantId))
          .toList(),
    );
  }

  @override
  Future<AppResult<List<VariantAvailability>>> listByProductIds({
    required String organizationId,
    required Iterable<String> productIds,
  }) async {
    final wanted = productIds.toSet();
    return AppSuccess<List<VariantAvailability>>(
      availabilities
          .where((availability) => wanted.contains(availability.productId))
          .toList(),
    );
  }
}

FavoriteProduct _buildFavorite(String productId, {DateTime? createdAt}) {
  return FavoriteProduct(
    productId: productId,
    userId: 'user-1',
    organizationId: 'org-1',
    createdAt: createdAt ?? DateTime.utc(2026, 1, 1),
    syncStatus: FavoriteSyncStatus.synced,
  );
}

Product _buildProduct(String id) {
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

void main() {
  group('ListFavoriteProductsUseCase', () {
    late _InMemoryFavoriteRepository favoriteRepository;
    late _InMemoryProductRepository productRepository;
    late _InMemoryVariantAvailabilityRepository availabilityRepository;
    late ListFavoriteProductsUseCase useCase;

    setUp(() {
      favoriteRepository = _InMemoryFavoriteRepository();
      productRepository = _InMemoryProductRepository();
      availabilityRepository = _InMemoryVariantAvailabilityRepository();
      useCase = ListFavoriteProductsUseCase(
        favoriteRepository,
        productRepository,
        GetVariantAvailabilityUseCase(availabilityRepository),
      );
    });

    test('hydrates favorited ids into full products, preserving favorited '
        'order', () async {
      favoriteRepository.favorites.addAll(<FavoriteProduct>[
        _buildFavorite('product-2'),
        _buildFavorite('product-1'),
      ]);
      productRepository.products.addAll(<Product>[
        _buildProduct('product-1'),
        _buildProduct('product-2'),
      ]);

      final result = await useCase.call(
        organizationId: 'org-1',
        userId: 'user-1',
      );

      expect(result, isA<AppSuccess<FavoriteCatalogPage>>());
      final page = (result as AppSuccess<FavoriteCatalogPage>).value;
      expect(page.products.map((product) => product.id), <String>[
        'product-2',
        'product-1',
      ]);
      expect(page.unavailableCount, 0);
    });

    test(
      'drops a favorited id that no longer resolves to an existing product '
      'and counts it into unavailableCount, instead of a broken card',
      () async {
        favoriteRepository.favorites.addAll(<FavoriteProduct>[
          _buildFavorite('product-1'),
          _buildFavorite('discontinued-product'),
        ]);
        productRepository.products.add(_buildProduct('product-1'));

        final result = await useCase.call(
          organizationId: 'org-1',
          userId: 'user-1',
        );

        expect(result, isA<AppSuccess<FavoriteCatalogPage>>());
        final page = (result as AppSuccess<FavoriteCatalogPage>).value;
        expect(page.products.map((product) => product.id), <String>[
          'product-1',
        ]);
        expect(page.unavailableCount, 1);
      },
    );

    test('returns an empty page without querying products/availability when '
        'there are no favorites', () async {
      final result = await useCase.call(
        organizationId: 'org-1',
        userId: 'user-1',
      );

      expect(result, isA<AppSuccess<FavoriteCatalogPage>>());
      final page = (result as AppSuccess<FavoriteCatalogPage>).value;
      expect(page.products, isEmpty);
      expect(page.availabilityByProductId, isEmpty);
      expect(page.unavailableCount, 0);
    });

    test(
      'resolves the primary availability for each favorited product',
      () async {
        favoriteRepository.favorites.add(_buildFavorite('product-1'));
        productRepository.products.add(_buildProduct('product-1'));
        availabilityRepository.availabilities.add(
          const VariantAvailability(
            variantId: 'variant-1',
            productId: 'product-1',
            status: VariantAvailabilityStatus.readyStock,
            availableQuantity: 10,
          ),
        );

        final result = await useCase.call(
          organizationId: 'org-1',
          userId: 'user-1',
        );

        expect(result, isA<AppSuccess<FavoriteCatalogPage>>());
        final page = (result as AppSuccess<FavoriteCatalogPage>).value;
        expect(
          page.availabilityByProductId['product-1']?.variantId,
          'variant-1',
        );
      },
    );

    test('propagates hasMore/nextOffset from the favorites page', () async {
      favoriteRepository.hasMore = true;
      favoriteRepository.favorites.add(_buildFavorite('product-1'));
      productRepository.products.add(_buildProduct('product-1'));

      final result = await useCase.call(
        organizationId: 'org-1',
        userId: 'user-1',
        offset: 20,
        limit: 20,
      );

      expect(result, isA<AppSuccess<FavoriteCatalogPage>>());
      final page = (result as AppSuccess<FavoriteCatalogPage>).value;
      expect(page.hasMore, isTrue);
      expect(page.nextOffset, 40);
    });

    test('rejects an empty organizationId with a ValidationFailure', () async {
      final result = await useCase.call(organizationId: '  ', userId: 'user-1');

      expect(result, isA<AppFailure<FavoriteCatalogPage>>());
      final failure = (result as AppFailure<FavoriteCatalogPage>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).code,
        'invalid_list_favorite_products_payload',
      );
    });

    test('rejects an empty userId with a ValidationFailure', () async {
      final result = await useCase.call(organizationId: 'org-1', userId: '');

      expect(result, isA<AppFailure<FavoriteCatalogPage>>());
    });
  });
}
