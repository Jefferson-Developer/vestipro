import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
import '../../../organizations/organizations.dart';
import '../../domain/entities/ranking_participant.dart';
import '../../domain/entities/ranking_peer_scope.dart';
import '../../domain/entities/ranking_period_window.dart';
import '../../domain/entities/target.dart';
import '../../domain/entities/target_visibility_filter.dart';
import '../../domain/repositories/target_achievement_repository.dart';
import '../../domain/repositories/target_repository.dart';
import '../../domain/services/ranking_calculation_service.dart';
import '../../domain/services/ranking_peer_resolver_service.dart';
import '../../domain/services/target_visibility_service.dart';
import '../../domain/value_objects/ranking_access_level.dart';
import '../../domain/value_objects/ranking_dimension_type.dart';
import '../../domain/value_objects/ranking_visibility_mode.dart';
import '../../domain/value_objects/target_metric_type.dart';
import 'ranking_dashboard_state.dart';

/// Drives the ranking comercial dashboard (TASK-118, EPIC-15): resolves the
/// caller's dimension visibility (`TargetVisibilityService`, reused verbatim
/// from TASK-116, never re-implemented), resolves *who the peers are*
/// (`RankingPeerResolverService`, the RBAC-critical boundary this task
/// adds), lists every distinct period window found among those peers'
/// `Target`s for the selected dimension/metric, and computes the
/// already-redacted `RankingBoard` for the selected window
/// (`RankingCalculationService`) from the exact same achievement source
/// TASK-116's dashboard reads (`TargetAchievementRepository`, backed by
/// `TargetsTable.achievedValueCache`) — never a client-side sum of raw order
/// documents, and never diverging from the achievement dashboard's numbers.
@injectable
final class RankingDashboardCubit extends Cubit<RankingDashboardState> {
  RankingDashboardCubit(
    this._visibilityService,
    this._peerResolverService,
    this._getOrganizationUseCase,
    this._targetRepository,
    this._achievementRepository,
    this._membershipRepository,
    this._teamRepository,
    this._calculationService,
    this._analyticsService,
  ) : super(const RankingDashboardState());

  final TargetVisibilityService _visibilityService;
  final RankingPeerResolverService _peerResolverService;
  final GetOrganizationUseCase _getOrganizationUseCase;
  final TargetRepository _targetRepository;
  final TargetAchievementRepository _achievementRepository;
  final MembershipRepository _membershipRepository;
  final TeamRepository _teamRepository;
  final RankingCalculationService _calculationService;
  final AnalyticsService _analyticsService;

  /// The caller's own `Membership.teamIds`, resolved once at [load] time —
  /// only ever used to highlight the caller's own team when ranking by
  /// [RankingDimensionType.team]; never used for any RBAC decision (that is
  /// entirely [TargetVisibilityFilter]/`RankingPeerResolverService`'s job).
  List<String> _callerTeamIds = const <String>[];

  /// Every peer `Target` loaded for the current dimension/metric selection,
  /// across every period — kept only to slice by [RankingPeriodWindow] on
  /// `selectPeriod` without a second round trip to [_targetRepository].
  List<Target> _peerTargets = const <Target>[];

  /// Resolves visibility, the organization's [RankingVisibilityMode] and the
  /// caller's own Membership, then loads the default `salesRep` ranking —
  /// the "meu ranking" landing view every role that can reach this page at
  /// all is guaranteed to be allowed to see (a SALES_REP's own peer group).
  Future<void> load({
    required String organizationId,
    required String companyId,
    required String userId,
  }) async {
    emit(
      state.copyWith(
        status: RankingDashboardStatus.loading,
        organizationId: organizationId,
        companyId: companyId,
        userId: userId,
      ),
    );

    final filterResult = await _visibilityService.resolve(
      organizationId: organizationId,
      companyId: companyId,
      userId: userId,
    );
    if (filterResult case AppFailure<TargetVisibilityFilter>(
      failure: final failure,
    )) {
      emit(
        state.copyWith(
          status: RankingDashboardStatus.error,
          failureMessage: failure.message,
        ),
      );
      return;
    }
    final filter = (filterResult as AppSuccess<TargetVisibilityFilter>).value;
    emit(state.copyWith(visibilityFilter: filter));

    if (!filter.canViewAny) {
      emit(state.copyWith(status: RankingDashboardStatus.forbidden));
      return;
    }

    final organizationResult = await _getOrganizationUseCase(organizationId);
    if (organizationResult case AppFailure<Organization>(
      failure: final failure,
    )) {
      emit(
        state.copyWith(
          status: RankingDashboardStatus.error,
          failureMessage: failure.message,
        ),
      );
      return;
    }
    final organization = (organizationResult as AppSuccess<Organization>).value;
    final rankingVisibilityMode =
        RankingVisibilityMode.fromOrganizationSettings(organization.settings);
    emit(state.copyWith(rankingVisibilityMode: rankingVisibilityMode));

    final membershipResult = await _membershipRepository.getByUser(
      organizationId: organizationId,
      userId: userId,
    );
    if (membershipResult case AppSuccess<Membership>(value: final membership)) {
      _callerTeamIds = membership.teamIds;
    }

    await selectDimension(
      dimensionType: RankingDimensionType.salesRep,
      metricType: state.metricType,
    );
  }

