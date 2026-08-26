import '../../../../core/utils/utils.dart';
import '../entities/catalog_campaign.dart';

/// Contract for reading and writing `CatalogCampaign` documents scoped
/// under one Organization (TASK-076 read-only, TASK-080 adds the write
/// side) — the same "read contract first, write contract added by the task
/// that needs it" precedent `CollectionRepository`/`ProductRepository`
/// already set across TASK-064 through TASK-066.
abstract interface class CatalogCampaignRepository {
  /// Lists every non-deleted `CatalogCampaign` of [organizationId]. Callers
  /// (e.g. `GetCatalogCampaignsSectionUseCase`) are responsible for applying
  /// `CatalogCampaign.isVisibleAt` — this contract never filters by
  /// active/visibility window itself, so an admin screen can still list
  /// inactive/scheduled/expired campaigns.
  Future<AppResult<List<CatalogCampaign>>> listByOrganization(
    String organizationId,
  );

  Future<AppResult<CatalogCampaign>> getById({
    required String organizationId,
    required String id,
  });

  Future<AppResult<CatalogCampaign>> create({
    required CatalogCampaign campaign,
  });

  Future<AppResult<CatalogCampaign>> update({
    required CatalogCampaign campaign,
  });

  /// Soft-deletes (`deletedAt`) a campaign — never a hard delete, mirroring
  /// `Product`/`Collection`. A soft-deleted campaign never appears again in
  /// [listByOrganization] nor as "em campanha" anywhere in the catalog.
  Future<AppResult<CatalogCampaign>> delete({
    required String organizationId,
    required String id,
    required String updatedBy,
  });
}
