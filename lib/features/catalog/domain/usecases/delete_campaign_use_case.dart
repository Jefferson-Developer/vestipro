import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/catalog_campaign.dart';
import '../repositories/catalog_campaign_repository.dart';

/// Soft-deletes a `CatalogCampaign` (TASK-080): once deleted, it never
/// appears again in `listByOrganization`, the catalog home's "campanhas em
/// destaque" section, nor as "em campanha" in any product screen.
@injectable
final class DeleteCampaignUseCase {
  DeleteCampaignUseCase(this._repository);

  final CatalogCampaignRepository _repository;

  Future<AppResult<CatalogCampaign>> call({
    required String organizationId,
    required String id,
    required String updatedBy,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedId = id.trim();
    final trimmedUpdatedBy = updatedBy.trim();

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedUpdatedBy.isEmpty) {
      fieldErrors['updatedBy'] = 'UpdatedBy is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<CatalogCampaign>(
        ValidationFailure(
          'Invalid campaign delete payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_campaign_delete_payload',
        ),
      );
    }

    return _repository.delete(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
      updatedBy: trimmedUpdatedBy,
    );
  }
}
