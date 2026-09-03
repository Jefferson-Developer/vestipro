import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
import '../../../organizations/domain/entities/company.dart';
import '../../../organizations/domain/entities/team.dart';
import '../../../organizations/domain/repositories/company_repository.dart';
import '../../../organizations/domain/repositories/team_repository.dart';
import '../../domain/entities/executive_dashboard_visibility_filter.dart';
import '../../domain/entities/sales_dashboard_filters.dart';
import '../../domain/services/executive_dashboard_visibility_service.dart';
import '../../domain/usecases/load_sales_dashboard_group_rows_use_case.dart';
import '../../domain/usecases/load_sales_dashboard_snapshot_use_case.dart';
import '../../domain/value_objects/sales_dashboard_group_dimension.dart';
import 'executive_dashboard_state.dart' show ExecutiveDashboardScopeOption;
import 'sales_dashboard_event.dart';
import 'sales_dashboard_state.dart';

/// Drives the Sales Dashboard (TASK-135, EPIC-17): resolves which
/// companies/teams the caller may pick as scope, then loads the KPI
/// snapshot and the drill-down table for the selected company/team/month
/// exclusively from [LoadSalesDashboardSnapshotUseCase]/
/// [LoadSalesDashboardGroupRowsUseCase] (TASK-133's aggregation layer) —
/// never a raw query against `orders`.
///
/// **Reuses [ExecutiveDashboardVisibilityService] verbatim, deliberately not
/// a new "SalesDashboardVisibilityService".** Both dashboards read the exact
/// same five TASK-133 aggregation collections, gated server-side by the
/// exact same `report.viewSensitive` capability (`firestore.rules`) — the
/// company/team scoping decision ("todo mundo" para OWNER/ADMIN/FINANCE,
/// "só o próprio escopo" para SALES_MANAGER) is identical, so duplicating it
/// here would only create two copies of the same rule to keep in sync.
///
/// **Known, documented gap: SALES_REP cannot reach this dashboard today**,
/// even though this task's own Objetivo names "representantes" as an
/// audience. `Capability.reportViewSensitive` — the capability
/// `firestore.rules` requires to read any of the five TASK-133 aggregation
/// collections — is not granted to `SALES_REP` (`RolePermissionMatrix`), and
/// those collections' Security Rules are capability-gated only (no
/// `scopeId`-level ownership check, unlike `orders`' own `canReadOrder`) —
/// granting `report.viewSensitive` to `SALES_REP` today would let any sales
/// rep list every other seller's/customer's aggregated revenue org-wide, a
/// real security regression. Extending seller-level access safely requires
/// row-level Firestore Rules scoping on the TASK-133 collections themselves
/// (shared infrastructure every other EPIC-17 dashboard also reads) — a
/// deliberate follow-up task, not something to slip in silently while
/// building one dashboard screen. Documented in
/// `docs/tasks/TASK-135-implementar-dashboard-de-vendas-CONCLUIDA.md`.
@injectable
final class SalesDashboardBloc
    extends Bloc<SalesDashboardEvent, SalesDashboardState> {
  SalesDashboardBloc(
    this._visibilityService,
    this._loadSnapshot,
    this._loadGroupRows,
    this._companyRepository,
    this._teamRepository,
    this._analyticsService,
  ) : super(const SalesDashboardState()) {
    on<SalesDashboardStarted>(_onStarted);
    on<SalesDashboardFiltersChanged>(_onFiltersChanged);
    on<SalesDashboardRetried>(_onRetried);
    on<SalesDashboardGroupRowsRetried>(_onGroupRowsRetried);
  }

  final ExecutiveDashboardVisibilityService _visibilityService;
  final LoadSalesDashboardSnapshotUseCase _loadSnapshot;
  final LoadSalesDashboardGroupRowsUseCase _loadGroupRows;
  final CompanyRepository _companyRepository;
  final TeamRepository _teamRepository;
  final AnalyticsService _analyticsService;

  List<Team> _teams = const <Team>[];

  Future<void> _onStarted(
    SalesDashboardStarted event,
    Emitter<SalesDashboardState> emit,
  ) async {
    emit(
      SalesDashboardState(
        status: SalesDashboardStatus.loading,
        organizationId: event.organizationId,
        userId: event.userId,
        filters: event.initialFilters,
      ),
    );

    final visibilityResult = await _visibilityService.resolve(
      organizationId: event.organizationId,
      userId: event.userId,
    );
    if (visibilityResult case AppFailure<ExecutiveDashboardVisibilityFilter>(
      failure: final failure,
    )) {
      emit(
        state.copyWith(status: SalesDashboardStatus.error, failure: failure),
      );
      return;
    }
    final visibility =
        (visibilityResult as AppSuccess<ExecutiveDashboardVisibilityFilter>)
            .value;
    emit(state.copyWith(visibilityFilter: visibility));

    if (!visibility.canViewAny) {
      emit(state.copyWith(status: SalesDashboardStatus.forbidden));
      return;
    }

    final companiesResult = await _companyRepository.listByOrganization(
      event.organizationId,
    );
    if (companiesResult case AppFailure<List<Company>>(
      failure: final failure,
    )) {
      emit(
        state.copyWith(status: SalesDashboardStatus.error, failure: failure),
      );
      return;
    }
    final companies = (companiesResult as AppSuccess<List<Company>>).value
        .where(
          (company) =>
              company.deletedAt == null &&
              visibility.canViewCompany(company.id),
        )
        .toList(growable: false);

    final teamsResult = await _teamRepository.listByOrganization(
      event.organizationId,
    );
    if (teamsResult case AppFailure<List<Team>>(failure: final failure)) {
      emit(
        state.copyWith(status: SalesDashboardStatus.error, failure: failure),
      );
      return;
    }
    _teams = (teamsResult as AppSuccess<List<Team>>).value
        .where(
          (team) => team.deletedAt == null && visibility.canViewTeam(team.id),
        )
        .toList(growable: false);

    final companyOptions = <ExecutiveDashboardScopeOption>[
      for (final company in companies)
        ExecutiveDashboardScopeOption(id: company.id, name: company.name),
    ];

    var effectiveFilters = event.initialFilters;
    if (companies.isNotEmpty &&
        !companies.any((company) => company.id == effectiveFilters.companyId)) {
      effectiveFilters = effectiveFilters.copyWith(
        companyId: companies.first.id,
      );
    }
    if (effectiveFilters.teamId != null &&
        !_teams.any((team) => team.id == effectiveFilters.teamId)) {
      effectiveFilters = effectiveFilters.copyWith(clearTeamId: true);
    }

    emit(
      state.copyWith(
        companyOptions: companyOptions,
        teamOptions: _teamOptionsFor(effectiveFilters.companyId),
        filters: effectiveFilters,
      ),
    );

    await _load(effectiveFilters, visibility, emit);
  }

  Future<void> _onFiltersChanged(
    SalesDashboardFiltersChanged event,
    Emitter<SalesDashboardState> emit,
  ) async {
    final visibility = state.visibilityFilter;
    if (visibility == null || !visibility.canViewAny) return;
    if (!visibility.canViewCompany(event.filters.companyId)) return;
    final teamId = event.filters.teamId;
    if (teamId != null && !visibility.canViewTeam(teamId)) return;

    emit(
      state.copyWith(
        status: SalesDashboardStatus.loading,
        filters: event.filters,
        teamOptions: _teamOptionsFor(event.filters.companyId),
      ),
    );
    await _load(event.filters, visibility, emit);
  }

  Future<void> _onRetried(
    SalesDashboardRetried event,
    Emitter<SalesDashboardState> emit,
  ) async {
    final visibility = state.visibilityFilter;
    if (visibility == null) return;
    emit(
      state.copyWith(status: SalesDashboardStatus.loading, clearFailure: true),
    );
    await _load(state.filters, visibility, emit);
  }

  Future<void> _onGroupRowsRetried(
    SalesDashboardGroupRowsRetried event,
    Emitter<SalesDashboardState> emit,
  ) async {
    final visibility = state.visibilityFilter;
    if (visibility == null) return;
    emit(
      state.copyWith(
        groupRowsStatus: SalesDashboardGroupRowsStatus.loading,
        clearGroupRowsFailure: true,
      ),
    );
    await _loadGroupRowsInto(state.filters, visibility, emit);
  }

  List<ExecutiveDashboardScopeOption> _teamOptionsFor(String companyId) {
    return <ExecutiveDashboardScopeOption>[
      for (final team in _teams)
        if (team.companyId == null || team.companyId == companyId)
          ExecutiveDashboardScopeOption(id: team.id, name: team.name),
    ];
  }

  /// Every seller id the caller's currently-managed teams resolve to — the
  /// same [ExecutiveDashboardVisibilityMode.ownScope] union
  /// `ExecutiveDashboardBloc` resolves per-team, folded across every managed
  /// team at once, so a SALES_MANAGER's "por vendedor" table never lists a
  /// seller outside their own teams even with no explicit team filter
  /// applied — same defense-in-depth spirit as `OrderVisibilityService`.
  Set<String> _managedSellerIds() {
    return <String>{for (final team in _teams) ...team.memberIds};
  }

  List<String> _teamMemberIds(String? teamId) {
    if (teamId == null) return const <String>[];
    return _teams
        .where((team) => team.id == teamId)
        .expand((team) => team.memberIds)
        .toSet()
        .toList(growable: false);
  }

  Future<void> _load(
    SalesDashboardFilters filters,
    ExecutiveDashboardVisibilityFilter visibility,
    Emitter<SalesDashboardState> emit,
  ) async {
    final teamMemberIds = _teamMemberIds(filters.teamId);

    final snapshotResult = await _loadSnapshot(
      organizationId: state.organizationId,
      filters: filters,
      teamMemberIds: teamMemberIds,
    );
    if (emit.isDone) return;

    switch (snapshotResult) {
      case AppFailure(failure: final failure):
        emit(
          state.copyWith(status: SalesDashboardStatus.error, failure: failure),
        );
        return;
      case AppSuccess(value: final snapshot):
        emit(
          state.copyWith(
            status: SalesDashboardStatus.ready,
            snapshot: snapshot,
            clearFailure: true,
          ),
        );
    }

    unawaited(
      _analyticsService.logEvent(
        AnalyticsEvents.dashboardViewed,
        parameters: <String, Object?>{
          'organization_id': state.organizationId,
          'dashboard_type': 'sales',
          'company_id': filters.companyId,
          'team_id': filters.teamId,
          'month': filters.monthKey,
          'group_by': filters.groupDimension.code,
        },
      ),
    );

    await _loadGroupRowsInto(filters, visibility, emit);
  }

  Future<void> _loadGroupRowsInto(
    SalesDashboardFilters filters,
    ExecutiveDashboardVisibilityFilter visibility,
    Emitter<SalesDashboardState> emit,
  ) async {
    Set<String>? sellerScopeIds;
    if (filters.groupDimension == SalesDashboardGroupDimension.seller) {
      if (filters.teamId != null) {
        sellerScopeIds = _teamMemberIds(filters.teamId).toSet();
      } else if (visibility.mode == ExecutiveDashboardVisibilityMode.ownScope) {
        sellerScopeIds = _managedSellerIds();
      }
    }

    final result = await _loadGroupRows(
      organizationId: state.organizationId,
      filters: filters,
      sellerScopeIds: sellerScopeIds,
    );
    if (emit.isDone) return;

    switch (result) {
      case AppFailure(failure: final failure):
        emit(
          state.copyWith(
            groupRowsStatus: SalesDashboardGroupRowsStatus.error,
            groupRowsFailure: failure,
          ),
        );
      case AppSuccess(value: final rows):
        emit(
          state.copyWith(
            groupRowsStatus: SalesDashboardGroupRowsStatus.ready,
            groupRows: rows,
            clearGroupRowsFailure: true,
          ),
        );
    }
  }
}
