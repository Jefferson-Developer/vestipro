import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/report_catalog.dart';
import '../entities/report_definition.dart';
import '../entities/report_export_result.dart';
import '../entities/report_query_result.dart';
import '../repositories/report_export_repository.dart';
import '../services/report_export_file_name_builder.dart';

/// Orchestrates the full XLSX export flow (TASK-147) — the same
/// small-volume/large-volume routing `ExportReportToCsv` (TASK-146) already
/// established: decides — based on [maxLocalRows], a caller-supplied,
/// feature-flag-backed threshold
/// (`FeatureFlagRegistry.configReportExportMaxLocalRows`, read by
/// `ReportBuilderBloc`, never hardcoded here) — whether [result] is small
/// enough to encode on-device or must be delegated to the
/// `exportReportToXlsx` Cloud Function.
///
/// [result] must always be the *exact* result the report builder already
/// executed under the caller's own RBAC/tenant scope
/// (`ExecuteReportQuery`) — this use case never adds, removes or re-fetches
/// rows on its own for the local path. [catalog] is only ever used to
/// resolve column *types* for cell formatting (`ReportColumnValueTypeResolver`)
/// — it plays no role in authorization; the remote path re-derives its own
/// rows and catalog server-side instead of trusting either at all.
@injectable
final class ExportReportToXlsx {
  const ExportReportToXlsx(this._repository);

  final ReportExportRepository _repository;

  Future<AppResult<ReportExportSummary>> call({
    required ReportDefinition definition,
    required ReportQueryResult result,
    required ReportCatalog catalog,
    required int maxLocalRows,
    ReportExportLocale locale = ReportExportLocale.ptBr,
  }) async {
    if (result.rows.length > maxLocalRows) {
      return _repository.requestCloudXlsxExport(
        definition: definition,
        locale: locale,
      );
    }

    final fileName = ReportExportFileNameBuilder.build(
      definition: definition,
      generatedAt: result.generatedAt,
      extension: 'xlsx',
    );

    try {
      final bytes = await _repository.encodeXlsx(result, catalog, locale);
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
          'Não foi possível gerar o arquivo XLSX.',
          code: 'report_xlsx_export_unexpected',
          cause: error,
        ),
      );
    }
  }
}
