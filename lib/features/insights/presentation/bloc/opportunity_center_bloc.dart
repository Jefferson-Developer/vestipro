import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/insight.dart';
import '../../domain/entities/insight_page.dart';
import '../../domain/usecases/list_opportunity_center_insights_use_case.dart';
import '../../domain/usecases/update_insight_status_use_case.dart';
import '../../domain/value_objects/insight_status.dart';
import 'opportunity_center_event.dart';
import 'opportunity_center_state.dart';

/// Drives the Central de Oportunidades (TASK-132, EPIC-16): a single,
/// paginated listing aggregating every `Insight` type (TASK-122 a TASK-131)
/// the caller's RBAC/carteira scope allows, resolved once per page load by
/// [ListOpportunityCenterInsightsUseCase] (never re-implemented here —
/// scoping is entirely that use case's/`InsightVisibilityService`'s job).
///
/// Filtering by type/severity/period and sorting (impact estimado by
/// default) are pure, synchronous derivations over the already-loaded
/// [OpportunityCenterState.insights] — see
/// [OpportunityCenterState.visibleInsights] — so changing [filters] never
/// triggers a new Firestore read, exactly like
/// `CustomerPortfolioBloc`/`OrderListBloc` already do for their own client
/// filters. Only pagination (`OpportunityCenterNextPageRequested`) and the
/// initial/retry load hit [ListOpportunityCenterInsightsUseCase].
///
/// Discard/resolve ([OpportunityCenterInsightDismissed]/
/// [OpportunityCenterInsightResolved]) apply optimistically: the insight is
/// removed from [OpportunityCenterState.insights] immediately (so "insight
/// descartado não deve reaparecer no mesmo ciclo" holds instantly, without
/// waiting on the write) and kept in
/// [OpportunityCenterState.pendingUndo] until either
/// [OpportunityCenterUndoRequested] restores it or another action
/// supersedes it. If the write itself fails, the optimistic removal is
/// rolled back and the failure surfaces via [OpportunityCenterState.failure].
@injectable
final class OpportunityCenterBloc
    extends Bloc<OpportunityCenterEvent, OpportunityCenterState> {
  OpportunityCenterBloc(
    this._listOpportunityCenterInsights,
    this._updateInsightStatus,
    this._analyticsService,
  ) : super(const OpportunityCenterState()) {
    on<OpportunityCenterStarted>(_onStarted);
    on<OpportunityCenterFiltersChanged>(_onFiltersChanged);
    on<OpportunityCenterNextPageRequested>(_onNextPageRequested);
    on<OpportunityCenterRetried>(_onRetried);
    on<OpportunityCenterInsightOpened>(_onInsightOpened);
    on<OpportunityCenterActionExecuted>(_onActionExecuted);
    on<OpportunityCenterInsightDismissed>(_onInsightDismissed);
    on<OpportunityCenterInsightResolved>(_onInsightResolved);
    on<OpportunityCenterUndoRequested>(_onUndoRequested);
  }

  static const pageSize = 25;

  final ListOpportunityCenterInsightsUseCase _listOpportunityCenterInsights;
  final UpdateInsightStatusUseCase _updateInsightStatus;
  final AnalyticsService _analyticsService;

  int _requestToken = 0;

  Future<void> _onStarted(
    OpportunityCenterStarted event,
    Emitter<OpportunityCenterState> emit,
  ) async {
    emit(
      OpportunityCenterState(
        status: OpportunityCenterLoadStatus.loading,
        organizationId: event.organizationId,
        companyId: event.companyId,
        userId: event.userId,
        filters: event.filters,
      ),
    );
    await _loadFirstPage(emit);
  }

  void _onFiltersChanged(
    OpportunityCenterFiltersChanged event,
    Emitter<OpportunityCenterState> emit,
  ) {
    emit(state.copyWith(filters: event.filters));
  }

  Future<void> _onNextPageRequested(
    OpportunityCenterNextPageRequested event,
    Emitter<OpportunityCenterState> emit,
  ) async {
    if (!state.hasMore || state.isLoadingMore || state.isInitialLoading) {
      return;
    }

    final requestToken = ++_requestToken;
    emit(
      state.copyWith(
        status: OpportunityCenterLoadStatus.loadingMore,
        clearFailure: true,
      ),
    );
    final result = await _listOpportunityCenterInsights(
      organizationId: state.organizationId,
      companyId: state.companyId,
      userId: state.userId,
      limit: pageSize,
      before: state.nextCursor,
    );
    if (emit.isDone || requestToken != _requestToken) return;
    switch (result) {
      case AppSuccess<InsightPage>(value: final page):
        emit(
          state.copyWith(
            status: OpportunityCenterLoadStatus.ready,
            insights: <Insight>[...state.insights, ...page.insights],
            hasMore: page.hasMore,
            nextCursor: page.nextCursor,
            clearFailure: true,
          ),
        );
      case AppFailure<InsightPage>(failure: final failure):
        emit(
          state.copyWith(
            status: OpportunityCenterLoadStatus.ready,
            failure: failure,
          ),
        );
    }
  }

  Future<void> _onRetried(
    OpportunityCenterRetried event,
    Emitter<OpportunityCenterState> emit,
  ) async {
    emit(
      state.copyWith(
        status: OpportunityCenterLoadStatus.loading,
        insights: const <Insight>[],
        hasMore: false,
        clearNextCursor: true,
        clearFailure: true,
      ),
    );
    await _loadFirstPage(emit);
  }

  Future<void> _loadFirstPage(Emitter<OpportunityCenterState> emit) async {
    final requestToken = ++_requestToken;
    final result = await _listOpportunityCenterInsights(
      organizationId: state.organizationId,
      companyId: state.companyId,
      userId: state.userId,
      limit: pageSize,
    );
    if (emit.isDone || requestToken != _requestToken) return;
    switch (result) {
      case AppSuccess<InsightPage>(value: final page):
        emit(
          state.copyWith(
            status: OpportunityCenterLoadStatus.ready,
            insights: page.insights,
            hasMore: page.hasMore,
            nextCursor: page.nextCursor,
            clearFailure: true,
          ),
        );
      case AppFailure<InsightPage>(failure: final failure):
        emit(
          state.copyWith(
            status: OpportunityCenterLoadStatus.failure,
            insights: const <Insight>[],
            hasMore: false,
            clearNextCursor: true,
            failure: failure,
          ),
        );
    }
  }

  void _onInsightOpened(
    OpportunityCenterInsightOpened event,
    Emitter<OpportunityCenterState> emit,
  ) {
    final insight = state.insights.firstWhereOrNull(
      (item) => item.id == event.insightId,
    );
    if (insight == null) return;
    unawaited(
      _analyticsService.logEvent(
        AnalyticsEvents.insightOpened,
        parameters: <String, Object?>{
          'organization_id': state.organizationId,
          'insight_id': insight.id,
          'insight_type': insight.type.name,
        },
      ),
    );
  }

  void _onActionExecuted(
    OpportunityCenterActionExecuted event,
    Emitter<OpportunityCenterState> emit,
  ) {
    final insight = state.insights.firstWhereOrNull(
      (item) => item.id == event.insightId,
    );
    unawaited(
      _analyticsService.logEvent(
        AnalyticsEvents.insightActionClicked,
        parameters: <String, Object?>{
          'organization_id': state.organizationId,
          'insight_id': event.insightId,
          'insight_type': insight?.type.name,
          'action_type': event.action.type.name,
        },
      ),
    );
  }

  Future<void> _onInsightDismissed(
    OpportunityCenterInsightDismissed event,
    Emitter<OpportunityCenterState> emit,
  ) => _applyStatus(
    insightId: event.insightId,
    appliedStatus: InsightStatus.dismissed,
    emit: emit,
  );

  Future<void> _onInsightResolved(
    OpportunityCenterInsightResolved event,
    Emitter<OpportunityCenterState> emit,
  ) => _applyStatus(
    insightId: event.insightId,
    appliedStatus: InsightStatus.resolved,
    emit: emit,
  );

  /// Optimistically removes [insightId] from [OpportunityCenterState.insights]
  /// and stashes it in [OpportunityCenterState.pendingUndo] before
  /// persisting [appliedStatus] — "descarte com undo funcional" never waits
  /// on the round-trip write to update what the caller sees.
  Future<void> _applyStatus({
    required String insightId,
    required InsightStatus appliedStatus,
    required Emitter<OpportunityCenterState> emit,
  }) async {
    final insight = state.insights.firstWhereOrNull(
      (item) => item.id == insightId,
    );
    if (insight == null) return;

    emit(
      state.copyWith(
        insights: state.insights
            .where((item) => item.id != insightId)
            .toList(growable: false),
        pendingUndo: OpportunityCenterPendingUndo(
          insight: insight,
          previousStatus: insight.status,
          appliedStatus: appliedStatus,
        ),
      ),
    );

    final result = await _updateInsightStatus(
      organizationId: state.organizationId,
      insightId: insightId,
      status: appliedStatus,
    );
    if (emit.isDone) return;

    if (result case AppFailure<void>(failure: final failure)) {
      // The write failed — roll back the optimistic removal so the caller
      // never silently loses an insight they still cannot act on.
      final pending = state.pendingUndo;
      final stillPending = pending != null && pending.insight.id == insightId;
      emit(
        state.copyWith(
          insights: stillPending
              ? <Insight>[...state.insights, insight]
              : state.insights,
          clearPendingUndo: stillPending,
          failure: failure,
        ),
      );
    }
  }

  Future<void> _onUndoRequested(
    OpportunityCenterUndoRequested event,
    Emitter<OpportunityCenterState> emit,
  ) async {
    final pending = state.pendingUndo;
    if (pending == null || pending.insight.id != event.insightId) return;

    emit(state.copyWith(clearPendingUndo: true));

    final result = await _updateInsightStatus(
      organizationId: state.organizationId,
      insightId: pending.insight.id,
      status: pending.previousStatus,
    );
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<void>():
        emit(
          state.copyWith(
            insights: <Insight>[
              pending.insight.copyWith(status: pending.previousStatus),
              ...state.insights,
            ],
          ),
        );
      case AppFailure<void>(failure: final failure):
        emit(state.copyWith(failure: failure));
    }
  }
}
