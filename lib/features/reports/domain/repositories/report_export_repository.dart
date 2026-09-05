import '../../../../core/utils/utils.dart';
import '../entities/report_catalog.dart';
import '../entities/report_definition.dart';
import '../entities/report_export_result.dart';
import '../entities/report_query_result.dart';

/// Ports `ExportReportToCsv` (TASK-146) and `ExportReportToXlsx` (TASK-147)
/// need, each backed by a different datasource: [encodeCsv]/[encodeXlsx] run
/// entirely on-device (an isolate, see `CsvIsolateEncoder`/
/// `XlsxIsolateEncoder`), [saveLocalFile] hands the encoded bytes to the
/// platform's own "save file" flow (format-agnostic — it infers
/// mime-type/extension from `fileName`), and [requestCloudCsvExport]/
/// [requestCloudXlsxExport] delegate the whole large-volume flow to the
/// matching Cloud Function.
abstract interface class ReportExportRepository {
  /// Encodes [result] as CSV bytes (BOM + [locale]'s delimiter/decimal
  /// convention) off the calling isolate, so generating a large file never
  /// blocks the UI thread.
  Future<List<int>> encodeCsv(
    ReportQueryResult result,
    ReportExportLocale locale,
  );

  /// Encodes [result] as XLSX bytes off the calling isolate — cell types
  /// (date/currency/percentage/number/text) are resolved from [catalog]
  /// (`ReportColumnValueTypeResolver`), the same schema the report was built
  /// against, never guessed from the raw runtime value alone.
  Future<List<int>> encodeXlsx(
    ReportQueryResult result,
    ReportCatalog catalog,
    ReportExportLocale locale,
  );

  /// Saves [bytes] as [fileName] through the platform's native "save
  /// file"/"share" flow. A `null`-returning success (user cancelled the
  /// native dialog) is surfaced as an [AppFailure] with a dedicated code so
  /// the caller can tell "cancelled" apart from a real I/O error.
  Future<AppResult<String>> saveLocalFile({
    required List<int> bytes,
    required String fileName,
  });

  /// Delegates CSV generation entirely to the `exportReportToCsv` Cloud
  /// Function for volumes above the configured client-side threshold
  /// (`FeatureFlagRegistry.configReportExportMaxLocalRows`): the callable
  /// re-executes [definition]'s aggregation itself, under the caller's own
  /// role/tenant scope — it never receives or trusts a client-computed
  /// [ReportQueryResult] — and uploads the resulting CSV to a
  /// user-restricted, time-limited Storage location.
  Future<AppResult<ReportExportSummary>> requestCloudCsvExport({
    required ReportDefinition definition,
    required ReportExportLocale locale,
  });

  /// Same large-volume delegation as [requestCloudCsvExport], but for the
  /// `exportReportToXlsx` Cloud Function (TASK-147) — also never trusts a
  /// client-computed [ReportQueryResult] or [ReportCatalog]; the callable
  /// re-derives its own copy of both, server-side, under the caller's own
  /// role/tenant scope.
  Future<AppResult<ReportExportSummary>> requestCloudXlsxExport({
    required ReportDefinition definition,
    required ReportExportLocale locale,
  });
}
