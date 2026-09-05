import '../../../../core/utils/utils.dart';
import '../entities/report_catalog.dart';
import '../entities/report_definition.dart';
import '../entities/report_query_result.dart';

abstract interface class ReportRepository {
  Future<AppResult<ReportCatalog>> loadCatalog({
    required String organizationId,
    required String companyId,
  });

  Future<AppResult<ReportQueryResult>> execute(ReportDefinition definition);
}

abstract interface class ReportDraftRepository {
  Future<ReportDefinition?> load({
    required String userId,
    required String organizationId,
    required String companyId,
  });
  Future<void> save({
    required String userId,
    required ReportDefinition definition,
  });
}
