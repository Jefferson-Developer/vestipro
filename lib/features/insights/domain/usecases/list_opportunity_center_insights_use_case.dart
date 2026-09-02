import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/insight_page.dart';
import '../entities/insight_visibility_filter.dart';
import '../repositories/insight_repository.dart';
import '../services/insight_visibility_service.dart';

/// Loads one page of the Central de Oportunidades (TASK-132): resolves the
/// caller's [InsightVisibilityFilter] (vendedor vê a própria carteira,
/// gestor vê a equipe, admin vê a organização) and then lists every
/// `Insight` type (TASK-122 a TASK-131) that scope allows, oldest-cursor
/// paginated by `Insight.generatedAt`.
///
/// Sorting by `estimatedImpact` (the screen's mandatory default) and
/// filtering by type/severity/period are applied by
/// `OpportunityCenterBloc` over the loaded page — this use case only
/// resolves *which* insights the caller may see, never how they are
/// ordered/filtered for display.
@injectable
final class ListOpportunityCenterInsightsUseCase {
  const ListOpportunityCenterInsightsUseCase(
    this._visibilityService,
    this._insightRepository,
  );

  final InsightVisibilityService _visibilityService;
  final InsightRepository _insightRepository;

  Future<AppResult<InsightPage>> call({
    required String organizationId,
    required String companyId,
    required String userId,
    int limit = 25,
    DateTime? before,
  }) async {
    final normalizedOrganizationId = organizationId.trim();
    final normalizedCompanyId = companyId.trim();
    final normalizedUserId = userId.trim();
    final fieldErrors = <String, String>{};

    if (normalizedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (normalizedCompanyId.isEmpty) {
      fieldErrors['companyId'] = 'CompanyId is required.';
    }
    if (normalizedUserId.isEmpty) {
      fieldErrors['userId'] = 'UserId is required.';
    }
    if (limit <= 0 || limit > 100) {
      fieldErrors['limit'] = 'Limit must be between 1 and 100.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<InsightPage>(
        ValidationFailure(
          'Invalid opportunity center payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_opportunity_center_payload',
        ),
      );
    }

    final visibilityResult = await _visibilityService.resolve(
      organizationId: normalizedOrganizationId,
      companyId: normalizedCompanyId,
      userId: normalizedUserId,
    );
    if (visibilityResult case AppFailure<InsightVisibilityFilter>(
      failure: final failure,
    )) {
      return AppFailure<InsightPage>(failure);
    }
    final visibility =
        (visibilityResult as AppSuccess<InsightVisibilityFilter>).value;
    if (!visibility.canViewAny) {
      return const AppFailure<InsightPage>(
        PermissionFailure(
          'User has no visible insight.',
          code: 'opportunity_center_not_visible',
        ),
      );
    }

    return _insightRepository.listPageByVisibility(
      organizationId: normalizedOrganizationId,
      visibility: visibility,
      limit: limit,
      before: before,
    );
  }
}