  /// Switches the ranking to [dimensionType]/[metricType], re-resolving the
  /// peer scope every time — never assuming the UI already hid an option the
  /// caller cannot reach.
  Future<void> selectDimension({
    required RankingDimensionType dimensionType,
    TargetMetricType? metricType,
  }) async {
    final filter = state.visibilityFilter;
    if (filter == null) return;
    final effectiveMetric = metricType ?? state.metricType;

    if (dimensionType == RankingDimensionType.team &&
        filter.mode == TargetVisibilityMode.ownOnly) {
      emit(
        state.copyWith(
          status: RankingDashboardStatus.forbidden,
          dimensionType: dimensionType,
          metricType: effectiveMetric,
          periodCandidates: const <RankingPeriodWindow>[],
          clearSelectedPeriod: true,
          clearBoard: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: RankingDashboardStatus.loading,
        dimensionType: dimensionType,
        metricType: effectiveMetric,
      ),
    );

    final peerScopeResult = await _peerResolverService.resolve(
      organizationId: state.organizationId,
      userId: state.userId,
      dimensionType: dimensionType,
      visibilityFilter: filter,
    );
    if (peerScopeResult case AppFailure<RankingPeerScope>(
      failure: final failure,
    )) {
      emit(
        state.copyWith(
          status: RankingDashboardStatus.error,
          failureMessage: failure.message,
        ),
      );
      return;
    }
    final peerScope = (peerScopeResult as AppSuccess<RankingPeerScope>).value;

    if (peerScope.isEmpty) {
      _peerTargets = const <Target>[];
      emit(
        state.copyWith(
          status: RankingDashboardStatus.empty,
          periodCandidates: const <RankingPeriodWindow>[],
          clearSelectedPeriod: true,
          clearBoard: true,
        ),
      );
      return;
    }

    final targets = <Target>[];
    for (final peerId in peerScope.peerIds) {
      final targetsResult = await _targetRepository.listByDimension(
        organizationId: state.organizationId,
        dimensionType: dimensionType.asTargetDimensionType,
        dimensionId: peerId,
        metricType: effectiveMetric,
      );
      if (targetsResult case AppSuccess<List<Target>>(
        value: final peerTargets,
      )) {
        targets.addAll(peerTargets.where((target) => target.deletedAt == null));
      }
      // A single peer's lookup failure (e.g. transient offline read) never
      // aborts the whole ranking — it simply means that peer has no
      // candidate `Target` this pass, same best-effort resilience
      // `PositivacaoDashboardCubit` already applies to pending-customer
      // label resolution.
    }
    _peerTargets = targets;

    if (targets.isEmpty) {
      emit(
        state.copyWith(
          status: RankingDashboardStatus.empty,
          periodCandidates: const <RankingPeriodWindow>[],
          clearSelectedPeriod: true,
          clearBoard: true,
        ),
      );
      return;
    }

    final periodCandidates = _distinctWindows(targets);
    emit(state.copyWith(periodCandidates: periodCandidates));

    unawaited(
      _analyticsService.logEvent(
        AnalyticsEvents.rankingDashboardViewed,
        parameters: <String, Object?>{
          'organization_id': state.organizationId,
          'company_id': state.companyId,
          'dimension_type': dimensionType.name,
          'metric_type': effectiveMetric.name,
        },
      ),
    );

    await selectPeriod(_pickDefaultWindow(periodCandidates));
  }

  /// Switches to [window] (the "filtro por período"), recomputing the
  /// `RankingBoard` for every peer `Target` already loaded that falls in
  /// that exact window.
  Future<void> selectPeriod(RankingPeriodWindow window) async {
    emit(
      state.copyWith(
        status: RankingDashboardStatus.loading,
        selectedPeriod: window,
        clearBoard: true,
      ),
    );

    final targetsInWindow = _peerTargets
        .where((target) => window.matches(target.startDate, target.endDate))
        .toList(growable: false);

    if (targetsInWindow.isEmpty) {
      emit(state.copyWith(status: RankingDashboardStatus.empty));
      return;
    }

    final dimensionType = state.dimensionType;
    final displayNames = await _resolveDisplayNames(
      dimensionType,
      targetsInWindow.map((target) => target.dimensionId).toSet(),
    );

    final participants = <RankingParticipant>[];
    for (final target in targetsInWindow) {
      final achievementResult = await _achievementRepository.getForTarget(
        organizationId: target.organizationId,
        targetId: target.id,
      );
      final realizedValue = achievementResult.fold(
        onSuccess: (snapshot) => snapshot.realizedValue,
        onFailure: (_) => null,
      );
      participants.add(
        RankingParticipant(
          dimensionId: target.dimensionId,
          displayName: displayNames[target.dimensionId] ?? target.dimensionId,
          targetValue: target.targetValue,
          realizedValue: realizedValue,
        ),
      );
    }

    final filter = state.visibilityFilter;
    final accessLevel = filter == null
        ? RankingAccessLevel.relativePositionOnly
        : RankingAccessLevel.resolve(
            mode: filter.mode,
            organizationSetting: state.rankingVisibilityMode,
          );

    final currentUserDimensionId =
        dimensionType == RankingDimensionType.salesRep
        ? state.userId
        : _callerTeamIds.cast<String?>().firstWhere(
                (teamId) => participants.any(
                  (participant) => participant.dimensionId == teamId,
                ),
                orElse: () => null,
              ) ??
              '';

    final board = _calculationService.compute(
      participants: participants,
      currentUserDimensionId: currentUserDimensionId,
      accessLevel: accessLevel,
    );

    emit(
      state.copyWith(
        status: board.isEmpty
            ? RankingDashboardStatus.notCalculated
            : RankingDashboardStatus.ready,
        board: board,
      ),
    );
  }

  /// Changes only the display order the ranked entries render in
  /// ([RankingDashboardState.sortedEntriesForDisplay]) — never re-fetches
  /// nor re-ranks the underlying [RankingDashboardState.board].
  void sortBy(RankingSortCriterion criterion) {
    emit(state.copyWith(sortCriterion: criterion));
  }

  Future<Map<String, String>> _resolveDisplayNames(
    RankingDimensionType dimensionType,
    Set<String> ids,
  ) async {
    switch (dimensionType) {
      case RankingDimensionType.salesRep:
        final result = await _membershipRepository.listByOrganization(
          state.organizationId,
        );
        return result.fold(
          onSuccess: (memberships) => <String, String>{
            for (final membership in memberships)
              if (ids.contains(membership.userId))
                membership.userId: (membership.name?.trim().isNotEmpty ?? false)
                    ? membership.name!.trim()
                    : membership.userId,
          },
          onFailure: (_) => const <String, String>{},
        );
      case RankingDimensionType.team:
        final result = await _teamRepository.listByOrganization(
          state.organizationId,
        );
        return result.fold(
          onSuccess: (teams) => <String, String>{
            for (final team in teams)
              if (ids.contains(team.id)) team.id: team.name,
          },
          onFailure: (_) => const <String, String>{},
        );
    }
  }

  List<RankingPeriodWindow> _distinctWindows(List<Target> targets) {
    final seen = <RankingPeriodWindow, bool>{};
    final windows = <RankingPeriodWindow>[];
    for (final target in targets) {
      final window = RankingPeriodWindow(
        start: target.startDate,
        end: target.endDate,
      );
      if (seen.containsKey(window)) continue;
      seen[window] = true;
      windows.add(window);
    }
    windows.sort((a, b) => a.start.compareTo(b.start));
    return windows;
  }

  /// Picks the period window a caller most likely wants to see by default:
  /// the one currently in progress, else the most recently ended one, else
  /// the soonest upcoming one — same heuristic
  /// `TargetDashboardCubit._pickDefaultTarget` (TASK-116) already
  /// established, applied to windows shared by many peers instead of one
  /// dimension's own `Target` list.
  RankingPeriodWindow _pickDefaultWindow(List<RankingPeriodWindow> windows) {
    final now = DateTime.now().toUtc();

    for (final window in windows) {
      if (!now.isBefore(window.start) && now.isBefore(window.end)) {
        return window;
      }
    }

    RankingPeriodWindow? mostRecentlyEnded;
    for (final window in windows) {
      if (!now.isBefore(window.end)) {
        mostRecentlyEnded = window;
      }
    }
    if (mostRecentlyEnded != null) return mostRecentlyEnded;

    return windows.first;
  }
}
