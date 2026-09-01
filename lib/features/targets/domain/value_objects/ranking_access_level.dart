import '../entities/target_visibility_filter.dart';
import 'ranking_visibility_mode.dart';

/// How much of a resolved ranking board the current caller may actually see,
/// combining two independent decisions (TASK-118, EPIC-15):
///
/// - **Who** the caller is: [TargetVisibilityMode] (TASK-116) already knows
///   whether the caller is an OWNER/ADMIN, a SALES_MANAGER or a SALES_REP.
/// - **What** the organization configured: [RankingVisibilityMode]
///   ([RankingVisibilityMode.fullRanking]/
///   [RankingVisibilityMode.relativePositionOnly]).
///
/// A `SALES_MANAGER`/`ADMIN`/`OWNER` ([TargetVisibilityMode.teams]/
/// [TargetVisibilityMode.allOrganization]) always resolves to [full] — the
/// task's RBAC rule is unconditional for those roles ("SALES_MANAGER/ADMIN
/// veem o ranking completo da equipe/empresa sob sua gestão"), the
/// organization setting never narrows it further. Only a `SALES_REP`
/// ([TargetVisibilityMode.ownOnly]) is subject to [RankingVisibilityMode].
/// [TargetVisibilityMode.none] never reaches [resolve] at all —
/// `RankingDashboardCubit` gates on [TargetVisibilityFilter.canViewAny]
/// first, exactly like `TargetDashboardCubit`/`PositivacaoDashboardCubit` do.
enum RankingAccessLevel {
  /// Every ranked peer's name and value are visible, in rank order.
  full,

  /// Only the caller's own entry (if ranked) is visible, alongside their
  /// rank and the total number of ranked peers — never another peer's name
  /// or value.
  relativePositionOnly;

  /// Resolves the [RankingAccessLevel] a caller in [mode] gets under
  /// [organizationSetting]. This is the single seam that decides whether
  /// `RankingCalculationService.compute` redacts peer data — never left to
  /// the UI to hide after the fact, per the task's own "validado na camada
  /// de aplicação/backend, não apenas ocultado na UI" rule.
  static RankingAccessLevel resolve({
    required TargetVisibilityMode mode,
    required RankingVisibilityMode organizationSetting,
  }) {
    if (mode != TargetVisibilityMode.ownOnly) {
      // allOrganization / teams: managers and admins always get the full
      // ranking of their scope, regardless of the organization setting.
      return RankingAccessLevel.full;
    }
    return organizationSetting == RankingVisibilityMode.fullRanking
        ? RankingAccessLevel.full
        : RankingAccessLevel.relativePositionOnly;
  }
}
