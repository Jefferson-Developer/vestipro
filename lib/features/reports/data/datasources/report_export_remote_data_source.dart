import '../../domain/entities/report_definition.dart';
import '../../domain/entities/report_export_result.dart';

abstract interface class ReportExportRemoteDataSource {
  Future<Map<String, dynamic>> exportCsv({
    required ReportDefinition definition,
    required ReportExportLocale locale,
  });
}
