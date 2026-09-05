import '../../domain/entities/report_definition.dart';

abstract interface class ReportRemoteDataSource {
  Future<Map<String, dynamic>> loadCatalog({
    required String organizationId,
    required String companyId,
  });
  Future<Map<String, dynamic>> execute(ReportDefinition definition);
}
