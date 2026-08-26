import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/catalog_campaign.dart';
import '../repositories/catalog_campaign_repository.dart';
import 'campaign_use_case_validation.dart';

/// Creates a new `CatalogCampaign` (TASK-080), always as `active: true`
/// unless the admin explicitly opts out — publishing/updating a campaign
/// never requires a new app deploy, since it only ever writes data
/// (`CatalogCampaignRepository`), never code.
@injectable
final class CreateCampaignUseCase {
  CreateCampaignUseCase(this._repository);

  final CatalogCampaignRepository _repository;

  Future<AppResult<CatalogCampaign>> call({
    required String id,
    required String organizationId,
    required String title,
    String? subtitle,
    String? description,
    String? imageUrl,
    List<String> editorialImageUrls = const <String>[],
    List<String> relatedProductIds = const <String>[],
    String? collectionId,
    int order = 0,
    bool active = true,
    DateTime? startAt,
    DateTime? endAt,
    required String createdBy,
  }) async {
    final trimmedId = id.trim();
    final trimmedOrganizationId = organizationId.trim();
    final trimmedTitle = title.trim();
    final trimmedCreatedBy = createdBy.trim();

    final fieldErrors = validateCampaignFields(
      id: trimmedId,
      organizationId: trimmedOrganizationId,
      title: trimmedTitle,
      actorId: trimmedCreatedBy,
      actorField: 'createdBy',
      startAt: startAt,
      endAt: endAt,
    );
    if (fieldErrors.isNotEmpty) {
      return AppFailure<CatalogCampaign>(
        ValidationFailure(
          'Invalid campaign creation payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_campaign_create_payload',
        ),
      );
    }

    final now = DateTime.now().toUtc();
    final campaign = CatalogCampaign(
      id: trimmedId,
      organizationId: trimmedOrganizationId,
      title: trimmedTitle,
      subtitle: normalizeCampaignOptional(subtitle),
      description: normalizeCampaignOptional(description),
      imageUrl: normalizeCampaignOptional(imageUrl),
      editorialImageUrls: List<String>.unmodifiable(editorialImageUrls),
      relatedProductIds: List<String>.unmodifiable(relatedProductIds),
      collectionId: normalizeCampaignOptional(collectionId),
      order: order,
      active: active,
      startAt: startAt?.toUtc(),
      endAt: endAt?.toUtc(),
      createdAt: now,
      createdBy: trimmedCreatedBy,
      updatedAt: now,
      updatedBy: trimmedCreatedBy,
    );

    return _repository.create(campaign: campaign);
  }
}
