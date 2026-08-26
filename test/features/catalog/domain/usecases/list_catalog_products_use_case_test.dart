import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog/catalog.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('ListCatalogProductsUseCase', () {
    test(
      'delegates to ProductRepository.listCatalog with a trimmed organizationId',
      () async {
        final repository = _FakeProductRepository(
          AppSuccess<ProductCatalogPage>(
            ProductCatalogPage(
              products: <Product>[_buildProduct(id: 'product-1')],
              hasMore: true,
              nextCursor: 'product-1',
            ),
          ),
        );
        final useCase = ListCatalogProductsUseCase(repository);

        final result = await useCase(
          organizationId: ' org-1 ',
          companyId: 'company-1',
          cursor: 'cursor-0',
          limit: 5,
        );

        expect(result, isA<AppSuccess<ProductCatalogPage>>());
        expect(repository.lastOrganizationId, 'org-1');
        expect(repository.lastCompanyId, 'company-1');
        expect(repository.lastCursor, 'cursor-0');
        expect(repository.lastLimit, 5);
      },
    );

    test('uses kProductGridPageSize as the default limit', () async {
      final repository = _FakeProductRepository(
        const AppSuccess<ProductCatalogPage>(
          ProductCatalogPage(products: <Product>[], hasMore: false),
        ),
      );
      final useCase = ListCatalogProductsUseCase(repository);

      await useCase(organizationId: 'org-1');

      expect(repository.lastLimit, kProductGridPageSize);
    });

    test('propagates a repository failure', () async {
      const failure = UnexpectedFailure(
        'boom',
        code: 'product_local_list_catalog_unexpected',
      );
      final repository = _FakeProductRepository(
        const AppFailure<ProductCatalogPage>(failure),
      );
      final useCase = ListCatalogProductsUseCase(repository);

      final result = await useCase(organizationId: 'org-1');

      expect(result, isA<AppFailure<ProductCatalogPage>>());
      expect((result as AppFailure<ProductCatalogPage>).failure, failure);
    });
  });
}

class _FakeProductRepository implements ProductRepository {
  _FakeProductRepository(this._result);

  final AppResult<ProductCatalogPage> _result;

  String? lastOrganizationId;
  String? lastCompanyId;
  String? lastCursor;
  int? lastLimit;

  @override
  Future<AppResult<ProductCatalogPage>> listCatalog({
    required String organizationId,
    String? companyId,
    String? cursor,
    int limit = 20,
    CatalogFilter? filter,
  }) async {
    lastOrganizationId = organizationId;
    lastCompanyId = companyId;
    lastCursor = cursor;
    lastLimit = limit;
    return _result;
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
  Future<AppResult<List<Product>>> getByIds({
    required String organizationId,
    required List<String> ids,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<List<Product>>> listRecentlyLaunched({
    required String organizationId,
    String? companyId,
    int limit = 12,
  }) => throw UnimplementedError();
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
