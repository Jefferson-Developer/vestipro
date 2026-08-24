import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/opportunity.dart';
import '../repositories/opportunity_repository.dart';
import '../value_objects/opportunity_status.dart';
import '../value_objects/opportunity_sync_status.dart';
import 'opportunity_use_case_helpers.dart';

/// Creates an Opportunity, the base unit of the sales pipeline (TASK-057).
///
/// A newly created Opportunity always starts as [OpportunityStatus.open];
/// moving it forward is the job of `UpdateOpportunityStageUseCase`,
/// `MarkOpportunityWonUseCase` and `MarkOpportunityLostUseCase`.
///
/// [revenueForecast] is always derived here as `estimatedValue *
/// probability / 100`, never accepted as caller input, so it can never drift
/// from the values it is computed from at creation time.
final class CreateOpportunityUseCase {
  CreateOpportunityUseCase(this._repository);

  final OpportunityRepository _repository;

  Future<AppResult<Opportunity>> call({
    required String id,
    required String organizationId,
    String? companyId,
    required String title,
    String? description,
    String? customerId,
    String? leadId,
    required double estimatedValue,
    required int probability,
    required String responsibleUserId,
    required String stageId,
    required DateTime expectedCloseDate,
    required String createdBy,
  }) async {
    final trimmedId = id.trim();
    final trimmedOrganizationId = organizationId.trim();
    final trimmedTitle = title.trim();
    final trimmedResponsibleUserId = responsibleUserId.trim();
    final trimmedStageId = stageId.trim();
    final trimmedCreatedBy = createdBy.trim();
    final normalizedCustomerId = normalizeOpportunityOptional(customerId);
    final normalizedLeadId = normalizeOpportunityOptional(leadId);
    final fieldErrors = <String, String>{};

    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedTitle.isEmpty) fieldErrors['title'] = 'Title is required.';
    if (trimmedResponsibleUserId.isEmpty) {
      fieldErrors['responsibleUserId'] = 'ResponsibleUserId is required.';
    }
    if (trimmedStageId.isEmpty) {
      fieldErrors['stageId'] = 'StageId is required.';
    }
    if (trimmedCreatedBy.isEmpty) {
      fieldErrors['createdBy'] = 'CreatedBy is required.';
    }
    if (normalizedCustomerId == null && normalizedLeadId == null) {
      fieldErrors['customerId'] =
          'Either customerId or leadId must be provided.';
      fieldErrors['leadId'] = 'Either customerId or leadId must be provided.';
    }
    if (estimatedValue < 0) {
      fieldErrors['estimatedValue'] = 'EstimatedValue cannot be negative.';
    }
    if (probability < 0 || probability > 100) {
      fieldErrors['probability'] = 'Probability must be between 0 and 100.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<Opportunity>(
        ValidationFailure(
          'Invalid opportunity creation payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_opportunity_create_payload',
        ),
      );
    }

    final now = DateTime.now().toUtc();
    final opportunity = Opportunity(
      id: trimmedId,
      organizationId: trimmedOrganizationId,
      companyId: normalizeOpportunityOptional(companyId),
      title: trimmedTitle,
      description: normalizeOpportunityOptional(description),
      customerId: normalizedCustomerId,
      leadId: normalizedLeadId,
      estimatedValue: estimatedValue,
      probability: probability,
      revenueForecast: estimatedValue * probability / 100.0,
      responsibleUserId: trimmedResponsibleUserId,
      stageId: trimmedStageId,
      status: OpportunityStatus.open,
      expectedCloseDate: expectedCloseDate,
      createdAt: now,
      createdBy: trimmedCreatedBy,
      updatedAt: now,
      updatedBy: trimmedCreatedBy,
      version: 1,
      syncStatus: OpportunitySyncStatus.pending,
    );

    return _repository.create(opportunity: opportunity);
  }
}
