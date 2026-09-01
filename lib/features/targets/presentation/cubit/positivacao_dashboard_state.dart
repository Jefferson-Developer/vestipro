import '../../domain/entities/positivacao_snapshot.dart';
import '../../domain/entities/target_visibility_filter.dart';
import '../../domain/services/positivacao_period_resolver.dart';
import '../../domain/value_objects/positivacao_dimension_type.dart';
import '../../domain/value_objects/positivacao_settings.dart';

enum PositivacaoDashboardStatus {
  initial,
  loading,
  ready,

  /// A carteira/período was resolved, but its snapshot has never been
  /// calculated server-side yet ([PositivacaoSnapshot.isCalculated] ==
  /// `false`) — distinct from [emptyPortfolio], where it *was* calculated
  /// and the carteira simply has zero customers.
  notCalculated,

  /// The snapshot was calculated and the carteira has zero customers —
  /// never confused with [notCalculated].
  emptyPortfolio,

  /// The caller is not allowed to view the currently selected
  /// dimension/dimensionId ([TargetVisibilityFilter.canView] denied it, or
  /// resolved to [TargetVisibilityMode.none] entirely).
  forbidden,
  error,
}

/// Drives the positivação de carteira dashboard (TASK-117, EPIC-15/
/// VESTI-087): resolves RBAC visibility (reusing `TargetVisibilityService`,
/// TASK-116) and subscribes to the selected dimension's near-real-time
/// positivação snapshot for the organization's current configured period.
final class PositivacaoDashboardState {
  const PositivacaoDashboardState({
    this.status = PositivacaoDashboardStatus.initial,
    this.organizationId = '',
    this.companyId = '',
    this.userId = '',
    this.visibilityFilter,
    this.settings,
    this.dimensionType = PositivacaoDimensionType.salesRep,
    this.dimensionId = '',
    this.period,
    this.snapshot,
    this.pendingCustomerLabels = const <String, String>{},
    this.failureMessage,
  });

  final PositivacaoDashboardStatus status;
  final String organizationId;
  final String companyId;
  final String userId;

  /// `null` only before `PositivacaoDashboardCubit.load` resolves it for the
  /// first time.
  final TargetVisibilityFilter? visibilityFilter;

  /// The organization's positivação rule, resolved from
  /// `OrganizationSettings` — `null` only before `load` resolves it.
  final PositivacaoSettings? settings;

  final PositivacaoDimensionType dimensionType;
  final String dimensionId;

  /// The current `[start, end)` window for [settings]'s configured period
  /// granularity — `null` only before [settings] resolves.
  final PositivacaoPeriod? period;

  final PositivacaoSnapshot? snapshot;

  /// Best-effort `Customer.displayName` for each of
  /// [PositivacaoSnapshot.nonPositivatedCustomerIds], resolved lazily/in the
  /// background (never blocking [status] from reaching [ready]) — a missing
  /// entry means the label has not resolved yet (or failed to), the UI falls
  /// back to showing the raw id.
  final Map<String, String> pendingCustomerLabels;

  final String? failureMessage;

  /// Whether the caller may switch [dimensionType]/[dimensionId] at all — a
  /// `SALES_REP` ([TargetVisibilityMode.ownOnly]) only ever sees their own
  /// carteira, so the dimension picker itself should not even render.
  bool get canPickDimension =>
      visibilityFilter?.mode == TargetVisibilityMode.allOrganization ||
      visibilityFilter?.mode == TargetVisibilityMode.teams;

  bool get isBusy => status == PositivacaoDashboardStatus.loading;

  PositivacaoDashboardState copyWith({
    PositivacaoDashboardStatus? status,
    String? organizationId,
    String? companyId,
    String? userId,
    TargetVisibilityFilter? visibilityFilter,
    PositivacaoSettings? settings,
    PositivacaoDimensionType? dimensionType,
    String? dimensionId,
    PositivacaoPeriod? period,
    PositivacaoSnapshot? snapshot,
    bool clearSnapshot = false,
    Map<String, String>? pendingCustomerLabels,
    String? failureMessage,
    bool clearFailureMessage = false,
  }) {
    return PositivacaoDashboardState(
      status: status ?? this.status,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      visibilityFilter: visibilityFilter ?? this.visibilityFilter,
      settings: settings ?? this.settings,
      dimensionType: dimensionType ?? this.dimensionType,
      dimensionId: dimensionId ?? this.dimensionId,
      period: period ?? this.period,
      snapshot: clearSnapshot ? null : (snapshot ?? this.snapshot),
      pendingCustomerLabels:
          pendingCustomerLabels ?? this.pendingCustomerLabels,
      failureMessage: clearFailureMessage
          ? null
          : (failureMessage ?? this.failureMessage),
    );
  }
}
