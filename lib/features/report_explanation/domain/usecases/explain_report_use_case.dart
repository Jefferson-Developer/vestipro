import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../reports/domain/entities/report_definition.dart';
import '../entities/report_explanation.dart';
import '../repositories/report_explanation_repository.dart';

/// Requests TASK-189's "explicação de relatórios" (EPIC-28) for a
/// [ReportDefinition]. Input validation only — the real authorization
/// boundary is server-side (`explainReport` re-derives the report's own
/// rows via `runReportAggregation`, under the caller's own role/tenant
/// scope, exactly like `exportReportToCsv`, TASK-146): both entry points
/// this feature is reached from (the construtor de relatórios, TASK-144; an
/// existing dashboard already showing an aggregated result) already gate
/// the surrounding screen to data the caller is already allowed to see, so
/// this use case does not duplicate a separate client-side visibility check
/// the way `GenerateWalletSummaryUseCase` (TASK-186) does for a *seller's*
/// wallet.
@injectable
final class ExplainReportUseCase {
  const ExplainReportUseCase(this._repository, this._analyticsService);

  final ReportExplanationRepository _repository;
  final AnalyticsService _analyticsService;

  Future<AppResult<ReportExplanation>> call({
    required ReportDefinition definition,
    String? savedReportId,
  }) async {
    if (definition.dimensions.isEmpty || definition.metrics.isEmpty) {
      return const AppFailure<ReportExplanation>(
        ValidationFailure(
          'Selecione ao menos uma dimensão e uma métrica antes de explicar o relatório.',
          fieldErrors: <String, String>{
            'definition': 'At least one dimension and one metric are required.',
          },
          code: 'invalid_report_explanation_request',
        ),
      );
    }

    final result = await _repository.explain(
      definition: definition,
      savedReportId: savedReportId,
    );
    switch (result) {
      case AppSuccess<ReportExplanation>(value: final explanation):
        await _analyticsService.logEvent(
          AnalyticsEvents.reportExplanationGenerated,
          parameters: <String, Object?>{
            'organization_id': definition.organizationId,
            'from_cache': explanation.fromCache,
          },
        );
      case AppFailure<ReportExplanation>(failure: final failure):
        await _analyticsService.logEvent(
          AnalyticsEvents.reportExplanationGenerationFailed,
          parameters: <String, Object?>{
            'organization_id': definition.organizationId,
            'failure_code': failure.code,
          },
        );
    }
    return result;
  }
}
