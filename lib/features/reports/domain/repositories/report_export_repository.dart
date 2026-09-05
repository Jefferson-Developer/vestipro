import '../../../../core/utils/utils.dart';
import '../entities/report_definition.dart';
import '../entities/report_export_result.dart';
import '../entities/report_query_result.dart';

/// Ports `ExportReportToCsv` (TASK-146) needs, each backed by a different
/// datasource: [encodeCsv] runs entirely on-device (an isolate, see
/// `CsvIsolateEncoder`), [saveLocalFile] hands the encoded bytes to the
/// platform's own "save file" flow, and [requestCloudCsvExport] delegates
/// the whole large-volume flow to the `exportReportToCsv` Cloud Function.
abstract interface class ReportExportRepository {
  /// Encodes [result] as CSV bytes (BOM + [locale]'s delimiter/decimal
  /// convention) off the calling isolate, so generating a large file never
  /// blocks the UI thread.
  Future<List<int>> encodeCsv(
    ReportQueryResult result,
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
}
