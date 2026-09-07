import '../../domain/value_objects/demand_forecast_scope_type.dart';

sealed class DemandForecastEvent {
  const DemandForecastEvent();
}

/// Fired once when the screen opens, and again whenever the gestor submits a
/// different escopo/período filter.
final class DemandForecastRequested extends DemandForecastEvent {
  const DemandForecastRequested({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.scopeType,
    required this.scopeId,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final DemandForecastScopeType scopeType;
  final String scopeId;
}

final class DemandForecastRefreshRequested extends DemandForecastEvent {
  const DemandForecastRefreshRequested();
}
