import '../../../../core/utils/utils.dart';
import '../entities/product.dart';
import '../entities/product_catalog_page.dart';
import '../value_objects/sku.dart';

/// Domain contract for Product persistence, decoupled from Firestore/Drift.
///
/// TASK-064 modeled the entity and the basic read use case with only
/// [getById] as a contract-only repository, no concrete implementation.
/// TASK-065 adds [existsBySku]/[create]/[update] plus a first concrete
/// implementation (`SharedPreferencesProductRepository`), the same
/// local-store-until-outbox-exists precedent `SharedPreferencesCustomerRepository`
/// (TASK-048/049) already set.
abstract interface class ProductRepository {
  /// Whether an active (non soft-deleted) Product with [sku] already exists
  /// in [organizationId]. [excludingProductId] lets an update check
  /// uniqueness against every other product without flagging itself as a
  /// duplicate. SKU uniqueness is scoped by organization, mirroring
  /// `CustomerRepository.existsByDocument`.
  Future<AppResult<bool>> existsBySku({
    required String organizationId,
    required Sku sku,
    String? excludingProductId,
  });

  Future<AppResult<Product>> create({required Product product});

  Future<AppResult<Product>> update({required Product product});

  Future<AppResult<Product>> getById({
    required String organizationId,
    required String id,
  });

  /// Batch-loads every Product of [organizationId] whose id is in [ids]
  /// (TASK-066, `ListProductsByCollectionUseCase`). Silently skips ids that
  /// do not exist or belong to another organization instead of failing the
  /// whole batch — a stale/removed Product reference in a join table should
  /// not block the rest of the list from loading.
  Future<AppResult<List<Product>>> getByIds({
    required String organizationId,
    required List<String> ids,
  });

  /// Lists the most recently launched, currently active (non soft-deleted)
  /// Products of [organizationId] — newest first, ranked by
  /// `Product.launchDate` when set, falling back to `Product.createdAt`
  /// otherwise. Capped at [limit]. Used by the catalog home's "lançamentos"
  /// section (TASK-076, `GetNewArrivalsSectionUseCase`) so the ranking is a
  /// repository/query concern, never a client-side scan by the BLoC.
  ///
  /// [companyId], when provided, restricts the result to Products either
  /// scoped to that company or shared across the whole organization
  /// (`Product.companyId == null`) — mirroring how `Product.companyId`
  /// itself is documented as optional for organizations that share a single
  /// catalog across companies.
  Future<AppResult<List<Product>>> listRecentlyLaunched({
    required String organizationId,
    String? companyId,
    int limit = 12,
  });

  /// Cursor-paginated listing of every active (non soft-deleted) Product of
  /// [organizationId] — newest first, ranked by `Product.createdAt` (ties
  /// broken by `Product.id` for a stable order). This is the query behind
  /// the catalog's full visual grid (TASK-077, `ProductGridBloc`): unlike
  /// [listRecentlyLaunched] (a fixed top-N for the home's "lançamentos"
  /// section), callers keep paging through the whole catalog by feeding the
  /// previous page's `ProductCatalogPage.nextCursor` back in, never loading
  /// every Product into memory at once.
  ///
  /// [cursor] is the previous page's `ProductCatalogPage.nextCursor`; `null`
  /// (or omitted) starts from the first page. A [cursor] that no longer
  /// matches any Product (e.g. it was deleted between page loads) safely
  /// restarts pagination from the first page rather than failing.
  ///
  /// [companyId] restricts the result the same way [listRecentlyLaunched]
  /// does: Products scoped to that company, plus Products shared across the
  /// whole organization (`Product.companyId == null`).
  Future<AppResult<ProductCatalogPage>> listCatalog({
    required String organizationId,
    String? companyId,
    String? cursor,
    int limit = 20,
  });
}
