import '../../../../core/errors/errors.dart';
import '../../../insights/domain/entities/insight.dart';
import '../../domain/entities/executive_dashboard_filters.dart';
import '../../domain/entities/executive_dashboard_snapshot.dart';
import '../../domain/entities/executive_dashboard_visibility_filter.dart';

enum ExecutiveDashboardStatus { initial, loading, forbidden, error, ready }

/// A selectable company/team option for the dashboard's scope filters —
/// `id`+`name` only, never the full `Company`/`Team` entity, so the
/// presentation layer never needs to reach past the bloc for a label.
final class ExecutiveDashboardScopeOption {
  const ExecutiveDashboardScopeOption({required this.id, required this.name});

  final String id;
  final String name;

  @override
  bool operator ==(Object other) {
    return other is ExecutiveDashboardScopeOption &&
        id == other.id &&
        name == other.name;
  }

  @override
  int get hashCode => Object.hash(id, name);
}

final class ExecutiveDashboardState {
  const ExecutiveDashboardState({
    this.status = ExecutiveDashboardStatus.initial,
    this.organizationId = '',
    this.userId = '',
    this.visibilityFilter,
    this.filters = const ExecutiveDashboardFilters(
      companyId: '',
      year: 2024,
      month: 1,
    ),
    this.companyOptions = const <ExecutiveDashboardScopeOption>[],
    this.teamOptions = const <ExecutiveDashboardScopeOption>[],
    this.snapshot,
    this.topInsights = const <Insight>[],
    this.failure,
  });

  final ExecutiveDashboardStatus status;
  final String organizationId;
  final String userId;
  final ExecutiveDashboardVisibilityFilter? visibilityFilter;
  final ExecutiveDashboardFilters filters;
  final List<ExecutiveDashboardScopeOption> companyOptions;
  final List<ExecutiveDashboardScopeOption> teamOptions;
  final ExecutiveDashboardSnapshot? snapshot;

  /// Top insights (by `estimatedImpact`) generated within [filters]'
  /// period, for the "atalho para a Central de Oportunidades" shortcut —
  /// reuses the exact same RBAC scope `OpportunityCenterBloc` (TASK-132)
  /// already resolves, never a second visibility rule.
  final List<Insight> topInsights;

  final Failure? failure;

  /// Whether the caller may pick a company/team other than their own —
  /// mirrors `TargetDashboardState.canPickDimension`'s own precedent.
  bool get canPickScope =>
      visibilityFilter?.mode ==
          ExecutiveDashboardVisibilityMode.allOrganization ||
      companyOptions.length > 1 ||
      teamOptions.isNotEmpty;

  ExecutiveDashboardState copyWith({
    ExecutiveDashboardStatus? status,
    String? organizationId,
    String? userId,
    ExecutiveDashboardVisibilityFilter? visibilityFilter,
    ExecutiveDashboardFilters? filters,
    List<ExecutiveDashboardScopeOption>? companyOptions,
    List<ExecutiveDashboardScopeOption>? teamOptions,
    ExecutiveDashboardSnapshot? snapshot,
    bool clearSnapshot = false,
    List<Insight>? topInsights,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return ExecutiveDashboardState(
      status: status ?? this.status,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      visibilityFilter: visibilityFilter ?? this.visibilityFilter,
      filters: filters ?? this.filters,
      companyOptions: companyOptions ?? this.companyOptions,
      teamOptions: teamOptions ?? this.teamOptions,
      snapshot: clearSnapshot ? null : (snapshot ?? this.snapshot),
      topInsights: topInsights ?? this.topInsights,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}
