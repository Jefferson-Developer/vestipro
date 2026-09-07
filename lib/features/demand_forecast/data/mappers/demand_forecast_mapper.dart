import 'package:injectable/injectable.dart';

import '../../domain/entities/demand_forecast.dart';
import '../../domain/entities/demand_forecast_history_point.dart';
import '../../domain/entities/demand_forecast_period_projection.dart';
import '../../domain/value_objects/demand_forecast_scope_type.dart';
import '../../domain/value_objects/demand_forecast_status.dart';
import '../dtos/demand_forecast_dto.dart';

@lazySingleton
final class DemandForecastMapper {
  const DemandForecastMapper();

  DemandForecast toEntity(DemandForecastDto dto) {
    return DemandForecast(
      id: dto.id,
      organizationId: dto.organizationId,
      companyId: dto.companyId,
      scopeType: parseDemandForecastScopeType(dto.scopeType),
      scopeId: dto.scopeId,
      scopeLabel: dto.scopeLabel,
      anchorMonthKey: dto.anchorMonthKey,
      status: parseDemandForecastStatus(dto.status),
      insufficientDataReason: dto.insufficientDataReason == null
          ? null
          : parseDemandForecastInsufficientDataReason(
              dto.insufficientDataReason!,
            ),
      observedPeriodsCount: dto.observedPeriodsCount,
      model: dto.model,
      modelVersion: dto.modelVersion,
      residualStdDev: dto.residualStdDev,
      history: dto.history
          .map(
            (point) => DemandForecastHistoryPoint(
              periodKey: point.periodKey,
              quantity: point.quantity,
              observed: point.observed,
            ),
          )
          .toList(growable: false),
      forecastPeriods: dto.forecastPeriods
          .map(
            (period) => DemandForecastPeriodProjection(
              periodKey: period.periodKey,
              predictedQuantity: period.predictedQuantity,
              lowerBound: period.lowerBound,
              upperBound: period.upperBound,
              actualQuantity: period.actualQuantity,
              absolutePercentageError: period.absolutePercentageError,
            ),
          )
          .toList(growable: false),
      generatedAt: dto.generatedAt,
      updatedAt: dto.updatedAt,
      version: dto.version,
    );
  }
}
