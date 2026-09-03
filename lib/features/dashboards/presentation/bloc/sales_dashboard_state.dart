import '../../../../core/errors/errors.dart';
import '../../domain/entities/executive_dashboard_visibility_filter.dart';
import '../../domain/entities/sales_dashboard_filters.dart';
import '../../domain/entities/sales_dashboard_group_row.dart';
import '../../domain/entities/sales_dashboard_snapshot.dart';
import 'executive_dashboard_state.dart' show ExecutiveDashboardScopeOption;

enum SalesDashboardStatus { initial, loading, forbidden, error, ready }

enum SalesDashboardGroupRowsStatus { loading, ready, error }

final class SalesDashboardState {
  const SalesDashboardState({
    this.status = SalesDashboardStatus.initial,
    this.organizationId = '',
    this.userId = '',
    this.visibilityFilter,
    this.filters = const SalesDashboardFilters(
      companyId: '',
      year: 2024,
      month: 1,
    ),
    this.companyOptions = const <ExecutiveDashboardScopeOption>[],
    this.teamOptions = const <ExecutiveDashboardScopeOption>[],
    this.snapshot,
    this.groupRowsStatus = SalesDashboardGroupRowsStatus.loading,
    this.groupRows = const <SalesDashboardGroupRow>[],
    this.groupRowsFailure,
    this.failure,
  });

  final SalesDashboardStatus status;
  final String organizationId;
  final String userId;

  /// Reuses `ExecutiveDashboardVisibilityFilter` verbatim — see
  /// `SalesDashboardBloc`'s own docs for why this dashboard shares the exact
  /// same RBAC scoping semantics as the Executive Dashboard.
  final ExecutiveDashboardVisibilityFilter? visibilityFilter;
  final SalesDashboardFilters filters;
  final List<ExecutiveDashboardScopeOption> companyOptions;
  final List<ExecutiveDashboardScopeOption> teamOptions;
  final SalesDashboardSnapshot? snapshot;

  /// Loaded independently from [snapshot] (see [SalesDashboardBloc._load]):
  /// a failed drill-down table never blocks the KPI cards, and vice-versa.
  final SalesDashboardGroupRowsStatus groupRowsStatus;
  final List<SalesDashboardGroupRow> groupRows;
  final Failure? groupRowsFailure;

  final Failure? failure;

  /// Whether the caller may pick a company/team other than their own —
  /// mirrors `ExecutiveDashboardState.canPickScope`.
  bool get canPickScope =>
      visibilityFilter?.mode ==
          ExecutiveDashboardVisibilityMode.allOrganization ||
      companyOptions.length > 1 ||
      teamOptions.isNotEmpty;

  SalesDashboardState copyWith({
    SalesDashboardStatus? status,
    String? organizationId,
    String? userId,
    ExecutiveDashboardVisibilityFilter? visibilityFilter,
    SalesDashboardFilters? filters,
    List<ExecutiveDashboardScopeOption>? companyOptions,
    List<ExecutiveDashboardScopeOption>? teamOptions,
    SalesDashboardSnapshot? snapshot,
    SalesDashboardGroupRowsStatus? groupRowsStatus,
    List<SalesDashboardGroupRow>? groupRows,
    Failure? groupRowsFailure,
    bool clearGroupRowsFailure = false,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return SalesDashboardState(
      status: status ?? this.status,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      visibilityFilter: visibilityFilter ?? this.visibilityFilter,
      filters: filters ?? this.filters,
      companyOptions: companyOptions ?? this.companyOptions,
      teamOptions: teamOptions ?? this.teamOptions,
      snapshot: snapshot ?? this.snapshot,
      groupRowsStatus: groupRowsStatus ?? this.groupRowsStatus,
      groupRows: groupRows ?? this.groupRows,
      groupRowsFailure: clearGroupRowsFailure
          ? null
          : (groupRowsFailure ?? this.groupRowsFailure),
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}
