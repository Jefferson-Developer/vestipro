import '../../../organizations/organizations.dart';

/// Organization-configurable ranking comercial visibility rule (TASK-118,
/// EPIC-15): whether a `SALES_REP` sees the full nominal ranking of their
/// peers, or only their own relative position (e.g. "você está em 4º de
/// 12"), never their peers' names or values.
///
/// This rule only ever narrows what a `SALES_REP` sees
/// (`RankingAccessLevel.resolve`'s own doc): a `SALES_MANAGER`/`ADMIN`/
/// `OWNER` always sees the full ranking of the scope they manage, regardless
/// of this setting — the task's own RBAC rule is unconditional for those
/// roles, only "SALES_REP vê apenas sua posição relativa... conforme
/// configuração da organização".
enum RankingVisibilityMode {
  /// Every caller allowed to view the ranking at all sees every peer's name
  /// and value, in rank order.
  fullRanking,

  /// A `SALES_REP` sees only their own entry (name/value are their own, so
  /// never redacted) plus their rank and the total number of ranked peers —
  /// never another peer's name or value.
  relativePositionOnly;

  /// Raw code persisted on [OrganizationSettings.rankingVisibilityMode] —
  /// kept in sync with [OrganizationSettings.validRankingVisibilityModes]).
  String get code => switch (this) {
    RankingVisibilityMode.fullRanking => 'full_ranking',
    RankingVisibilityMode.relativePositionOnly => 'relative_position_only',
  };

  /// Parses [OrganizationSettings.rankingVisibilityMode], falling back to
  /// [RankingVisibilityMode.fullRanking] for a value this feature does not
  /// recognize (e.g. a stale/corrupted document) instead of throwing — same
  /// safe-fallback technique `PositivacaoSettings
  /// .fromOrganizationSettings` already established for
  /// `positivacaoPeriodGranularity`.
  factory RankingVisibilityMode.fromOrganizationSettings(
    OrganizationSettings settings,
  ) {
    return RankingVisibilityMode.values.firstWhere(
      (value) => value.code == settings.rankingVisibilityMode,
      orElse: () => RankingVisibilityMode.fullRanking,
    );
  }
}
