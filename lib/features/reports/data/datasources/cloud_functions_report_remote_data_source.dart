import 'package:injectable/injectable.dart';

import '../../../../core/functions/functions.dart';
import '../../domain/entities/report_definition.dart';
import 'report_remote_data_source.dart';

@LazySingleton(as: ReportRemoteDataSource)
final class CloudFunctionsReportRemoteDataSource
    implements ReportRemoteDataSource {
  const CloudFunctionsReportRemoteDataSource(this._functions);
  final CloudFunctionsService _functions;

  @override
  Future<Map<String, dynamic>> loadCatalog({
    required String organizationId,
    required String companyId,
  }) => _functions.call<Map<String, dynamic>>(
    'loadReportCatalog',
    data: <String, dynamic>{
      'organizationId': organizationId,
      'companyId': companyId,
    },
    requireAuth: true,
  );

  @override
  Future<Map<String, dynamic>> execute(ReportDefinition definition) =>
      _functions.call<Map<String, dynamic>>(
        'executeReportQuery',
        data: Map<String, dynamic>.from(definition.toJson()),
        requireAuth: true,
      );
}
