import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('CreateProductUseCase', () {
    late _InMemoryProductRepository repository;
    late CreateProductUseCase useCase;

    setUp(() {
      repository = _InMemoryProductRepository();
      useCase = CreateProductUseCase(repository);
    });

    test(
      'creates a product always as draft, even with minimal fields',
      () async {
        final result = await useCase.call(
          id: 'product-1',
          organizationId: 'org-1',
          companyId: 'company-1',
          sku: 'camisa-001',
          reference: 'REF-001',
          name: 'Camisa Essential',
          createdBy: 'user-1',
        );

        expect(result, isA<AppSuccess<Product>>());
        final product = (result as AppSuccess<Product>).value;
        expect(product.status, ProductStatus.draft);
        expect(product.sku, Sku.parse('CAMISA-001'));
        expect(product.syncStatus, ProductSyncStatus.pending);
        expect(product.version, 1);
        expect(repository.products.single.id, 'product-1');
      },
    );

    test(
      'rejects a blank name/reference without touching the repository',
      () async {
        final result = await useCase.call(
          id: 'product-1',
          organizationId: 'org-1',
          sku: 'CAMISA-001',
          reference: '   ',
          name: '  ',
          createdBy: 'user-1',
        );

        expect(result, isA<AppFailure<Product>>());
        final failure = (result as AppFailure<Product>).failure;
        expect(failure, isA<ValidationFailure>());
        expect(
          (failure as ValidationFailure).fieldErrors,
          containsPair('name', isNotEmpty),
        );
        expect(failure.fieldErrors, containsPair('reference', isNotEmpty));
        expect(repository.products, isEmpty);
      },
    );

    test('rejects an invalid SKU format', () async {
      final result = await useCase.call(
        id: 'product-1',
        organizationId: 'org-1',
        sku: '!!',
        reference: 'REF-001',
        name: 'Camisa Essential',
        createdBy: 'user-1',
      );

      expect(result, isA<AppFailure<Product>>());
      expect(repository.products, isEmpty);
    });

    test('rejects an invalid EAN when informed', () async {
      final result = await useCase.call(
        id: 'product-1',
        organizationId: 'org-1',
        sku: 'CAMISA-001',
        reference: 'REF-001',
        name: 'Camisa Essential',
        ean: '123',
        createdBy: 'user-1',
      );

      expect(result, isA<AppFailure<Product>>());
      final failure =
          (result as AppFailure<Product>).failure as ValidationFailure;
      expect(failure.fieldErrors, containsPair('ean', isNotEmpty));
    });

    test('blocks a duplicate SKU within the same organization', () async {
      repository.seed(_buildProduct(id: 'existing', sku: 'CAMISA-001'));

      final result = await useCase.call(
        id: 'product-1',
        organizationId: 'org-1',
        sku: 'camisa-001',
        reference: 'REF-002',
        name: 'Camisa Essential 2',
        createdBy: 'user-1',
      );

      expect(result, isA<AppFailure<Product>>());
      expect((result as AppFailure<Product>).failure, isA<ConflictFailure>());
      expect(repository.products, hasLength(1));
    });
  });
}

Product _buildProduct({
  required String id,
  required String sku,
  String organizationId = 'org-1',
  ProductStatus status = ProductStatus.draft,
  String? categoryId,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Product(
    id: id,
    organizationId: organizationId,
    sku: Sku.parse(sku),
    reference: 'REF-$id',
    name: 'Produto $id',
    categoryId: categoryId,
    status: status,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: ProductSyncStatus.pending,
  );
}

final class _InMemoryProductRepository implements ProductRepository {
  final List<Product> products = <Product>[];

  void seed(Product product) => products.add(product);

  @override
  Future<AppResult<bool>> existsBySku({
    required String organizationId,
    required Sku sku,
    String? excludingProductId,
  }) async {
    return AppSuccess<bool>(
      products.any(
        (product) =>
            product.organizationId == organizationId &&
            product.sku == sku &&
            product.id != excludingProductId,
      ),
    );
  }

  @override
  Future<AppResult<Product>> create({required Product product}) async {
    products.add(product);
    return AppSuccess<Product>(product);
  }

  @override
  Future<AppResult<Product>> update({required Product product}) async {
    final index = products.indexWhere((item) => item.id == product.id);
    if (index == -1) {
      return const AppFailure<Product>(
        NotFoundFailure('Product not found.', code: 'product_not_found'),
      );
    }
    products[index] = product;
    return AppSuccess<Product>(product);
  }

  @override
  Future<AppResult<Product>> getById({
    required String organizationId,
    required String id,
  }) async {
    for (final product in products) {
      if (product.organizationId == organizationId && product.id == id) {
        return AppSuccess<Product>(product);
      }
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
      products
          .where(
            (product) =>
                product.organizationId == organizationId &&
                wanted.contains(product.id),
          )
          .toList(growable: false),
    );
  }
}
