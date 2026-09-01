import '../../domain/entities/ranking_board.dart';
import '../../domain/entities/ranking_entry.dart';
import '../../domain/entities/ranking_period_window.dart';
import '../../domain/entities/target_visibility_filter.dart';
import '../../domain/value_objects/ranking_dimension_type.dart';
import '../../domain/value_objects/ranking_visibility_mode.dart';
import '../../domain/value_objects/target_metric_type.dart';

enum RankingDashboardStatus {
  initial,
  loading,
  ready,

  /// Peers exist for the selected dimension/metric/period, but nobody
  /// (including the caller) has a calculated achievement yet
  /// (`RankingBoard.isEmpty`) — distinct from [empty], where there are no
  /// peers to compare against at all.
  notCalculated,

  /// No peer (including the caller) has ever set a `Target` for the
  /// selected dimension/metric — never confused with [notCalculated].
  empty,

  /// The caller is not allowed to view any ranking at all
  /// (`TargetVisibilityFilter.canViewAny == false`), or explicitly requested
  /// [RankingDimensionType.team] while restricted to
  /// [TargetVisibilityMode.ownOnly].
  forbidden,
  error,
}

/// Ranking display order the "lista ordenável" filter switches between — a
/// display-only concern: [RankingBoard.entries]' canonical `RankingEntry
/// .rank` (achievement %, then absolute value, then name, per
/// `RankingCalculationService`'s deterministic tie-break) never changes when
/// this does.
enum RankingSortCriterion { achievementPercentage, absoluteValue }

/// Drives the ranking comercial dashboard (TASK-118, EPIC-15): resolves RBAC
/// visibility/peer scope, lists the period windows available for the
/// selected dimension/metric and computes the (already-redacted)
/// `RankingBoard` for the selected one.
final class RankingDashboardState {
  const RankingDashboardState({
    this.status = RankingDashboardStatus.initial,
    this.organizationId = '',
    this.companyId = '',
    this.userId = '',
    this.visibilityFilter,
    this.rankingVisibilityMode = RankingVisibilityMode.fullRanking,
    this.dimensionType = RankingDimensionType.salesRep,
    this.metricType = TargetMetricType.revenue,
    this.periodCandidates = const <RankingPeriodWindow>[],
    this.selectedPeriod,
    this.sortCriterion = RankingSortCriterion.achievementPercentage,
    this.board,
    this.failureMessage,
  });

  final RankingDashboardStatus status;
  final String organizationId;
  final String companyId;
  final String userId;

  /// `null` only before `RankingDashboardCubit.load` resolves it for the
  /// first time.
  final TargetVisibilityFilter? visibilityFilter;

  /// The organization's configured ranking visibility rule — resolved once
  /// at `load` time, same lifecycle as [visibilityFilter].
  final RankingVisibilityMode rankingVisibilityMode;

  final RankingDimensionType dimensionType;
  final TargetMetricType metricType;

  /// Every distinct `[start, end)` window found among the compared peers'
  /// `Target`s for [dimensionType]/[metricType] — the "filtro por período"
  /// source, mirroring `TargetDashboardState.candidates`'s role for a single
  /// dimension.
  final List<RankingPeriodWindow> periodCandidates;
  final RankingPeriodWindow? selectedPeriod;

  final RankingSortCriterion sortCriterion;
  final RankingBoard? board;
  final String? failureMessage;

  /// Whether the caller may switch [dimensionType] at all — a `SALES_REP`
  /// ([TargetVisibilityMode.ownOnly]) only ever ranks `salesRep` peers, same
  /// precedent as `TargetDashboardState.canPickDimension`/
  /// `PositivacaoDashboardState.canPickDimension`.
  bool get canPickDimension =>
      visibilityFilter?.mode == TargetVisibilityMode.allOrganization ||
      visibilityFilter?.mode == TargetVisibilityMode.teams;

  bool get isBusy => status == RankingDashboardStatus.loading;

  /// [board.entries], resorted for display by [sortCriterion] — never
  /// mutates [RankingEntry.rank], only the order rows render in.
  List<RankingEntry> get sortedEntriesForDisplay {
    final entries = board?.entries ?? const <RankingEntry>[];
    final sorted = List<RankingEntry>.of(entries);
    sorted.sort((a, b) {
      return switch (sortCriterion) {
        RankingSortCriterion.achievementPercentage =>
          b.achievementPercentage.compareTo(a.achievementPercentage),
        RankingSortCriterion.absoluteValue => b.realizedValue.compareTo(
          a.realizedValue,
        ),
      };
    });
    return sorted;
  }

  RankingDashboardState copyWith({
    RankingDashboardStatus? status,
    String? organizationId,
    String? companyId,
    String? userId,
    TargetVisibilityFilter? visibilityFilter,
    RankingVisibilityMode? rankingVisibilityMode,
    RankingDimensionType? dimensionType,
    TargetMetricType? metricType,
    List<RankingPeriodWindow>? periodCandidates,
    RankingPeriodWindow? selectedPeriod,
    bool clearSelectedPeriod = false,
    RankingSortCriterion? sortCriterion,
    RankingBoard? board,
    bool clearBoard = false,
    String? failureMessage,
    bool clearFailureMessage = false,
  }) {
    return RankingDashboardState(
      status: status ?? this.status,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      visibilityFilter: visibilityFilter ?? this.visibilityFilter,
      rankingVisibilityMode:
          rankingVisibilityMode ?? this.rankingVisibilityMode,
      dimensionType: dimensionType ?? this.dimensionType,
      metricType: metricType ?? this.metricType,
      periodCandidates: periodCandidates ?? this.periodCandidates,
      selectedPeriod: clearSelectedPeriod
          ? null
          : (selectedPeriod ?? this.selectedPeriod),
      sortCriterion: sortCriterion ?? this.sortCriterion,
      board: clearBoard ? null : (board ?? this.board),
      failureMessage: clearFailureMessage
          ? null
          : (failureMessage ?? this.failureMessage),
    );
  }
}
