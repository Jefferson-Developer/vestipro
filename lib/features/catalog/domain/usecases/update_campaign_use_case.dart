import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/catalog_campaign.dart';
import '../repositories/catalog_campaign_repository.dart';
import 'campaign_use_case_validation.dart';

/// Updates every editable field of a `CatalogCampaign` (TASK-080), including
/// `active`/`startAt`/`endAt` — unlike `Collection`'s dedicated
/// `CloseCollectionUseCase`, a campaign's activation window is itself just
/// regular editorial content an admin republishes at will, so there is no
/// separate "close" step here.
@injectable
final class UpdateCampaignUseCase {
  UpdateCampaignUseCase(this._repository);

  final CatalogCampaignRepository _repository;

  Future<AppResult<CatalogCampaign>> call({
    required String organizationId,
    required String id,
    required String title,
    String? subtitle,
    String? description,
    String? imageUrl,
    List<String> editorialImageUrls = const <String>[],
    List<String> relatedProductIds = const <String>[],
    String? collectionId,
    int? order,
    required bool active,
    DateTime? startAt,
    DateTime? endAt,
    required String updatedBy,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedId = id.trim();
    final trimmedTitle = title.trim();
    final trimmedUpdatedBy = updatedBy.trim();

    final fieldErrors = validateCampaignFields(
      id: trimmedId,
      organizationId: trimmedOrganizationId,
      title: trimmedTitle,
      actorId: trimmedUpdatedBy,
      actorField: 'updatedBy',
      startAt: startAt,
      endAt: endAt,
    );
    if (fieldErrors.isNotEmpty) {
      return AppFailure<CatalogCampaign>(
        ValidationFailure(
          'Invalid campaign update payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_campaign_update_payload',
        ),
      );
    }

    final existingResult = await _repository.getById(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
    );
    if (existingResult is AppFailure<CatalogCampaign>) return existingResult;
    final existing = (existingResult as AppSuccess<CatalogCampaign>).value;

    final updated = existing.copyWith(
      title: trimmedTitle,
      subtitle: normalizeCampaignOptional(subtitle),
      description: normalizeCampaignOptional(description),
      imageUrl: normalizeCampaignOptional(imageUrl),
      editorialImageUrls: List<String>.unmodifiable(editorialImageUrls),
      relatedProductIds: List<String>.unmodifiable(relatedProductIds),
      collectionId: normalizeCampaignOptional(collectionId),
      order: order ?? existing.order,
      active: active,
      startAt: startAt?.toUtc(),
      endAt: endAt?.toUtc(),
      updatedAt: DateTime.now().toUtc(),
      updatedBy: trimmedUpdatedBy,
    );

    return _repository.update(campaign: updated);
  }
}
