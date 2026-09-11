import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/barcode_scanner/barcode_scanner.dart';
import 'package:vestipro/features/barcode_scanner/data/datasources/alternate_product_code_local_data_source.dart';
import 'package:vestipro/features/barcode_scanner/data/repositories/product_code_lookup_repository_impl.dart';
import 'package:vestipro/features/products/products.dart';

import '../../../products/product_factory.dart';

final class _FakeProductRepository implements ProductRepository {
  final Map<String, Product> byId = <String, Product>{};

  @override
  Future<AppResult<Product>> getById({
    required String organizationId,
    required String id,
  }) async {
    final product = byId[id];
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
  }) => throw UnimplementedError();

  @override
  Future<AppResult<Product>> create({required Product product}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<Product>> update({required Product product}) =>
      throw UnimplementedError();

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

  @override
  Future<AppResult<ProductCatalogPage>> listCatalog({
    required String organizationId,
    String? companyId,
    String? cursor,
    int limit = 20,
    CatalogFilter? filter,
  }) => throw UnimplementedError();
}

final class _FakeProductVariantRepository implements ProductVariantRepository {
  final List<ProductVariant> variants = <ProductVariant>[];

  @override
  Future<AppResult<List<ProductVariant>>> listByOrganization(
    String organizationId,
  ) async {
    return AppSuccess<List<ProductVariant>>(
      variants.where((v) => v.organizationId == organizationId).toList(),
    );
  }

  @override
  Future<AppResult<List<ProductVariant>>> listByProduct({
    required String organizationId,
    required String productId,
  }) async {
    return AppSuccess<List<ProductVariant>>(
      variants.where((v) => v.productId == productId).toList(),
    );
  }

  @override
  Future<AppResult<ProductVariant>> getById({
    required String organizationId,
    required String id,
  }) async {
    for (final variant in variants) {
      if (variant.id == id) return AppSuccess<ProductVariant>(variant);
    }
    return const AppFailure<ProductVariant>(
      NotFoundFailure('Variant not found.', code: 'variant_not_found'),
    );
  }

