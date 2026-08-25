import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog/catalog.dart';
import 'package:vestipro/features/products/products.dart';

/// Shared fakes for `CatalogHomeBloc` tests (bloc-level and widget-level) —
/// avoids redefining the same repository fakes in every test file that
/// needs to build a real `CatalogHomeBloc` (TASK-076).
class FakeCatalogHomeConfigRepository implements CatalogHomeConfigRepository {
  FakeCatalogHomeConfigRepository(this.result);

  AppResult<List<CatalogHomeSectionConfig>> result;

  @override
  Future<AppResult<List<CatalogHomeSectionConfig>>> getSectionConfigs(
    String organizationId,
  ) async => result;
}

class FakeCollectionRepository implements CollectionRepository {
  FakeCollectionRepository(this.result);

  AppResult<List<Collection>> result;

  @override
  Future<AppResult<Collection>> create({required Collection collection}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<Collection>> update({required Collection collection}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<List<Collection>>> listByOrganization(
    String organizationId,
  ) async => result;

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

class FakeCatalogHomeProductRepository implements ProductRepository {
  FakeCatalogHomeProductRepository(this.result);

  AppResult<List<Product>> result;

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
  }) async => result;

  @override
  Future<AppResult<ProductCatalogPage>> listCatalog({
    required String organizationId,
    String? companyId,
    String? cursor,
    int limit = 20,
  }) async {
    return result.fold(
      onSuccess: (products) => AppSuccess<ProductCatalogPage>(
        ProductCatalogPage(products: products, hasMore: false),
      ),
      onFailure: (failure) => AppFailure<ProductCatalogPage>(failure),
    );
  }
}

class FakeCatalogCampaignRepository implements CatalogCampaignRepository {
  FakeCatalogCampaignRepository(this.result);

  AppResult<List<CatalogCampaign>> result;

  @override
  Future<AppResult<List<CatalogCampaign>>> listByOrganization(
    String organizationId,
  ) async => result;
}

class FakeCatalogHomeCacheRepository implements CatalogHomeCacheRepository {
  FakeCatalogHomeCacheRepository({
    this.loadResult = const AppSuccess<CatalogHomeSnapshot?>(null),
  });

  AppResult<CatalogHomeSnapshot?> loadResult;
  final List<CatalogHomeSnapshot> saved = <CatalogHomeSnapshot>[];

  @override
  Future<AppResult<CatalogHomeSnapshot?>> load({
    required String organizationId,
    String? companyId,
  }) async => loadResult;

  @override
  Future<AppResult<void>> save({
    required String organizationId,
    String? companyId,
    required CatalogHomeSnapshot snapshot,
  }) async {
    saved.add(snapshot);
    return const AppSuccess<void>(null);
  }
}

Collection buildTestCollection({required String id}) {
  final now = DateTime.utc(2026, 1, 1);
  return Collection(
    id: id,
    organizationId: 'org-1',
    name: 'Verão 2026',
    year: 2026,
    startDate: now,
    status: CollectionStatus.active,
    version: 1,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
  );
}

Product buildTestCatalogHomeProduct({required String id}) {
  final now = DateTime.utc(2026, 1, 1);
  return Product(
    id: id,
    organizationId: 'org-1',
    sku: Sku.parse('SKU-$id'),
    reference: 'REF-$id',
    name: 'Produto $id',
    status: ProductStatus.active,
    launchDate: now,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: ProductSyncStatus.synced,
  );
}

CatalogCampaign buildTestCampaign({required String id}) {
  final now = DateTime.utc(2026, 1, 1);
  return CatalogCampaign(
    id: id,
    organizationId: 'org-1',
    title: 'Campanha $id',
    order: 0,
    active: true,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
  );
}

/// Builds a real `CatalogHomeBloc` wired to the fakes above — every test
/// that needs a working bloc (bloc-level or widget-level) reuses this
/// instead of hand-wiring the 6 use cases again.
CatalogHomeBloc buildTestCatalogHomeBloc({
  required AppResult<List<Collection>> collectionsResult,
  required AppResult<List<Product>> productsResult,
  required AppResult<List<CatalogCampaign>> campaignsResult,
  CatalogHomeSnapshot? cachedSnapshot,
  required AnalyticsService analyticsService,
}) {
  return CatalogHomeBloc(
    getCatalogHomeConfig: GetCatalogHomeConfigUseCase(
      FakeCatalogHomeConfigRepository(
        AppSuccess<List<CatalogHomeSectionConfig>>(
          defaultCatalogHomeSectionConfigs,
        ),
      ),
    ),
    getFeaturedCollectionsSection: GetFeaturedCollectionsSectionUseCase(
      FakeCollectionRepository(collectionsResult),
    ),
    getNewArrivalsSection: GetNewArrivalsSectionUseCase(
      FakeCatalogHomeProductRepository(productsResult),
    ),
    getCatalogCampaignsSection: GetCatalogCampaignsSectionUseCase(
      FakeCatalogCampaignRepository(campaignsResult),
    ),
    loadCatalogHomeCache: LoadCatalogHomeCacheUseCase(
      FakeCatalogHomeCacheRepository(
        loadResult: AppSuccess<CatalogHomeSnapshot?>(cachedSnapshot),
      ),
    ),
    saveCatalogHomeCache: SaveCatalogHomeCacheUseCase(
      FakeCatalogHomeCacheRepository(),
    ),
    analyticsService: analyticsService,
  );
}
