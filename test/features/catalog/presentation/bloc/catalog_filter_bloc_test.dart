import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/auth/auth.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog/catalog.dart';
import 'package:vestipro/features/products/products.dart';

class _MockSessionService extends Mock implements SessionService {}

void main() {
  group('CatalogFilterBloc', () {
    late FakeAnalyticsService analyticsService;
    late _MockSessionService sessionService;
    late _FakeCatalogPreferencesRepository preferencesRepository;

    const signedInUser = SessionUser(uid: 'user-1', emailVerified: true);

    setUp(() {
      analyticsService = FakeAnalyticsService();
      sessionService = _MockSessionService();
      when(() => sessionService.currentUser).thenReturn(signedInUser);
      preferencesRepository = _FakeCatalogPreferencesRepository();
    });

    CatalogFilterBloc buildBloc({
      required _ScriptedProductRepository productRepository,
      VariantAvailabilityRepository? availabilityRepository,
      CatalogPreferencesRepository? preferences,
    }) {
      return CatalogFilterBloc(
        listCatalogProducts: ListCatalogProductsUseCase(productRepository),
        getVariantAvailability: GetVariantAvailabilityUseCase(
          availabilityRepository ?? const _FakeVariantAvailabilityRepository(),
        ),
        listCollections: ListCollectionsUseCase(
          const _EmptyCollectionRepository(),
        ),
        listSeasons: ListSeasonsUseCase(const _EmptySeasonRepository()),
        listCategories: ListCategoriesUseCase(const _EmptyCategoryRepository()),
        listProductColors: ListProductColorsUseCase(
          const _EmptyProductColorRepository(),
        ),
        listSizeGridTemplates: ListSizeGridTemplatesUseCase(
          const _EmptySizeGridTemplateRepository(),
        ),
        loadCatalogPreferences: LoadCatalogPreferencesUseCase(
          preferences ?? preferencesRepository,
        ),
        saveCatalogPreferences: SaveCatalogPreferencesUseCase(
          preferences ?? preferencesRepository,
        ),
        analyticsService: analyticsService,
        sessionService: sessionService,
      );
    }

    blocTest<CatalogFilterBloc, CatalogFilterState>(
      'starts with no persisted preference: grid mode, empty filter',
      build: () => buildBloc(
        productRepository: _ScriptedProductRepository(
          <String?, AppResult<ProductCatalogPage>>{
            null: AppSuccess<ProductCatalogPage>(
              ProductCatalogPage(
                products: <Product>[_product(id: 'product-1')],
                hasMore: false,
              ),
            ),
          },
        ),
      ),
      act: (bloc) =>
          bloc.add(const CatalogFilterStarted(organizationId: 'org-1')),
      expect: () => <Object>[
        isA<CatalogFilterState>().having(
          (s) => s.status,
          'status',
          CatalogFilterLoadStatus.loading,
        ),
        isA<CatalogFilterState>()
            .having((s) => s.status, 'status', CatalogFilterLoadStatus.success)
            .having((s) => s.viewMode, 'viewMode', CatalogViewMode.grid)
            .having((s) => s.filter, 'filter', CatalogFilter.empty),
      ],
      verify: (_) {
        expect(preferencesRepository.savedPreferences, isNotEmpty);
      },
    );

    blocTest<CatalogFilterBloc, CatalogFilterState>(
      'restores the last persisted view mode/filter when none is given by '
      'the caller (e.g. no deep link)',
      build: () {
        preferencesRepository.stored = const CatalogPreferences(
          viewMode: CatalogViewMode.list,
          filter: CatalogFilter(brand: 'Malwee'),
        );
        return buildBloc(
          productRepository: _ScriptedProductRepository(
            <String?, AppResult<ProductCatalogPage>>{
              null: const AppSuccess<ProductCatalogPage>(
                ProductCatalogPage(products: <Product>[], hasMore: false),
              ),
            },
          ),
        );
      },
      act: (bloc) =>
          bloc.add(const CatalogFilterStarted(organizationId: 'org-1')),
      expect: () => <Object>[
        isA<CatalogFilterState>(),
        isA<CatalogFilterState>()
            .having((s) => s.viewMode, 'viewMode', CatalogViewMode.list)
            .having(
              (s) => s.filter,
              'filter',
              const CatalogFilter(brand: 'Malwee'),
            ),
      ],
    );

    blocTest<CatalogFilterBloc, CatalogFilterState>(
      'a deep link initialViewMode/initialFilter wins over a persisted '
      'preference',
      build: () {
        preferencesRepository.stored = const CatalogPreferences(
          viewMode: CatalogViewMode.list,
          filter: CatalogFilter(brand: 'Persisted'),
        );
        return buildBloc(
          productRepository: _ScriptedProductRepository(
            <String?, AppResult<ProductCatalogPage>>{
              null: const AppSuccess<ProductCatalogPage>(
                ProductCatalogPage(products: <Product>[], hasMore: false),
              ),
            },
          ),
        );
      },
      act: (bloc) => bloc.add(
        const CatalogFilterStarted(
          organizationId: 'org-1',
          initialViewMode: CatalogViewMode.grid,
          initialFilter: CatalogFilter(brand: 'FromLink'),
        ),
      ),
      expect: () => <Object>[
        isA<CatalogFilterState>(),
        isA<CatalogFilterState>().having(
          (s) => s.filter,
          'filter',
          const CatalogFilter(brand: 'FromLink'),
        ),
      ],
    );

    blocTest<CatalogFilterBloc, CatalogFilterState>(
      'applies a single filter dimension and reloads from the first page',
      build: () => buildBloc(
        productRepository: _ScriptedProductRepository(
          <String?, AppResult<ProductCatalogPage>>{
            null: AppSuccess<ProductCatalogPage>(
              ProductCatalogPage(
                products: <Product>[_product(id: 'product-1')],
                hasMore: false,
              ),
            ),
          },
        ),
      ),
      act: (bloc) async {
        bloc.add(const CatalogFilterStarted(organizationId: 'org-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const CatalogFilterApplied(CatalogFilter(collectionId: 'col-1')),
        );
      },
      skip: 2,
      expect: () => <Object>[
        isA<CatalogFilterState>().having(
          (s) => s.status,
          'status',
          CatalogFilterLoadStatus.loading,
        ),
        isA<CatalogFilterState>()
            .having(
              (s) => s.filter,
              'filter',
              const CatalogFilter(collectionId: 'col-1'),
            )
            .having((s) => s.status, 'status', CatalogFilterLoadStatus.success),
      ],
      verify: (_) {
        expect(
          analyticsService.loggedEvents.map((e) => e.name),
          contains(AnalyticsEvents.catalogFiltered),
        );
      },
    );

    blocTest<CatalogFilterBloc, CatalogFilterState>(
      'combines multiple filter dimensions into a single active filter',
      build: () => buildBloc(
        productRepository:
            _ScriptedProductRepository(<String?, AppResult<ProductCatalogPage>>{
              null: const AppSuccess<ProductCatalogPage>(
                ProductCatalogPage(products: <Product>[], hasMore: false),
              ),
            }),
      ),
      act: (bloc) async {
        bloc.add(const CatalogFilterStarted(organizationId: 'org-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const CatalogFilterApplied(
            CatalogFilter(
              collectionId: 'col-1',
              brand: 'Malwee',
              colorIds: <String>{'red'},
            ),
          ),
        );
      },
      skip: 2,
      expect: () => <Object>[
        isA<CatalogFilterState>(),
        isA<CatalogFilterState>().having(
          (s) => s.filter.activeCount,
          'activeCount',
          3,
        ),
      ],
    );

    blocTest<CatalogFilterBloc, CatalogFilterState>(
      'removes a single filter chip without clearing the others',
      build: () => buildBloc(
        productRepository:
            _ScriptedProductRepository(<String?, AppResult<ProductCatalogPage>>{
              null: const AppSuccess<ProductCatalogPage>(
                ProductCatalogPage(products: <Product>[], hasMore: false),
              ),
            }),
      ),
      act: (bloc) async {
        bloc.add(
          const CatalogFilterStarted(
            organizationId: 'org-1',
            initialFilter: CatalogFilter(
              collectionId: 'col-1',
              colorIds: <String>{'red', 'blue'},
            ),
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const CatalogFilterChipRemoved(CatalogFilterKey.color, value: 'red'),
        );
      },
      skip: 2,
      expect: () => <Object>[
        isA<CatalogFilterState>(),
        isA<CatalogFilterState>().having(
          (s) => s.filter,
          'filter',
          const CatalogFilter(
            collectionId: 'col-1',
            colorIds: <String>{'blue'},
          ),
        ),
      ],
    );

    blocTest<CatalogFilterBloc, CatalogFilterState>(
      'a filter combination with no match surfaces the empty state, never '
      'a broken/blank grid',
      build: () => buildBloc(
        productRepository:
            _ScriptedProductRepository(<String?, AppResult<ProductCatalogPage>>{
              null: const AppSuccess<ProductCatalogPage>(
                ProductCatalogPage(products: <Product>[], hasMore: false),
              ),
            }),
      ),
      act: (bloc) => bloc.add(
        const CatalogFilterStarted(
          organizationId: 'org-1',
          initialFilter: CatalogFilter(brand: 'Inexistente'),
        ),
      ),
      expect: () => <Object>[
        isA<CatalogFilterState>(),
        isA<CatalogFilterState>()
            .having((s) => s.status, 'status', CatalogFilterLoadStatus.empty)
            .having((s) => s.products, 'products', isEmpty),
      ],
    );

    blocTest<CatalogFilterBloc, CatalogFilterState>(
      'switching view mode keeps the active filter (spec: "troca de modo de '
      'visualização mantendo filtro ativo")',
      build: () => buildBloc(
        productRepository:
            _ScriptedProductRepository(<String?, AppResult<ProductCatalogPage>>{
              null: const AppSuccess<ProductCatalogPage>(
                ProductCatalogPage(products: <Product>[], hasMore: false),
              ),
            }),
      ),
      act: (bloc) async {
        bloc.add(
          const CatalogFilterStarted(
            organizationId: 'org-1',
            initialFilter: CatalogFilter(brand: 'Malwee'),
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const CatalogFilterViewModeChanged(CatalogViewMode.list));
      },
      skip: 2,
      expect: () => <Object>[
        isA<CatalogFilterState>(),
        isA<CatalogFilterState>()
            .having((s) => s.viewMode, 'viewMode', CatalogViewMode.list)
            .having(
              (s) => s.filter,
              'filter',
              const CatalogFilter(brand: 'Malwee'),
            ),
      ],
    );

    blocTest<CatalogFilterBloc, CatalogFilterState>(
      'bestSellers/recommended surface "unavailable" instead of a '
      'fabricated ranking (no sales/recommendation data source exists)',
      build: () => buildBloc(
        productRepository:
            _ScriptedProductRepository(<String?, AppResult<ProductCatalogPage>>{
              null: const AppSuccess<ProductCatalogPage>(
                ProductCatalogPage(products: <Product>[], hasMore: false),
              ),
            }),
      ),
      act: (bloc) async {
        bloc.add(const CatalogFilterStarted(organizationId: 'org-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const CatalogFilterViewModeChanged(CatalogViewMode.bestSellers),
        );
      },
      skip: 2,
      expect: () => <Object>[
        isA<CatalogFilterState>().having(
          (s) => s.status,
          'status',
          CatalogFilterLoadStatus.unavailable,
        ),
      ],
    );

    blocTest<CatalogFilterBloc, CatalogFilterState>(
      'readyStock narrows the fetched page to only ready-stock availability',
      build: () => buildBloc(
        productRepository: _ScriptedProductRepository(
          <String?, AppResult<ProductCatalogPage>>{
            null: AppSuccess<ProductCatalogPage>(
              ProductCatalogPage(
                products: <Product>[
                  _product(id: 'product-ready'),
                  _product(id: 'product-future'),
                ],
                hasMore: false,
              ),
            ),
          },
        ),
        availabilityRepository:
            _FakeVariantAvailabilityRepository(<VariantAvailability>[
              const VariantAvailability(
                variantId: 'v1',
                productId: 'product-ready',
                status: VariantAvailabilityStatus.readyStock,
              ),
              const VariantAvailability(
                variantId: 'v2',
                productId: 'product-future',
                status: VariantAvailabilityStatus.futureStock,
              ),
            ]),
      ),
      act: (bloc) => bloc.add(
        const CatalogFilterStarted(
          organizationId: 'org-1',
          initialViewMode: CatalogViewMode.readyStock,
        ),
      ),
      expect: () => <Object>[
        isA<CatalogFilterState>(),
        isA<CatalogFilterState>().having(
          (s) => s.products.map((p) => p.id).toList(),
          'products',
          <String>['product-ready'],
        ),
      ],
    );

    blocTest<CatalogFilterBloc, CatalogFilterState>(
      'appends the next page without losing the products already shown',
      build: () => buildBloc(
        productRepository: _ScriptedProductRepository(
          <String?, AppResult<ProductCatalogPage>>{
            null: AppSuccess<ProductCatalogPage>(
              ProductCatalogPage(
                products: <Product>[_product(id: 'product-1')],
                hasMore: true,
                nextCursor: 'product-1',
              ),
            ),
            'product-1': AppSuccess<ProductCatalogPage>(
              ProductCatalogPage(
                products: <Product>[_product(id: 'product-2')],
                hasMore: false,
              ),
            ),
          },
        ),
      ),
      act: (bloc) async {
        bloc.add(const CatalogFilterStarted(organizationId: 'org-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const CatalogFilterNextPageRequested());
      },
      skip: 2,
      expect: () => <Object>[
        isA<CatalogFilterState>(),
        isA<CatalogFilterState>().having(
          (s) => s.products.map((p) => p.id).toList(),
          'products',
          <String>['product-1', 'product-2'],
        ),
      ],
    );

    blocTest<CatalogFilterBloc, CatalogFilterState>(
      'logs product_viewed with a catalog_filter source on product open',
      build: () => buildBloc(
        productRepository:
            _ScriptedProductRepository(<String?, AppResult<ProductCatalogPage>>{
              null: const AppSuccess<ProductCatalogPage>(
                ProductCatalogPage(products: <Product>[], hasMore: false),
              ),
            }),
      ),
      act: (bloc) => bloc.add(CatalogFilterProductOpened(_product(id: 'p1'))),
      verify: (_) {
        final logged = analyticsService.loggedEvents.firstWhere(
          (event) => event.name == AnalyticsEvents.productViewed,
        );
        expect(logged.parameters?['product_id'], 'p1');
        expect(logged.parameters?['source'], 'catalog_filter_grid');
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

final class _ScriptedProductRepository implements ProductRepository {
  _ScriptedProductRepository(this._pages);

  final Map<String?, AppResult<ProductCatalogPage>> _pages;
  final List<CatalogFilter?> receivedFilters = <CatalogFilter?>[];

  @override
  Future<AppResult<ProductCatalogPage>> listCatalog({
    required String organizationId,
    String? companyId,
    String? cursor,
    int limit = 20,
    CatalogFilter? filter,
  }) async {
    receivedFilters.add(filter);
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

final class _FakeVariantAvailabilityRepository
    implements VariantAvailabilityRepository {
  const _FakeVariantAvailabilityRepository([this._availabilities = const []]);

  final List<VariantAvailability> _availabilities;

  @override
  Future<AppResult<List<VariantAvailability>>> listByProductIds({
    required String organizationId,
    required Iterable<String> productIds,
  }) async {
    return AppSuccess<List<VariantAvailability>>(_availabilities);
  }

  @override
  Future<AppResult<List<VariantAvailability>>> listByVariantIds({
    required String organizationId,
    required Iterable<String> variantIds,
  }) async {
    return AppSuccess<List<VariantAvailability>>(_availabilities);
  }
}

final class _EmptyCollectionRepository implements CollectionRepository {
  const _EmptyCollectionRepository();

  @override
  Future<AppResult<List<Collection>>> listByOrganization(
    String organizationId,
  ) async => const AppSuccess<List<Collection>>(<Collection>[]);

  @override
  Future<AppResult<Collection>> create({required Collection collection}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<Collection>> update({required Collection collection}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<Collection>> getById({
    required String organizationId,
    required String id,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<Collection>> close({
    required String organizationId,
    required String id,
    required String updatedBy,
  }) => throw UnimplementedError();
}

final class _EmptySeasonRepository implements SeasonRepository {
  const _EmptySeasonRepository();

  @override
  Future<AppResult<List<Season>>> listByOrganization(
    String organizationId,
  ) async => const AppSuccess<List<Season>>(<Season>[]);

  @override
  Future<AppResult<Season>> create({required Season season}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<Season>> update({required Season season}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<Season>> getById({
    required String organizationId,
    required String id,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<bool>> existsByName({
    required String organizationId,
    required String name,
    String? excludingSeasonId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<bool>> hasCollections({
    required String organizationId,
    required String seasonId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<Season>> delete({
    required String organizationId,
    required String id,
    required String deletedBy,
  }) => throw UnimplementedError();
}

final class _EmptyCategoryRepository implements CategoryRepository {
  const _EmptyCategoryRepository();

  @override
  Future<AppResult<List<Category>>> listByOrganization(
    String organizationId,
  ) async => const AppSuccess<List<Category>>(<Category>[]);

  @override
  Future<AppResult<Category>> create({required Category category}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<Category>> update({required Category category}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<Category>> getById({
    required String organizationId,
    required String id,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<bool>> existsByName({
    required String organizationId,
    required String name,
    String? parentId,
    String? excludingCategoryId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<bool>> hasProducts({
    required String organizationId,
    required String categoryId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<Category>> delete({
    required String organizationId,
    required String id,
    required String deletedBy,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<List<Category>>> reorder({
    required String organizationId,
    required String? parentId,
    required List<String> orderedIds,
    required String updatedBy,
  }) => throw UnimplementedError();
}

final class _EmptyProductColorRepository implements ProductColorRepository {
  const _EmptyProductColorRepository();

  @override
  Future<AppResult<List<ProductColor>>> listByOrganization(
    String organizationId,
  ) async => const AppSuccess<List<ProductColor>>(<ProductColor>[]);

  @override
  Future<AppResult<ProductColor>> create({required ProductColor color}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<ProductColor>> update({required ProductColor color}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<ProductColor>> getById({
    required String organizationId,
    required String id,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<bool>> eanExists({
    required String organizationId,
    required Ean ean,
    String? excludingColorId,
  }) => throw UnimplementedError();
}

final class _EmptySizeGridTemplateRepository
    implements SizeGridTemplateRepository {
  const _EmptySizeGridTemplateRepository();

  @override
  Future<AppResult<List<SizeGridTemplate>>> listByOrganization(
    String organizationId,
  ) async => const AppSuccess<List<SizeGridTemplate>>(<SizeGridTemplate>[]);

  @override
  Future<AppResult<SizeGridTemplate>> create({
    required SizeGridTemplate template,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<SizeGridTemplate>> update({
    required SizeGridTemplate template,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<SizeGridTemplate>> getById({
    required String organizationId,
    required String id,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<bool>> nameExists({
    required String organizationId,
    required String name,
    String? excludingTemplateId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<bool>> hasPublishedProductsUsingTemplate({
    required String organizationId,
    required String templateId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<bool>> sizeHasGeneratedVariants({
    required String organizationId,
    required String templateId,
    required String sizeId,
  }) => throw UnimplementedError();
}

final class _FakeCatalogPreferencesRepository
    implements CatalogPreferencesRepository {
  CatalogPreferences? stored;
  final List<CatalogPreferences> savedPreferences = <CatalogPreferences>[];

  @override
  Future<AppResult<CatalogPreferences?>> load({
    required String organizationId,
    required String userId,
  }) async => AppSuccess<CatalogPreferences?>(stored);

  @override
  Future<AppResult<void>> save({
    required String organizationId,
    required String userId,
    required CatalogPreferences preferences,
  }) async {
    savedPreferences.add(preferences);
    stored = preferences;
    return const AppSuccess<void>(null);
  }
}
