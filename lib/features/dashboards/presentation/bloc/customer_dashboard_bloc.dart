import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
import '../../../organizations/domain/entities/company.dart';
import '../../../organizations/domain/entities/team.dart';
import '../../../organizations/domain/repositories/company_repository.dart';
import '../../../organizations/domain/repositories/team_repository.dart';
import '../../domain/entities/customer_dashboard_filters.dart';
import '../../domain/entities/executive_dashboard_visibility_filter.dart';
import '../../domain/services/executive_dashboard_visibility_service.dart';
import '../../domain/usecases/load_customer_dashboard_ranking_use_case.dart';
import '../../domain/usecases/load_customer_dashboard_snapshot_use_case.dart';
import 'customer_dashboard_event.dart';
import 'customer_dashboard_state.dart';
import 'executive_dashboard_state.dart' show ExecutiveDashboardScopeOption;

/// Drives the Customer Dashboard (TASK-136, EPIC-17): resolves which
/// companies/teams the caller may pick as scope, then loads the KPI
/// snapshot and the ranking table for the selected company/team/month
/// exclusively from [LoadCustomerDashboardSnapshotUseCase]/
/// [LoadCustomerDashboardRankingUseCase] (TASK-133's aggregation layer and
/// TASK-117's positivação layer) — never a raw query against
/// `orders`/`customers`.
///
/// **Reuses [ExecutiveDashboardVisibilityService] verbatim, deliberately not
/// a new "CustomerDashboardVisibilityService"** — same reasoning
/// `SalesDashboardBloc` already documents: every EPIC-17 dashboard reads the
/// same `report.viewSensitive`-gated aggregation collections, so duplicating
/// the company/team scoping rule here would only create a second copy to
/// keep in sync.
///
/// **Known, documented gap: SALES_REP cannot reach this dashboard today**,
/// even though this task's own "Regras de negócio" names "vendedor vê
/// apenas a própria carteira" as a requirement. Same root cause
/// `SalesDashboardBloc` already documents: `Capability.reportViewSensitive`
/// is not granted to `SALES_REP`, and the TASK-133 aggregation collections'
/// Security Rules are capability-gated only (no `scopeId` ownership check).
/// Extending seller-level access safely requires row-level Firestore Rules
/// scoping shared across every EPIC-17 dashboard — a deliberate follow-up,
/// documented in
/// `docs/tasks/TASK-136-implementar-dashboard-de-clientes-CONCLUIDA.md`.
@injectable
final class CustomerDashboardBloc
    extends Bloc<CustomerDashboardEvent, CustomerDashboardState> {
  CustomerDashboardBloc(
    this._visibilityService,
    this._loadSnapshot,
    this._loadRanking,
    this._companyRepository,
    this._teamRepository,
    this._analyticsService,
  ) : super(const CustomerDashboardState()) {
    on<CustomerDashboardStarted>(_onStarted);
    on<CustomerDashboardFiltersChanged>(_onFiltersChanged);
    on<CustomerDashboardRetried>(_onRetried);
    on<CustomerDashboardRankingRetried>(_onRankingRetried);
    on<CustomerDashboardRankingPageRequested>(_onRankingPageRequested);
  }

  final ExecutiveDashboardVisibilityService _visibilityService;
  final LoadCustomerDashboardSnapshotUseCase _loadSnapshot;
  final LoadCustomerDashboardRankingUseCase _loadRanking;
  final CompanyRepository _companyRepository;
  final TeamRepository _teamRepository;
  final AnalyticsService _analyticsService;

  List<Team> _teams = const <Team>[];

  Future<void> _onStarted(
    CustomerDashboardStarted event,
    Emitter<CustomerDashboardState> emit,
  ) async {
    emit(
      CustomerDashboardState(
        status: CustomerDashboardStatus.loading,
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
        state.copyWith(status: CustomerDashboardStatus.error, failure: failure),
      );
      return;
    }
    final visibility =
        (visibilityResult as AppSuccess<ExecutiveDashboardVisibilityFilter>)
            .value;
    emit(state.copyWith(visibilityFilter: visibility));

    if (!visibility.canViewAny) {
      emit(state.copyWith(status: CustomerDashboardStatus.forbidden));
      return;
    }

    final companiesResult = await _companyRepository.listByOrganization(
      event.organizationId,
    );
    if (companiesResult case AppFailure<List<Company>>(
      failure: final failure,
    )) {
      emit(
        state.copyWith(status: CustomerDashboardStatus.error, failure: failure),
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
        state.copyWith(status: CustomerDashboardStatus.error, failure: failure),
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
    CustomerDashboardFiltersChanged event,
    Emitter<CustomerDashboardState> emit,
  ) async {
    final visibility = state.visibilityFilter;
    if (visibility == null || !visibility.canViewAny) return;
    if (!visibility.canViewCompany(event.filters.companyId)) return;
    final teamId = event.filters.teamId;
    if (teamId != null && !visibility.canViewTeam(teamId)) return;

    emit(
      state.copyWith(
        status: CustomerDashboardStatus.loading,
        filters: event.filters,
        teamOptions: _teamOptionsFor(event.filters.companyId),
      ),
    );
    await _load(event.filters, visibility, emit);
  }

  Future<void> _onRetried(
    CustomerDashboardRetried event,
    Emitter<CustomerDashboardState> emit,
  ) async {
    final visibility = state.visibilityFilter;
    if (visibility == null) return;
    emit(
      state.copyWith(
        status: CustomerDashboardStatus.loading,
        clearFailure: true,
      ),
    );
    await _load(state.filters, visibility, emit);
  }

  Future<void> _onRankingRetried(
    CustomerDashboardRankingRetried event,
    Emitter<CustomerDashboardState> emit,
  ) async {
    final visibility = state.visibilityFilter;
    if (visibility == null) return;
    emit(
      state.copyWith(
        rankingStatus: CustomerDashboardRankingStatus.loading,
        clearRankingFailure: true,
      ),
    );
    await _loadRankingInto(state.filters, emit);
  }

  void _onRankingPageRequested(
    CustomerDashboardRankingPageRequested event,
    Emitter<CustomerDashboardState> emit,
  ) {
    if (!state.hasMoreRankingRows) return;
    final nextCount =
        state.visibleRankingCount + CustomerDashboardState.pageSize;
    emit(
      state.copyWith(
        visibleRankingCount: nextCount > state.rankingRows.length
            ? state.rankingRows.length
            : nextCount,
      ),
    );
  }

  List<ExecutiveDashboardScopeOption> _teamOptionsFor(String companyId) {
    return <ExecutiveDashboardScopeOption>[
      for (final team in _teams)
        if (team.companyId == null || team.companyId == companyId)
          ExecutiveDashboardScopeOption(id: team.id, name: team.name),
    ];
  }

  Future<void> _load(
    CustomerDashboardFilters filters,
    ExecutiveDashboardVisibilityFilter visibility,
    Emitter<CustomerDashboardState> emit,
  ) async {
    final snapshotResult = await _loadSnapshot(
      organizationId: state.organizationId,
      filters: filters,
    );
    if (emit.isDone) return;

    switch (snapshotResult) {
      case AppFailure(failure: final failure):
        emit(
          state.copyWith(
            status: CustomerDashboardStatus.error,
            failure: failure,
          ),
        );
        return;
      case AppSuccess(value: final snapshot):
        emit(
          state.copyWith(
            status: CustomerDashboardStatus.ready,
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
          'dashboard_type': 'customer',
          'company_id': filters.companyId,
          'team_id': filters.teamId,
          'month': filters.monthKey,
        },
      ),
    );

    await _loadRankingInto(filters, emit);
  }

  Future<void> _loadRankingInto(
    CustomerDashboardFilters filters,
    Emitter<CustomerDashboardState> emit,
  ) async {
    final result = await _loadRanking(
      organizationId: state.organizationId,
      filters: filters,
    );
    if (emit.isDone) return;

    switch (result) {
      case AppFailure(failure: final failure):
        emit(
          state.copyWith(
            rankingStatus: CustomerDashboardRankingStatus.error,
            rankingFailure: failure,
          ),
        );
      case AppSuccess(value: final rows):
        emit(
          state.copyWith(
            rankingStatus: CustomerDashboardRankingStatus.ready,
            rankingRows: rows,
            visibleRankingCount: CustomerDashboardState.pageSize,
            clearRankingFailure: true,
          ),
        );
    }
  }
}
