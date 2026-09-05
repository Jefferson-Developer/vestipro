import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/report_catalog.dart';
import '../../domain/entities/report_definition.dart';
import '../../domain/entities/report_query_result.dart';
import '../../domain/repositories/report_repository.dart';
import '../datasources/report_remote_data_source.dart';

@LazySingleton(as: ReportRepository)
final class ReportRepositoryImpl implements ReportRepository {
  const ReportRepositoryImpl(this._remote);
  final ReportRemoteDataSource _remote;

  @override
  Future<AppResult<ReportCatalog>> loadCatalog({
    required String organizationId,
    required String companyId,
  }) async {
    try {
      return AppSuccess<ReportCatalog>(
        ReportCatalog.fromJson(
          await _remote.loadCatalog(
            organizationId: organizationId,
            companyId: companyId,
          ),
        ),
      );
    } on AppException catch (error) {
      return AppFailure<ReportCatalog>(mapAppExceptionToFailure(error));
    } catch (error) {
      return AppFailure<ReportCatalog>(
        UnexpectedFailure(
          'Não foi possível carregar o catálogo de relatórios.',
          code: 'report_catalog_unexpected',
          cause: error,
        ),
      );
    }
  }

  @override
  Future<AppResult<ReportQueryResult>> execute(
    ReportDefinition definition,
  ) async {
    try {
      return AppSuccess<ReportQueryResult>(
        ReportQueryResult.fromJson(await _remote.execute(definition)),
      );
    } on AppException catch (error) {
      return AppFailure<ReportQueryResult>(mapAppExceptionToFailure(error));
    } catch (error) {
      return AppFailure<ReportQueryResult>(
        UnexpectedFailure(
          'Não foi possível executar o relatório.',
          code: 'report_query_unexpected',
          cause: error,
        ),
      );
    }
  }
}
