import '../../../../core/utils/utils.dart';
import '../entities/demand_forecast.dart';
import '../value_objects/demand_forecast_scope_type.dart';

/// Contract behind reading the most recent `DemandForecast` for one scope
/// (TASK-185, EPIC-27). Always read-only, direct-to-Firestore (already
/// scoped/RBAC'd by `firestore.rules`) — unlike
/// `ReplenishmentRepository` (TASK-184), there is no decision/mutation
/// callable here: a `DemandForecast` is never acted upon by a client, only
/// consumed.
abstract interface class DemandForecastRepository {
  /// Returns `null` (never a [Failure]) when no `DemandForecast` has ever
  /// been generated yet for this exact scope — distinct from
  /// [DemandForecast.isAvailable] being `false`, which means a forecast
  /// *was* computed but the scope had insufficient history.
  Future<AppResult<DemandForecast?>> getLatestForecast({
    required String organizationId,
    required String companyId,
    required DemandForecastScopeType scopeType,
    required String scopeId,
  });
}
