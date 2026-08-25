import '../../../../core/utils/utils.dart';
import '../entities/catalog_home_snapshot.dart';

/// Local stale-while-revalidate cache for the catalog home (TASK-076):
/// persists the last successfully-loaded [CatalogHomeSnapshot] so
/// `CatalogHomeBloc` can paint instantly on the next open and keep showing
/// something useful offline, clearly flagged as potentially outdated (see
/// `CatalogHomeState.isStale`).
///
/// Scoped by [organizationId] and, when the organization splits its catalog
/// per company, [companyId] — never mixes a cached home across tenants or
/// companies.
abstract interface class CatalogHomeCacheRepository {
  Future<AppResult<CatalogHomeSnapshot?>> load({
    required String organizationId,
    String? companyId,
  });

  Future<AppResult<void>> save({
    required String organizationId,
    String? companyId,
    required CatalogHomeSnapshot snapshot,
  });
}
