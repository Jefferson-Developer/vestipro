import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/products.dart';

class _InMemoryProductCollectionLinkRepository
    implements ProductCollectionLinkRepository {
  final List<ProductCollectionLink> links = <ProductCollectionLink>[];

  @override
  Future<AppResult<ProductCollectionLink>> create({
    required ProductCollectionLink link,
  }) async {
    links.add(link);
    return AppSuccess<ProductCollectionLink>(link);
  }

  @override
  Future<AppResult<List<ProductCollectionLink>>> listByProduct({
    required String organizationId,
    required String productId,
  }) async {
    return AppSuccess<List<ProductCollectionLink>>(
      links.where((link) => link.productId == productId).toList(),
    );
  }

  @override
  Future<AppResult<List<ProductCollectionLink>>> listByCollection({
    required String organizationId,
    required String collectionId,
  }) async {
    return AppSuccess<List<ProductCollectionLink>>(
      links.where((link) => link.collectionId == collectionId).toList(),
    );
  }

  @override
  Future<AppResult<bool>> deleteByProductAndCollection({
    required String organizationId,
    required String productId,
    required String collectionId,
  }) async {
    links.removeWhere(
      (link) =>
          link.productId == productId && link.collectionId == collectionId,
    );
    return const AppSuccess<bool>(true);
  }

  @override
  Future<AppResult<bool>> deleteAllByProduct({
    required String organizationId,
    required String productId,
  }) async {
    links.removeWhere((link) => link.productId == productId);
    return const AppSuccess<bool>(true);
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
  }) async {
    return const AppSuccess<List<Product>>(<Product>[]);
  }

  @override
  Future<AppResult<ProductCatalogPage>> listCatalog({
    required String organizationId,
    String? companyId,
    String? cursor,
    int limit = 20,
  }) async {
    return const AppSuccess<ProductCatalogPage>(
      ProductCatalogPage(products: <Product>[], hasMore: false),
    );
  }
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
  group('ListProductsByCollectionUseCase', () {
    late _InMemoryProductCollectionLinkRepository linkRepository;
    late _InMemoryProductRepository productRepository;
    late ListProductsByCollectionUseCase useCase;

    setUp(() {
      linkRepository = _InMemoryProductCollectionLinkRepository();
      productRepository = _InMemoryProductRepository();
      useCase = ListProductsByCollectionUseCase(
        linkRepository,
        productRepository,
      );
    });

    test('returns every product linked to the collection', () async {
      productRepository.products.addAll(<Product>[
        _buildProduct('product-1'),
        _buildProduct('product-2'),
      ]);
      linkRepository.links.addAll(<ProductCollectionLink>[
        ProductCollectionLink(
          id: 'link-1',
          organizationId: 'org-1',
          productId: 'product-1',
          collectionId: 'collection-1',
          createdAt: DateTime.utc(2026, 1, 1),
          createdBy: 'user-1',
        ),
      ]);

      final result = await useCase.call(
        organizationId: 'org-1',
        collectionId: 'collection-1',
      );

      expect(result, isA<AppSuccess<List<Product>>>());
      final products = (result as AppSuccess<List<Product>>).value;
      expect(products.map((product) => product.id), <String>['product-1']);
    });

    test('a product associated with a now-closed collection is still '
        'listed (closing a collection never hides its own product list) — '
        'the caller decides how to flag "encerrada" in the UI', () async {
      productRepository.products.add(_buildProduct('product-1'));
      linkRepository.links.add(
        ProductCollectionLink(
          id: 'link-1',
          organizationId: 'org-1',
          productId: 'product-1',
          collectionId: 'collection-1',
          createdAt: DateTime.utc(2026, 1, 1),
          createdBy: 'user-1',
        ),
      );

      final result = await useCase.call(
        organizationId: 'org-1',
        collectionId: 'collection-1',
      );

      expect(result, isA<AppSuccess<List<Product>>>());
      expect(
        (result as AppSuccess<List<Product>>).value.single.id,
        'product-1',
      );
    });

    test('returns an empty list without querying products when there are '
        'no links', () async {
      final result = await useCase.call(
        organizationId: 'org-1',
        collectionId: 'collection-1',
      );

      expect(result, isA<AppSuccess<List<Product>>>());
      expect((result as AppSuccess<List<Product>>).value, isEmpty);
    });
  });
}
