import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/campaign_creation_draft.dart';
import '../repositories/campaign_assist_repository.dart';

/// Requests TASK-192's "criação assistida de coleção/campanha" (EPIC-28)
/// draft. Input validation only — the real authorization boundary is
/// server-side (`assistCampaignCreation`'s own role check, OWNER/ADMIN
/// only, always re-validated regardless of what the UI enforces): this use
/// case is reached exclusively from `CampaignFormPage` (TASK-080), which
/// already gates the whole screen behind `Capability.catalogManage`.
@injectable
final class GenerateCampaignCreationDraftUseCase {
  const GenerateCampaignCreationDraftUseCase(
    this._repository,
    this._analyticsService,
  );

  final CampaignAssistRepository _repository;
  final AnalyticsService _analyticsService;

  Future<AppResult<CampaignCreationDraft>> call({
    required String organizationId,
    List<String> productIds = const <String>[],
    required String audienceDescription,
    required String tone,
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedAudience = audienceDescription.trim();
    final trimmedTone = tone.trim();

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedAudience.isEmpty) {
      fieldErrors['audienceDescription'] =
          'Descreva o público-alvo da campanha.';
    }
    if (trimmedTone.isEmpty) {
      fieldErrors['tone'] = 'Informe o tom de comunicação desejado.';
    }
    if (startAt != null && endAt != null && endAt.isBefore(startAt)) {
      fieldErrors['endAt'] =
          'A data de término deve ser posterior à data de início.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<CampaignCreationDraft>(
        ValidationFailure(
          'Invalid campaign assist request.',
          fieldErrors: fieldErrors,
          code: 'invalid_campaign_assist_request',
        ),
      );
    }

    final dedupedProductIds = productIds
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);

    final result = await _repository.generate(
      organizationId: trimmedOrganizationId,
      productIds: dedupedProductIds,
      audienceDescription: trimmedAudience,
      tone: trimmedTone,
      startAt: startAt,
      endAt: endAt,
    );
    switch (result) {
      case AppSuccess<CampaignCreationDraft>(value: final draft):
        await _analyticsService.logEvent(
          AnalyticsEvents.campaignAssistDraftGenerated,
          parameters: <String, Object?>{
            'organization_id': trimmedOrganizationId,
            'product_count': dedupedProductIds.length,
            'from_cache': draft.fromCache,
          },
        );
      case AppFailure<CampaignCreationDraft>(failure: final failure):
        await _analyticsService.logEvent(
          AnalyticsEvents.campaignAssistDraftGenerationFailed,
          parameters: <String, Object?>{
            'organization_id': trimmedOrganizationId,
            'failure_code': failure.code,
          },
        );
    }
    return result;
  }
}
