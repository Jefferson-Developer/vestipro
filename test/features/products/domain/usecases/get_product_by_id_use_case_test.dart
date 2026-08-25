import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/products.dart';

/// In-memory fake that mirrors how a real implementation must scope lookups
/// by organization (composite key), so the cross-tenant test below exercises
/// actual isolation behavior instead of a canned mock response.
class _FakeProductRepository implements ProductRepository {
  final Map<String, Product> _productsByCompositeKey = <String, Product>{};

  void seed(Product product) {
    _productsByCompositeKey['${product.organizationId}:${product.id}'] =
        product;
  }

  @override
  Future<AppResult<Product>> getById({
    required String organizationId,
    required String id,
  }) async {
    final product = _productsByCompositeKey['$organizationId:$id'];
    if (product == null) {
      return const AppFailure<Product>(
        NotFoundFailure('Product not found.', code: 'product_not_found'),
      );
    }
    return AppSuccess<Product>(product);
  }

  @override
  Future<AppResult<bool>> existsBySku({
    required String organizationId,
    required Sku sku,
    String? excludingProductId,
  }) async {
    return AppSuccess<bool>(
      _productsByCompositeKey.values.any(
        (product) =>
            product.organizationId == organizationId &&
            product.sku == sku &&
            product.id != excludingProductId,
      ),
    );
  }

  @override
  Future<AppResult<Product>> create({required Product product}) async {
    _productsByCompositeKey['${product.organizationId}:${product.id}'] =
        product;
    return AppSuccess<Product>(product);
  }

  @override
  Future<AppResult<Product>> update({required Product product}) async {
    final key = '${product.organizationId}:${product.id}';
    if (!_productsByCompositeKey.containsKey(key)) {
      return const AppFailure<Product>(
        NotFoundFailure('Product not found.', code: 'product_not_found'),
      );
    }
    _productsByCompositeKey[key] = product;
    return AppSuccess<Product>(product);
  }

  @override
  Future<AppResult<List<Product>>> getByIds({
    required String organizationId,
    required List<String> ids,
  }) async {
    final wanted = ids.toSet();
    return AppSuccess<List<Product>>(
      _productsByCompositeKey.values
          .where(
            (product) =>
                product.organizationId == organizationId &&
                wanted.contains(product.id),
          )
          .toList(growable: false),
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

void main() {
  group('GetProductByIdUseCase', () {
    late _FakeProductRepository repository;
    late GetProductByIdUseCase useCase;

    setUp(() {
      repository = _FakeProductRepository();
      useCase = GetProductByIdUseCase(repository);
      repository.seed(_buildProduct());
    });

    test('returns the product when the organization matches', () async {
      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'product-1',
      );

      expect(result, isA<AppSuccess<Product>>());
      expect((result as AppSuccess<Product>).value.id, 'product-1');
    });

    test('fails when the product id does not exist', () async {
      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'missing-product',
      );

      expect(result, isA<AppFailure<Product>>());
      expect((result as AppFailure<Product>).failure, isA<NotFoundFailure>());
    });

    test(
      'fails when the product belongs to a different organization',
      () async {
        final result = await useCase.call(
          organizationId: 'org-2',
          id: 'product-1',
        );

        expect(result, isA<AppFailure<Product>>());
        expect((result as AppFailure<Product>).failure, isA<NotFoundFailure>());
      },
    );

    test(
      'rejects an empty organization id without touching the repository',
      () async {
        final result = await useCase.call(
          organizationId: '  ',
          id: 'product-1',
        );

        expect(result, isA<AppFailure<Product>>());
        final failure = (result as AppFailure<Product>).failure;
        expect(failure, isA<ValidationFailure>());
        expect(
          (failure as ValidationFailure).fieldErrors,
          containsPair('organizationId', 'OrganizationId is required.'),
        );
      },
    );

    test('rejects an empty id', () async {
      final result = await useCase.call(organizationId: 'org-1', id: '   ');

      expect(result, isA<AppFailure<Product>>());
      final failure = (result as AppFailure<Product>).failure;
      expect(
        (failure as ValidationFailure).fieldErrors,
        containsPair('id', 'Id is required.'),
      );
    });
  });
}

Product _buildProduct() {
  final now = DateTime.utc(2026, 1, 1);
  return Product(
    id: 'product-1',
    organizationId: 'org-1',
    sku: Sku.parse('CAMISA-001'),
    reference: 'REF-001',
    name: 'Camisa Essential',
    status: ProductStatus.active,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: ProductSyncStatus.synced,
  );
}
