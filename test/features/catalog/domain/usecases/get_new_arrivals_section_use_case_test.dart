import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog/catalog.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('GetNewArrivalsSectionUseCase', () {
    const config = CatalogHomeSectionConfig(
      type: CatalogHomeSectionType.newArrivals,
      title: 'Lançamentos',
      order: 1,
      priority: 1,
    );

    test('maps products to items with a "Lançamento" badge', () async {
      final product = _product(id: 'product-1');
      final useCase = GetNewArrivalsSectionUseCase(
        _FakeRepository(AppSuccess<List<Product>>(<Product>[product])),
      );

      final result = await useCase(organizationId: 'org-1', config: config);

      final section = (result as AppSuccess<CatalogHomeSection>).value;
      expect(section.items, hasLength(1));
      expect(section.items.single.id, 'product-1');
      expect(section.items.single.title, 'Produto product-1');
      expect(section.items.single.badgeLabel, 'Lançamento');
    });

    test('propagates a repository failure', () async {
      final useCase = GetNewArrivalsSectionUseCase(
        _FakeRepository(
          const AppFailure<List<Product>>(ServerFailure('down', code: 'down')),
        ),
      );

      final result = await useCase(organizationId: 'org-1', config: config);

      expect(result, isA<AppFailure<CatalogHomeSection>>());
    });

    test(
      'returns an empty section when there are no recent products',
      () async {
        final useCase = GetNewArrivalsSectionUseCase(
          _FakeRepository(const AppSuccess<List<Product>>(<Product>[])),
        );

        final result = await useCase(organizationId: 'org-1', config: config);

        final section = (result as AppSuccess<CatalogHomeSection>).value;
        expect(section.isEmpty, isTrue);
      },
    );
  });
}

Product _product({required String id}) {
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

class _FakeRepository implements ProductRepository {
  _FakeRepository(this._result);

  final AppResult<List<Product>> _result;

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
  }) async => _result;
}
