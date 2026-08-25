import '../../../../core/utils/utils.dart';
import '../entities/catalog_campaign.dart';

/// Read contract for `CatalogCampaign` (TASK-076), consumed by
/// `GetCatalogCampaignsSectionUseCase` for the catalog home's "campanhas em
/// destaque" section. Admin CRUD (create/update/deactivate a campaign)
/// belongs to TASK-080 (lookbook e campanhas) — the same "read contract
/// first, write contract added by the task that needs it" precedent
/// `CollectionRepository`/`ProductRepository` already set across TASK-064
/// through TASK-066.
abstract interface class CatalogCampaignRepository {
  /// Lists every non-deleted `CatalogCampaign` of [organizationId]. Callers
  /// (e.g. `GetCatalogCampaignsSectionUseCase`) are responsible for applying
  /// `CatalogCampaign.isVisibleAt` — this contract never filters by
  /// active/visibility window itself, so an admin screen can still list
  /// inactive/scheduled campaigns.
  Future<AppResult<List<CatalogCampaign>>> listByOrganization(
    String organizationId,
  );
}
