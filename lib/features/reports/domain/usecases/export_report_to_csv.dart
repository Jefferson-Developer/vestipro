import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/report_definition.dart';
import '../entities/report_export_result.dart';
import '../entities/report_query_result.dart';
import '../repositories/report_export_repository.dart';
import '../services/report_export_file_name_builder.dart';

/// Orchestrates the full CSV export flow (TASK-146): decides — based on
/// [maxLocalRows], a caller-supplied, feature-flag-backed threshold
/// (`FeatureFlagRegistry.configReportExportMaxLocalRows`, read by
/// `ReportBuilderBloc`, never hardcoded here) — whether [result] is small
/// enough to encode on-device or must be delegated to the
/// `exportReportToCsv` Cloud Function.
///
/// [result] must always be the *exact* result the report builder already
/// executed under the caller's own RBAC/tenant scope
/// (`ExecuteReportQuery`) — this use case never adds, removes or re-fetches
/// rows on its own for the local path; the remote path re-derives its own
/// rows server-side instead of trusting [result] at all, for volumes where a
/// client-held copy would be both slow to transfer and unnecessary to trust.
@injectable
final class ExportReportToCsv {
  const ExportReportToCsv(this._repository);

  final ReportExportRepository _repository;

  Future<AppResult<ReportExportSummary>> call({
    required ReportDefinition definition,
    required ReportQueryResult result,
    required int maxLocalRows,
    ReportExportLocale locale = ReportExportLocale.ptBr,
  }) async {
    if (result.rows.length > maxLocalRows) {
      return _repository.requestCloudCsvExport(
        definition: definition,
        locale: locale,
      );
    }

    final fileName = ReportExportFileNameBuilder.build(
      definition: definition,
      generatedAt: result.generatedAt,
      extension: 'csv',
    );

    try {
      final bytes = await _repository.encodeCsv(result, locale);
      final saved = await _repository.saveLocalFile(
        bytes: bytes,
        fileName: fileName,
      );
      return switch (saved) {
        AppSuccess<String>(value: final path) =>
          AppSuccess<ReportExportSummary>(
            ReportExportSummary(
              fileName: fileName,
              rowCount: result.rows.length,
              location: LocalReportExportLocation(path),
            ),
          ),
        AppFailure<String>(failure: final failure) =>
          AppFailure<ReportExportSummary>(failure),
      };
    } catch (error) {
      return AppFailure<ReportExportSummary>(
        UnexpectedFailure(
          'Não foi possível gerar o arquivo CSV.',
          code: 'report_csv_export_unexpected',
          cause: error,
        ),
      );
    }
  }
}
