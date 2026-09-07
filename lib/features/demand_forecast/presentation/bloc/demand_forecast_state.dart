import '../../../../core/errors/errors.dart';
import '../../domain/entities/demand_forecast.dart';
import '../../domain/value_objects/demand_forecast_scope_type.dart';

enum DemandForecastLoadStatus { initial, loading, ready, failure }

final class DemandForecastState {
  const DemandForecastState({
    this.loadStatus = DemandForecastLoadStatus.initial,
    this.organizationId = '',
    this.companyId = '',
    this.userId = '',
    this.scopeType = DemandForecastScopeType.product,
    this.scopeId = '',
    this.forecast,
    this.failure,
  });

  final DemandForecastLoadStatus loadStatus;
  final String organizationId;
  final String companyId;
  final String userId;
  final DemandForecastScopeType scopeType;
  final String scopeId;

  /// `null` while loading/on failure, or when the query succeeded but no
  /// `DemandForecast` has ever been generated for this scope yet — distinct
  /// from [failure], which means the request itself could not be completed.
  final DemandForecast? forecast;
  final Failure? failure;

  bool get isLoading =>
      loadStatus == DemandForecastLoadStatus.initial ||
      loadStatus == DemandForecastLoadStatus.loading;

  DemandForecastState copyWith({
    DemandForecastLoadStatus? loadStatus,
    String? organizationId,
    String? companyId,
    String? userId,
    DemandForecastScopeType? scopeType,
    String? scopeId,
    DemandForecast? forecast,
    bool clearForecast = false,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return DemandForecastState(
      loadStatus: loadStatus ?? this.loadStatus,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      scopeType: scopeType ?? this.scopeType,
      scopeId: scopeId ?? this.scopeId,
      forecast: clearForecast ? null : forecast ?? this.forecast,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}
