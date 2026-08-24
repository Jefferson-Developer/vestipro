import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/opportunity.dart';
import '../repositories/opportunity_repository.dart';
import 'opportunity_use_case_helpers.dart';

/// Lists every Opportunity feeding the pipeline board (TASK-058). See
/// [OpportunityRepository.listByOrganization] for the [responsibleUserIds]
/// visibility-scope contract.
@injectable
final class ListPipelineOpportunitiesUseCase {
  const ListPipelineOpportunitiesUseCase(this._repository);

  final OpportunityRepository _repository;

  Future<AppResult<List<Opportunity>>> call({
    required String organizationId,
    String? companyId,
    Set<String> responsibleUserIds = const <String>{},
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    if (trimmedOrganizationId.isEmpty) {
      return const AppFailure<List<Opportunity>>(
        ValidationFailure(
          'Invalid pipeline opportunity listing payload.',
          fieldErrors: <String, String>{
            'organizationId': 'OrganizationId is required.',
          },
          code: 'invalid_pipeline_opportunity_list_payload',
        ),
      );
    }

    final trimmedCompanyId = normalizeOpportunityOptional(companyId);
    return _repository.listByOrganization(
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      responsibleUserIds: responsibleUserIds
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toSet(),
    );
  }
}
