import 'package:injectable/injectable.dart';

import '../../../../core/functions/functions.dart';
import '../../domain/entities/report_definition.dart';
import '../../domain/entities/report_export_result.dart';
import 'report_export_remote_data_source.dart';

@LazySingleton(as: ReportExportRemoteDataSource)
final class CloudFunctionsReportExportRemoteDataSource
    implements ReportExportRemoteDataSource {
  const CloudFunctionsReportExportRemoteDataSource(this._functions);
  final CloudFunctionsService _functions;

  @override
  Future<Map<String, dynamic>> exportCsv({
    required ReportDefinition definition,
    required ReportExportLocale locale,
  }) => _functions.call<Map<String, dynamic>>(
    'exportReportToCsv',
    data: <String, dynamic>{...definition.toJson(), 'locale': locale.code},
    requireAuth: true,
  );

  @override
  Future<Map<String, dynamic>> exportXlsx({
    required ReportDefinition definition,
    required ReportExportLocale locale,
  }) => _functions.call<Map<String, dynamic>>(
    'exportReportToXlsx',
    data: <String, dynamic>{...definition.toJson(), 'locale': locale.code},
    requireAuth: true,
  );

  @override
  Future<Map<String, dynamic>> exportPdf({
    required ReportDefinition definition,
    required ReportExportLocale locale,
  }) => _functions.call<Map<String, dynamic>>(
    'exportReportToPdf',
    data: <String, dynamic>{...definition.toJson(), 'locale': locale.code},
    requireAuth: true,
  );
}
