import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
import '../../../insights/domain/entities/insight.dart';
import '../../../insights/domain/entities/insight_page.dart';
import '../../../insights/domain/usecases/list_opportunity_center_insights_use_case.dart';
import '../../../organizations/domain/entities/company.dart';
import '../../../organizations/domain/entities/team.dart';
import '../../../organizations/domain/repositories/company_repository.dart';
import '../../../organizations/domain/repositories/team_repository.dart';
import '../../domain/entities/executive_dashboard_filters.dart';
import '../../domain/entities/executive_dashboard_visibility_filter.dart';
import '../../domain/services/executive_dashboard_visibility_service.dart';
import '../../domain/usecases/load_executive_dashboard_snapshot_use_case.dart';
import 'executive_dashboard_event.dart';
import 'executive_dashboard_state.dart';

/// Drives the Executive Dashboard (TASK-134, EPIC-17): resolves which
/// companies/teams the caller may pick as scope
/// (`ExecutiveDashboardVisibilityService`, never trusted from the UI
/// alone — same two-layer shape `TargetDashboardCubit`/
/// `OpportunityCenterBloc` already use for their own visibility services),
/// then loads the KPI snapshot for the selected
/// company/team/month exclusively from `LoadExecutiveDashboardSnapshotUseCase`
/// (TASK-133's aggregation layer plus TASK-116/TASK-117's Target/
/// Positivação snapshots) — never a raw query against
/// `orders`/`customers`/`products`.
///
/// The "atalho para a Central de Oportunidades" (this task's own escopo
/// técnico) reuses `ListOpportunityCenterInsightsUseCase` — the exact same
/// RBAC-scoped read TASK-132 already validated — filtered client-side to
/// [ExecutiveDashboardFilters]' period and sorted by `estimatedImpact`,
/// never a second visibility rule reimplemented here.
@injectable
final class ExecutiveDashboardBloc
    extends Bloc<ExecutiveDashboardEvent, ExecutiveDashboardState> {
  ExecutiveDashboardBloc(
    this._visibilityService,
    this._loadSnapshot,
    this._companyRepository,
    this._teamRepository,
    this._listOpportunityCenterInsights,
    this._analyticsService,
  ) : super(const ExecutiveDashboardState()) {
    on<ExecutiveDashboardStarted>(_onStarted);
    on<ExecutiveDashboardFiltersChanged>(_onFiltersChanged);
    on<ExecutiveDashboardRetried>(_onRetried);
  }

  /// How many of the top-impact insights of the filtered period are shown
  /// in the "atalho" widget — enough for a glanceable shortlist, never a
  /// full listing (the Central de Oportunidades itself is where a caller
  /// browses everything).
  static const int _topInsightsLimit = 5;

  /// One page of the Central de Oportunidades is enough to compute "maior
  /// impacto do período filtrado" for a shortcut widget without paginating
  /// through the whole backlog — same bound
  /// `OpportunityCenterBloc.pageSize` uses per page, just requested once.
  static const int _insightsScanLimit = 100;

  final ExecutiveDashboardVisibilityService _visibilityService;
  final LoadExecutiveDashboardSnapshotUseCase _loadSnapshot;
  final CompanyRepository _companyRepository;
  final TeamRepository _teamRepository;
  final ListOpportunityCenterInsightsUseCase _listOpportunityCenterInsights;
  final AnalyticsService _analyticsService;

  List<Team> _teams = const <Team>[];

  Future<void> _onStarted(
    ExecutiveDashboardStarted event,
    Emitter<ExecutiveDashboardState> emit,
  ) async {
    emit(
      ExecutiveDashboardState(
        status: ExecutiveDashboardStatus.loading,
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
        state.copyWith(
          status: ExecutiveDashboardStatus.error,
          failure: failure,
        ),
      );
      return;
    }
    final visibility =
        (visibilityResult as AppSuccess<ExecutiveDashboardVisibilityFilter>)
            .value;
    emit(state.copyWith(visibilityFilter: visibility));

    if (!visibility.canViewAny) {
      emit(state.copyWith(status: ExecutiveDashboardStatus.forbidden));
      return;
    }

    final companiesResult = await _companyRepository.listByOrganization(
      event.organizationId,
    );
    if (companiesResult case AppFailure<List<Company>>(
      failure: final failure,
    )) {
      emit(
        state.copyWith(
          status: ExecutiveDashboardStatus.error,
          failure: failure,
        ),
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
        state.copyWith(
          status: ExecutiveDashboardStatus.error,
          failure: failure,
        ),
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

    await _load(effectiveFilters, emit);
  }

  Future<void> _onFiltersChanged(
    ExecutiveDashboardFiltersChanged event,
    Emitter<ExecutiveDashboardState> emit,
  ) async {
    final visibility = state.visibilityFilter;
    if (visibility == null || !visibility.canViewAny) return;
    if (!visibility.canViewCompany(event.filters.companyId)) return;
    final teamId = event.filters.teamId;
    if (teamId != null && !visibility.canViewTeam(teamId)) return;

    emit(
      state.copyWith(
        status: ExecutiveDashboardStatus.loading,
        filters: event.filters,
        teamOptions: _teamOptionsFor(event.filters.companyId),
      ),
    );
    await _load(event.filters, emit);
  }

  Future<void> _onRetried(
    ExecutiveDashboardRetried event,
    Emitter<ExecutiveDashboardState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ExecutiveDashboardStatus.loading,
        clearFailure: true,
      ),
    );
    await _load(state.filters, emit);
  }

  List<ExecutiveDashboardScopeOption> _teamOptionsFor(String companyId) {
    return <ExecutiveDashboardScopeOption>[
      for (final team in _teams)
        if (team.companyId == null || team.companyId == companyId)
          ExecutiveDashboardScopeOption(id: team.id, name: team.name),
    ];
  }

  Future<void> _load(
    ExecutiveDashboardFilters filters,
    Emitter<ExecutiveDashboardState> emit,
  ) async {
    final teamId = filters.teamId;
    final teamMemberIds = teamId == null
        ? const <String>[]
        : _teams
              .where((team) => team.id == teamId)
              .expand((team) => team.memberIds)
              .toSet()
              .toList(growable: false);

    final snapshotResult = await _loadSnapshot(
      organizationId: state.organizationId,
      filters: filters,
      teamMemberIds: teamMemberIds,
    );
    if (emit.isDone) return;

    switch (snapshotResult) {
      case AppFailure(failure: final failure):
        emit(
          state.copyWith(
            status: ExecutiveDashboardStatus.error,
            failure: failure,
          ),
        );
        return;
      case AppSuccess(value: final snapshot):
        emit(
          state.copyWith(
            status: ExecutiveDashboardStatus.ready,
            snapshot: snapshot,
            clearFailure: true,
          ),
        );
    }

    await _loadTopInsights(filters, emit);

    unawaited(
      _analyticsService.logEvent(
        AnalyticsEvents.dashboardViewed,
        parameters: <String, Object?>{
          'organization_id': state.organizationId,
          'dashboard_type': 'executive',
          'company_id': filters.companyId,
          'team_id': filters.teamId,
          'month': filters.monthKey,
        },
      ),
    );
  }

  /// Loaded after the main KPI snapshot is already emitted (a slower/failed
  /// insights read never blocks the KPIs the caller is here for) but still
  /// awaited within the same event handler/[Emitter] — `Bloc.emit` may only
  /// ever be called from inside a registered handler, never fire-and-forget
  /// from a detached `Future`.
  Future<void> _loadTopInsights(
    ExecutiveDashboardFilters filters,
    Emitter<ExecutiveDashboardState> emit,
  ) async {
    final result = await _listOpportunityCenterInsights(
      organizationId: state.organizationId,
      companyId: filters.companyId,
      userId: state.userId,
      limit: _insightsScanLimit,
    );
    if (emit.isDone) return;
    if (result case AppFailure<InsightPage>()) {
      emit(state.copyWith(topInsights: const <Insight>[]));
      return;
    }
    final page = (result as AppSuccess<InsightPage>).value;
    final withinPeriod =
        page.insights
            .where(
              (insight) =>
                  !insight.generatedAt.isBefore(filters.periodStart) &&
                  insight.generatedAt.isBefore(filters.periodEnd),
            )
            .toList(growable: false)
          ..sort((a, b) => _impactScore(b).compareTo(_impactScore(a)));
    emit(
      state.copyWith(
        topInsights: withinPeriod
            .take(_topInsightsLimit)
            .toList(growable: false),
      ),
    );
  }

  double _impactScore(Insight insight) {
    return insight.estimatedImpact.amount ??
        insight.estimatedImpact.percentage ??
        0;
  }
}
