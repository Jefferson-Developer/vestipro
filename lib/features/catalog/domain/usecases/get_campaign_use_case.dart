import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/catalog_campaign.dart';
import '../repositories/catalog_campaign_repository.dart';

/// Loads a single `CatalogCampaign` by id (TASK-080): used both by
/// `CampaignFormBloc` (editing) and `LookbookBloc` (the public lookbook
/// screen). Never filters by visibility itself — the admin form must still
/// be able to open an expired/scheduled campaign to edit it; visibility is
/// the caller's decision (`CatalogCampaign.isVisibleAt`).
@injectable
final class GetCampaignUseCase {
  GetCampaignUseCase(this._repository);

  final CatalogCampaignRepository _repository;

  Future<AppResult<CatalogCampaign>> call({
    required String organizationId,
    required String id,
  }) {
    return _repository.getById(
      organizationId: organizationId.trim(),
      id: id.trim(),
    );
  }
}
