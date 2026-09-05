import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/report_catalog.dart';
import '../entities/report_definition.dart';
import '../entities/report_query_result.dart';
import '../repositories/report_repository.dart';
import 'validate_report_definition.dart';

@injectable
final class LoadReportCatalog {
  const LoadReportCatalog(this._repository);
  final ReportRepository _repository;
  Future<AppResult<ReportCatalog>> call({
    required String organizationId,
    required String companyId,
  }) => _repository.loadCatalog(
    organizationId: organizationId,
    companyId: companyId,
  );
}

@injectable
final class ExecuteReportQuery {
  const ExecuteReportQuery(this._repository, this._validate);
  final ReportRepository _repository;
  final ValidateReportDefinition _validate;

  Future<AppResult<ReportQueryResult>> call(
    ReportDefinition definition,
    ReportCatalog catalog,
  ) async {
    final validation = _validate(definition, catalog);
    if (validation is AppFailure<void>) {
      return AppFailure<ReportQueryResult>(validation.failure);
    }
    return _repository.execute(definition);
  }
}
