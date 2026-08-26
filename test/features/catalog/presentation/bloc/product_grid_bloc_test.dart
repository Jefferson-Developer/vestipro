import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog/catalog.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('ProductGridBloc', () {
    late FakeAnalyticsService analyticsService;

    setUp(() {
      analyticsService = FakeAnalyticsService();
    });

    ProductGridBloc buildBloc(
      _ScriptedProductRepository repository, {
      VariantAvailabilityRepository? availabilityRepository,
    }) {
      return ProductGridBloc(
        listCatalogProducts: ListCatalogProductsUseCase(repository),
        getVariantAvailability: GetVariantAvailabilityUseCase(
          availabilityRepository ?? const _FakeVariantAvailabilityRepository(),
        ),
        analyticsService: analyticsService,
      );
    }

    blocTest<ProductGridBloc, ProductGridState>(
      'loads the first page from the local-first repository (works without '
      'any remote/online dependency)',
      build: () => buildBloc(
        _ScriptedProductRepository(<String?, AppResult<ProductCatalogPage>>{
          null: AppSuccess<ProductCatalogPage>(
            ProductCatalogPage(
              products: <Product>[_buildProduct(id: 'product-1')],
              hasMore: true,
              nextCursor: 'product-1',
            ),
          ),
        }),
      ),
      act: (bloc) =>
          bloc.add(const ProductGridStarted(organizationId: 'org-1')),
      expect: () => <Object>[
        isA<ProductGridState>().having(
          (state) => state.status,
          'status',
          ProductGridLoadStatus.loading,
        ),
        isA<ProductGridState>()
            .having(
              (state) => state.status,
              'status',
              ProductGridLoadStatus.success,
            )
            .having(
              (state) => state.products.map((p) => p.id).toList(),
              'products',
              <String>['product-1'],
            )
            .having((state) => state.hasMore, 'hasMore', isTrue)
            .having((state) => state.cursor, 'cursor', 'product-1'),
        isA<ProductGridState>().having(
          (state) => state.hasLoggedViewed,
          'hasLoggedViewed',
          isTrue,
        ),
      ],
      verify: (_) {
        expect(
          analyticsService.loggedEvents.map((e) => e.name),
          contains(AnalyticsEvents.catalogGridViewed),
        );
      },
    );

    blocTest<ProductGridBloc, ProductGridState>(
      'appends the next page without losing the products already shown',
      build: () => buildBloc(
        _ScriptedProductRepository(<String?, AppResult<ProductCatalogPage>>{
          null: AppSuccess<ProductCatalogPage>(
            ProductCatalogPage(
              products: <Product>[_buildProduct(id: 'product-1')],
              hasMore: true,
              nextCursor: 'product-1',
            ),
          ),
          'product-1': AppSuccess<ProductCatalogPage>(
            ProductCatalogPage(
              products: <Product>[_buildProduct(id: 'product-2')],
              hasMore: false,
            ),
          ),
        }),
      ),
      act: (bloc) async {
        bloc.add(const ProductGridStarted(organizationId: 'org-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ProductGridNextPageRequested());
      },
      skip: 3,
      expect: () => <Object>[
        isA<ProductGridState>().having(
          (state) => state.isLoadingMore,
          'isLoadingMore',
          isTrue,
        ),
        isA<ProductGridState>()
            .having(
              (state) => state.products.map((p) => p.id).toList(),
              'products',
              <String>['product-1', 'product-2'],
            )
            .having((state) => state.hasMore, 'hasMore', isFalse)
            .having((state) => state.isLoadingMore, 'isLoadingMore', isFalse),
      ],
    );

    late _ScriptedProductRepository duplicateRequestRepository;
    blocTest<ProductGridBloc, ProductGridState>(
      'drops a duplicated/concurrent next-page request instead of fetching '
      'the same page twice',
      build: () {
        duplicateRequestRepository = _ScriptedProductRepository(
          <String?, AppResult<ProductCatalogPage>>{
            null: AppSuccess<ProductCatalogPage>(
              ProductCatalogPage(
                products: <Product>[_buildProduct(id: 'product-1')],
                hasMore: true,
                nextCursor: 'product-1',
              ),
            ),
            'product-1': AppSuccess<ProductCatalogPage>(
              ProductCatalogPage(
                products: <Product>[_buildProduct(id: 'product-2')],
                hasMore: false,
              ),
            ),
          },
          delay: const Duration(milliseconds: 20),
        );
        return buildBloc(duplicateRequestRepository);
      },
      act: (bloc) async {
        bloc.add(const ProductGridStarted(organizationId: 'org-1'));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        bloc.add(const ProductGridNextPageRequested());
        bloc.add(const ProductGridNextPageRequested());
      },
      wait: const Duration(milliseconds: 60),
      verify: (bloc) {
        // Only one request for the "product-1" cursor reached the
        // repository — the second, concurrent `ProductGridNextPageRequested`
        // was dropped instead of re-fetching the same page.
        expect(
          duplicateRequestRepository.requestedCursors.where(
            (cursor) => cursor == 'product-1',
          ),
          hasLength(1),
        );
        expect(bloc.state.products.map((p) => p.id).toList(), <String>[
          'product-1',
          'product-2',
        ]);
      },
    );

    blocTest<ProductGridBloc, ProductGridState>(
      'keeps the products already shown when a later page fails',
      build: () => buildBloc(
        _ScriptedProductRepository(<String?, AppResult<ProductCatalogPage>>{
          null: AppSuccess<ProductCatalogPage>(
            ProductCatalogPage(
              products: <Product>[_buildProduct(id: 'product-1')],
              hasMore: true,
              nextCursor: 'product-1',
            ),
          ),
          'product-1': const AppFailure<ProductCatalogPage>(
            UnexpectedFailure(
              'boom',
              code: 'product_local_list_catalog_unexpected',
            ),
          ),
        }),
      ),
      act: (bloc) async {
        bloc.add(const ProductGridStarted(organizationId: 'org-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ProductGridNextPageRequested());
      },
      skip: 3,
      expect: () => <Object>[
        isA<ProductGridState>().having(
          (state) => state.isLoadingMore,
          'isLoadingMore',
          isTrue,
        ),
        isA<ProductGridState>()
            .having(
              (state) => state.products.map((p) => p.id).toList(),
              'products',
              <String>['product-1'],
            )
            .having((state) => state.isLoadingMore, 'isLoadingMore', isFalse)
            .having(
              (state) => state.status,
              'status',
              ProductGridLoadStatus.success,
            ),
      ],
    );

    blocTest<ProductGridBloc, ProductGridState>(
      'emits empty when the first page has no products',
      build: () => buildBloc(
        _ScriptedProductRepository(<String?, AppResult<ProductCatalogPage>>{
          null: const AppSuccess<ProductCatalogPage>(
            ProductCatalogPage(products: <Product>[], hasMore: false),
          ),
        }),
      ),
      act: (bloc) =>
          bloc.add(const ProductGridStarted(organizationId: 'org-1')),
      expect: () => <Object>[
        isA<ProductGridState>().having(
          (state) => state.status,
          'status',
          ProductGridLoadStatus.loading,
        ),
        isA<ProductGridState>().having(
          (state) => state.status,
          'status',
          ProductGridLoadStatus.empty,
        ),
      ],
      verify: (_) {
        expect(
          analyticsService.loggedEvents.map((e) => e.name),
          isNot(contains(AnalyticsEvents.catalogGridViewed)),
        );
      },
    );

    blocTest<ProductGridBloc, ProductGridState>(
      'logs product_viewed when a card is opened',
      build: () => buildBloc(
        _ScriptedProductRepository(<String?, AppResult<ProductCatalogPage>>{
          null: AppSuccess<ProductCatalogPage>(
            ProductCatalogPage(
              products: <Product>[_buildProduct(id: 'product-1')],
              hasMore: false,
            ),
          ),
        }),
      ),
      act: (bloc) async {
        bloc.add(const ProductGridStarted(organizationId: 'org-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(ProductGridProductOpened(_buildProduct(id: 'product-1')));
      },
      wait: const Duration(milliseconds: 5),
      verify: (_) {
        final logged = analyticsService.loggedEvents.firstWhere(
          (event) => event.name == AnalyticsEvents.productViewed,
        );
        expect(logged.parameters?['organization_id'], 'org-1');
        expect(logged.parameters?['product_id'], 'product-1');
        expect(logged.parameters?['source'], 'catalog_grid');
      },
    );
  });
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

/// A [ProductRepository] whose `listCatalog` responds with a pre-scripted
/// result per requested cursor, optionally after [delay] — used to make a
/// duplicated/concurrent "carregar mais" request deterministic to test.
final class _ScriptedProductRepository implements ProductRepository {
  _ScriptedProductRepository(this._pages, {this.delay = Duration.zero});

  final Map<String?, AppResult<ProductCatalogPage>> _pages;
  final Duration delay;
  final List<String?> requestedCursors = <String?>[];

  @override
  Future<AppResult<ProductCatalogPage>> listCatalog({
    required String organizationId,
    String? companyId,
    String? cursor,
    int limit = 20,
    CatalogFilter? filter,
  }) async {
    requestedCursors.add(cursor);
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    final result = _pages[cursor];
    if (result == null) {
      throw StateError('No scripted catalog page for cursor "$cursor".');
    }
    return result;
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
