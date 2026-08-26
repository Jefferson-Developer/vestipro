import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/catalog_campaign.dart';
import '../repositories/catalog_campaign_repository.dart';

/// Lists every non-deleted `CatalogCampaign` of an Organization (TASK-080),
/// active, scheduled, expired or inactive — the data behind the
/// administrative `CampaignsPage`, which (unlike the catalog home's
/// section) must still show a campaign that is not visible to end users
/// today.
@injectable
final class ListCampaignsUseCase {
  ListCampaignsUseCase(this._repository);

  final CatalogCampaignRepository _repository;

  Future<AppResult<List<CatalogCampaign>>> call(String organizationId) {
    return _repository.listByOrganization(organizationId.trim());
  }
}
