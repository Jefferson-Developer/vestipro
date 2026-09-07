import '../dtos/demand_forecast_dto.dart';

abstract interface class DemandForecastDataSource {
  /// Returns the most recently generated `DemandForecast` for one exact
  /// scope, or `null` when none has ever been computed.
  Future<DemandForecastDto?> getLatestForecast({
    required String organizationId,
    required String companyId,
    required String scopeType,
    required String scopeId,
  });
}
