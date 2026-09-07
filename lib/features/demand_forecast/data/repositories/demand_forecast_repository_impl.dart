import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/demand_forecast.dart';
import '../../domain/repositories/demand_forecast_repository.dart';
import '../../domain/value_objects/demand_forecast_scope_type.dart';
import '../datasources/demand_forecast_data_source.dart';
import '../mappers/demand_forecast_mapper.dart';

/// Read-only Firestore-backed [DemandForecastRepository] (TASK-185,
/// EPIC-27) — already scoped/RBAC'd by `firestore.rules`, same
/// "Firestore-only repository" shape `StockAlertRepositoryImpl` already
/// established, since a `DemandForecast` is never mutated by a client.
@LazySingleton(as: DemandForecastRepository)
final class DemandForecastRepositoryImpl implements DemandForecastRepository {
  const DemandForecastRepositoryImpl({
    required this.dataSource,
    required this.mapper,
  });

  final DemandForecastDataSource dataSource;
  final DemandForecastMapper mapper;

  @override
  Future<AppResult<DemandForecast?>> getLatestForecast({
    required String organizationId,
    required String companyId,
    required DemandForecastScopeType scopeType,
    required String scopeId,
  }) async {
    try {
      final dto = await dataSource.getLatestForecast(
        organizationId: organizationId,
        companyId: companyId,
        scopeType: scopeType.code,
        scopeId: scopeId,
      );
      return AppSuccess<DemandForecast?>(
        dto == null ? null : mapper.toEntity(dto),
      );
    } on AppException catch (exception) {
      return AppFailure<DemandForecast?>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<DemandForecast?>(
        UnexpectedFailure(
          'Unexpected error loading the demand forecast.',
          code: 'demand_forecast_load_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