  @override
  Future<AppResult<ProductVariant>> create({required ProductVariant variant}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<ProductVariant>> update({required ProductVariant variant}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<bool>> existsBySku({
    required String organizationId,
    required Sku sku,
    String? excludingVariantId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<bool>> existsByEan({
    required String organizationId,
    required Ean ean,
    String? excludingVariantId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<bool>> isReferencedByOrder({
    required String organizationId,
    required String variantId,
  }) => throw UnimplementedError();
}

final class _FakeProductSearchRepository implements ProductSearchRepository {
  final Map<ProductSearchSource, List<Product>> byRoutedSource =
      <ProductSearchSource, List<Product>>{
        ProductSearchSource.offline: <Product>[],
        ProductSearchSource.remote: <Product>[],
      };
  int offlineCallCount = 0;
  int remoteCallCount = 0;

  @override
  Future<AppResult<ProductSearchResult>> searchProducts({
    required String organizationId,
    required String query,
    ProductSearchSource source = ProductSearchSource.remote,
    int limit = 20,
  }) async {
    if (source == ProductSearchSource.offline) {
      offlineCallCount += 1;
    } else {
      remoteCallCount += 1;
    }
    return AppSuccess<ProductSearchResult>(
      ProductSearchResult(
        products: byRoutedSource[source] ?? const <Product>[],
        source: source,
        normalizedQuery: query,
      ),
    );
  }
}

final class _FakeAlternateProductCodeLocalDataSource
    implements AlternateProductCodeLocalDataSource {
  final Map<String, AlternateProductCode> byCode =
      <String, AlternateProductCode>{};

  @override
  Future<AlternateProductCode?> findByCode({
    required String organizationId,
    required String code,
  }) async => byCode[code];

  @override
  Future<List<AlternateProductCode>> listByOrganization(
    String organizationId,
  ) async => byCode.values.toList();

  @override
  Future<AlternateProductCode> upsert(AlternateProductCode code) async {
    byCode[code.code] = code;
    return code;
  }
}

ProductVariant _buildVariant({
  required String id,
  required String productId,
  required String sku,
  String? ean,
  String organizationId = 'org-1',
  ProductVariantStatus status = ProductVariantStatus.active,
}) {
  return ProductVariant(
    id: id,
    organizationId: organizationId,
    productId: productId,
    colorId: 'color-1',
    sizeGridTemplateId: 'grid-1',
    sizeId: 'size-1',
    sku: Sku.parse(sku),
    ean: ean == null ? null : Ean.parse(ean),
    status: status,
    createdAt: DateTime.utc(2026, 1, 1),
    createdBy: 'user-1',
    updatedAt: DateTime.utc(2026, 1, 1),
    updatedBy: 'user-1',
    version: 1,
    syncStatus: ProductSyncStatus.synced,
  );
}

void main() {
  group('ProductCodeLookupRepositoryImpl', () {
    late _FakeProductRepository productRepository;
    late _FakeProductVariantRepository variantRepository;
    late _FakeProductSearchRepository searchRepository;
    late _FakeAlternateProductCodeLocalDataSource alternateCodeDataSource;
    late ProductCodeLookupRepositoryImpl repository;

    setUp(() {
      productRepository = _FakeProductRepository();
      variantRepository = _FakeProductVariantRepository();
      searchRepository = _FakeProductSearchRepository();
      alternateCodeDataSource = _FakeAlternateProductCodeLocalDataSource();
      repository = ProductCodeLookupRepositoryImpl(
        variantRepository: variantRepository,
        productRepository: productRepository,
        searchProducts: SearchProductsUseCase(searchRepository),
        alternateCodeDataSource: alternateCodeDataSource,
      );
    });

    test('resolves an exact variant EAN to a single match', () async {
      final product = buildTestProduct(id: 'product-1');
      productRepository.byId['product-1'] = product;
      variantRepository.variants.add(
        _buildVariant(
          id: 'variant-1',
          productId: 'product-1',
          sku: 'CAM-P-AZ',
          ean: '7891234567895',
        ),
      );

      final result = await repository.resolveCode(
        organizationId: 'org-1',
        rawCode: '7891234567895',
      );

      expect(result, isA<AppSuccess<ProductCodeResolution>>());
      final resolution = (result as AppSuccess<ProductCodeResolution>).value;
      expect(resolution.status, ProductCodeResolutionStatus.singleMatch);
      expect(resolution.singleMatchOrNull!.variant!.id, 'variant-1');
      expect(resolution.singleMatchOrNull!.product.id, 'product-1');
    });

    test('resolves an exact variant SKU (case/format insensitive)', () async {
      final product = buildTestProduct(id: 'product-1');
      productRepository.byId['product-1'] = product;
      variantRepository.variants.add(
        _buildVariant(id: 'variant-1', productId: 'product-1', sku: 'CAM-P-AZ'),
      );

      final result = await repository.resolveCode(
        organizationId: 'org-1',
        rawCode: 'cam-p-az',
      );

      final resolution = (result as AppSuccess<ProductCodeResolution>).value;
      expect(resolution.status, ProductCodeResolutionStatus.singleMatch);
      expect(resolution.singleMatchOrNull!.variant!.id, 'variant-1');
    });

    test('an inactive variant never matches', () async {
      final product = buildTestProduct(id: 'product-1');
      productRepository.byId['product-1'] = product;
      variantRepository.variants.add(
        _buildVariant(
          id: 'variant-1',
          productId: 'product-1',
          sku: 'CAM-P-AZ',
          status: ProductVariantStatus.inactive,
        ),
      );

      final result = await repository.resolveCode(
        organizationId: 'org-1',
        rawCode: 'CAM-P-AZ',
      );

      final resolution = (result as AppSuccess<ProductCodeResolution>).value;
      expect(resolution.status, ProductCodeResolutionStatus.notFound);
    });

    test(
      'resolves a product-level code with a single active variant to singleMatch',
      () async {
        final product = buildTestProduct(id: 'product-1', reference: 'REF-1');
        productRepository.byId['product-1'] = product;
        variantRepository.variants.add(
          _buildVariant(
            id: 'variant-1',
            productId: 'product-1',
            sku: 'CAM-P-AZ',
          ),
        );
        searchRepository.byRoutedSource[ProductSearchSource.offline] = [
          product,
        ];

        final result = await repository.resolveCode(
          organizationId: 'org-1',
          rawCode: 'REF-1',
        );

        final resolution = (result as AppSuccess<ProductCodeResolution>).value;
        expect(resolution.status, ProductCodeResolutionStatus.singleMatch);
        expect(resolution.singleMatchOrNull!.variant!.id, 'variant-1');
      },
    );

    test(
      'resolves a product-level code with several active variants to multipleMatches sharing the same product',
      () async {
        final product = buildTestProduct(id: 'product-1', reference: 'REF-1');
        productRepository.byId['product-1'] = product;
        variantRepository.variants.addAll(<ProductVariant>[
          _buildVariant(
            id: 'variant-1',
            productId: 'product-1',
            sku: 'CAM-P-AZ',
          ),
          _buildVariant(
            id: 'variant-2',
            productId: 'product-1',
            sku: 'CAM-M-AZ',
          ),
        ]);
        searchRepository.byRoutedSource[ProductSearchSource.offline] = [
          product,
        ];

        final result = await repository.resolveCode(
          organizationId: 'org-1',
          rawCode: 'REF-1',
        );

        final resolution = (result as AppSuccess<ProductCodeResolution>).value;
        expect(resolution.status, ProductCodeResolutionStatus.multipleMatches);
        expect(resolution.matches, hasLength(2));
        expect(
          resolution.matches.every((m) => m.product.id == 'product-1'),
          isTrue,
        );
        expect(resolution.productId, 'product-1');
      },
    );

    test('an unknown code resolves to notFound', () async {
      final result = await repository.resolveCode(
        organizationId: 'org-1',
        rawCode: '0000000000000',
      );

      final resolution = (result as AppSuccess<ProductCodeResolution>).value;
      expect(resolution.status, ProductCodeResolutionStatus.notFound);
    });

    test(
      'a blank code resolves to notFound without querying anything',
      () async {
        final result = await repository.resolveCode(
          organizationId: 'org-1',
          rawCode: '   ',
        );

        final resolution = (result as AppSuccess<ProductCodeResolution>).value;
        expect(resolution.status, ProductCodeResolutionStatus.notFound);
        expect(searchRepository.offlineCallCount, 0);
        expect(searchRepository.remoteCallCount, 0);
      },
    );

    test(
      'tries the offline index before the remote one, and skips remote when offline already matched',
      () async {
        final product = buildTestProduct(id: 'product-1', reference: 'REF-1');
        productRepository.byId['product-1'] = product;
        variantRepository.variants.add(
          _buildVariant(
            id: 'variant-1',
            productId: 'product-1',
            sku: 'CAM-P-AZ',
          ),
        );
        searchRepository.byRoutedSource[ProductSearchSource.offline] = [
          product,
        ];

        await repository.resolveCode(organizationId: 'org-1', rawCode: 'REF-1');

        expect(searchRepository.offlineCallCount, 1);
        expect(searchRepository.remoteCallCount, 0);
      },
    );

    test(
      'falls back to the remote index when the offline index has no match',
      () async {
        final product = buildTestProduct(id: 'product-1', reference: 'REF-1');
        productRepository.byId['product-1'] = product;
        variantRepository.variants.add(
          _buildVariant(
            id: 'variant-1',
            productId: 'product-1',
            sku: 'CAM-P-AZ',
          ),
        );
        searchRepository.byRoutedSource[ProductSearchSource.remote] = [product];

        final result = await repository.resolveCode(
          organizationId: 'org-1',
          rawCode: 'REF-1',
        );

        expect(searchRepository.offlineCallCount, 1);
        expect(searchRepository.remoteCallCount, 1);
        final resolution = (result as AppSuccess<ProductCodeResolution>).value;
        expect(resolution.status, ProductCodeResolutionStatus.singleMatch);
      },
    );

    test('resolves through a registered alternate code', () async {
      final product = buildTestProduct(id: 'product-1');
      productRepository.byId['product-1'] = product;
      final variant = _buildVariant(
        id: 'variant-1',
        productId: 'product-1',
        sku: 'CAM-P-AZ',
      );
      variantRepository.variants.add(variant);
      alternateCodeDataSource.byCode['OLD-EAN-123'] = AlternateProductCode(
        organizationId: 'org-1',
        code: 'OLD-EAN-123',
        productId: 'product-1',
        variantId: 'variant-1',
        registeredAt: DateTime.utc(2026, 1, 1),
        registeredBy: 'user-1',
      );

      final result = await repository.resolveCode(
        organizationId: 'org-1',
        rawCode: 'old-ean-123',
      );

      final resolution = (result as AppSuccess<ProductCodeResolution>).value;
      expect(resolution.status, ProductCodeResolutionStatus.singleMatch);
      expect(resolution.singleMatchOrNull!.variant!.id, 'variant-1');
    });

    test(
      'resolves a well-formed internal QR for the caller\'s own org',
      () async {
        final product = buildTestProduct(id: 'product-1');
        productRepository.byId['product-1'] = product;
        variantRepository.variants.add(
          _buildVariant(
            id: 'variant-1',
            productId: 'product-1',
            sku: 'CAM-P-AZ',
          ),
        );

        final result = await repository.resolveCode(
          organizationId: 'org-1',
          rawCode: 'vestipro:v1:variant:org-1:variant-1',
        );

        final resolution = (result as AppSuccess<ProductCodeResolution>).value;
        expect(resolution.status, ProductCodeResolutionStatus.singleMatch);
        expect(resolution.singleMatchOrNull!.variant!.id, 'variant-1');
      },
    );

    test(
      'never resolves an internal QR minted for a different organization',
      () async {
        final product = buildTestProduct(id: 'product-1');
        productRepository.byId['product-1'] = product;
        variantRepository.variants.add(
          _buildVariant(
            id: 'variant-1',
            productId: 'product-1',
            sku: 'CAM-P-AZ',
            organizationId: 'org-2',
          ),
        );

        final result = await repository.resolveCode(
          organizationId: 'org-1',
          rawCode: 'vestipro:v1:variant:org-2:variant-1',
        );

        final resolution = (result as AppSuccess<ProductCodeResolution>).value;
        expect(resolution.status, ProductCodeResolutionStatus.notFound);
      },
    );

    test(
      'registerAlternateCode persists a normalized code the next resolveCode call finds',
      () async {
        final registerResult = await repository.registerAlternateCode(
          organizationId: 'org-1',
          code: 'old-ean-999',
          productId: 'product-1',
          variantId: 'variant-1',
          registeredBy: 'user-1',
        );
        expect(registerResult, isA<AppSuccess<AlternateProductCode>>());

        final product = buildTestProduct(id: 'product-1');
        productRepository.byId['product-1'] = product;
        variantRepository.variants.add(
          _buildVariant(
            id: 'variant-1',
            productId: 'product-1',
            sku: 'CAM-P-AZ',
          ),
        );

        final result = await repository.resolveCode(
          organizationId: 'org-1',
          rawCode: 'OLD-EAN-999',
        );
        final resolution = (result as AppSuccess<ProductCodeResolution>).value;
        expect(resolution.status, ProductCodeResolutionStatus.singleMatch);
      },
    );
  });
}
