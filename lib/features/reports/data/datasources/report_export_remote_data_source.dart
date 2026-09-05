import '../../domain/entities/report_definition.dart';
import '../../domain/entities/report_export_result.dart';

abstract interface class ReportExportRemoteDataSource {
  Future<Map<String, dynamic>> exportCsv({
    required ReportDefinition definition,
    required ReportExportLocale locale,
  });

  /// Calls the `exportReportToXlsx` Cloud Function (TASK-147) — same
  /// large-volume delegation as [exportCsv], never trusting a
  /// client-computed result or catalog.
  Future<Map<String, dynamic>> exportXlsx({
    required ReportDefinition definition,
    required ReportExportLocale locale,
  });
}
