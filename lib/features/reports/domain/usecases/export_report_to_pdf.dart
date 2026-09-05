import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/report_catalog.dart';
import '../entities/report_definition.dart';
import '../entities/report_export_result.dart';
import '../entities/report_query_result.dart';
import '../repositories/report_export_repository.dart';
import '../services/report_export_file_name_builder.dart';

/// Orchestrates the full PDF export flow (TASK-148) in two explicit steps —
/// unlike `ExportReportToCsv`/`ExportReportToXlsx`, which save straight to
/// disk, a PDF export always shows a pré-visualização the user can cancel
/// before anything is persisted (TASK-148's own acceptance criteria):
///
/// 1. [call] decides — based on [maxLocalRows], the same feature-flag-backed
///    threshold the other two formats use — whether [result] is small
///    enough to render on-device. When it is, it resolves the calling
///    organization's branding (`ReportExportRepository.loadBranding`) and
///    encodes the PDF, returning the bytes as a [LocalReportPdfPreview]
///    *without saving them anywhere yet*. When [result] is too large, it
///    delegates the whole flow to the `exportReportToPdf` Cloud Function
///    instead and returns a [RemoteReportPdfPreview] — there is no local
///    preview step for that path at all, since no bytes ever reach the
///    client.
/// 2. [confirm] is only ever called after the user accepts a
///    [LocalReportPdfPreview] shown by [call] — it hands the *same*
///    already-encoded bytes to `saveLocalFile`, so confirming a preview
///    never re-encodes the report or re-fetches branding a second time.
///
/// [result]/[catalog] must always be the *exact* result/schema the report
/// builder already executed under the caller's own RBAC/tenant scope — this
/// use case never adds, removes or re-fetches rows on its own for the local
/// path; the remote path re-derives its own rows/catalog server-side instead
/// of trusting either at all.
@injectable
final class ExportReportToPdf {
  const ExportReportToPdf(this._repository);

  final ReportExportRepository _repository;

  Future<AppResult<ReportPdfPreviewResult>> call({
    required ReportDefinition definition,
    required ReportQueryResult result,
    required ReportCatalog catalog,
    required int maxLocalRows,
    ReportExportLocale locale = ReportExportLocale.ptBr,
  }) async {
    if (result.rows.length > maxLocalRows) {
      final cloudResult = await _repository.requestCloudPdfExport(
        definition: definition,
        locale: locale,
      );
      return switch (cloudResult) {
        AppSuccess<ReportExportSummary>(value: final summary) =>
          AppSuccess<ReportPdfPreviewResult>(RemoteReportPdfPreview(summary)),
        AppFailure<ReportExportSummary>(failure: final failure) =>
          AppFailure<ReportPdfPreviewResult>(failure),
      };
    }

    final fileName = ReportExportFileNameBuilder.build(
      definition: definition,
      generatedAt: result.generatedAt,
      extension: 'pdf',
    );

    try {
      final branding = await _repository.loadBranding(
        definition.organizationId,
      );
      final bytes = await _repository.encodePdf(
        definition: definition,
        result: result,
        catalog: catalog,
        branding: branding,
        locale: locale,
      );
      return AppSuccess<ReportPdfPreviewResult>(
        LocalReportPdfPreview(
          bytes: bytes,
          fileName: fileName,
          rowCount: result.rows.length,
        ),
      );
    } catch (error) {
      return AppFailure<ReportPdfPreviewResult>(
        UnexpectedFailure(
          'Não foi possível gerar a pré-visualização do PDF.',
          code: 'report_pdf_preview_unexpected',
          cause: error,
        ),
      );
    }
  }

  /// Persists the bytes a previously-shown [LocalReportPdfPreview] already
  /// carried — never re-encodes, never re-fetches branding.
  Future<AppResult<ReportExportSummary>> confirm(
    LocalReportPdfPreview preview,
  ) async {
    final saved = await _repository.saveLocalFile(
      bytes: preview.bytes,
      fileName: preview.fileName,
    );
    return switch (saved) {
      AppSuccess<String>(value: final path) => AppSuccess<ReportExportSummary>(
        ReportExportSummary(
          fileName: preview.fileName,
          rowCount: preview.rowCount,
          location: LocalReportExportLocation(path),
        ),
      ),
      AppFailure<String>(failure: final failure) =>
        AppFailure<ReportExportSummary>(failure),
    };
  }
}
