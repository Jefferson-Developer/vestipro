/// How much of an organization's `Insight` set the caller may view on the
/// Central de Oportunidades (TASK-132, EPIC-16): "vendedor vê insights da
/// própria carteira; gestor vê da equipe; admin vê da organização".
enum InsightVisibilityMode {
  /// OWNER/ADMIN: every `Insight` of the tenant, regardless of
  /// `recipientUserId`.
  allOrganization,

  /// SALES_MANAGER: their own `recipientUserId` plus every teammate's,
  /// resolved from [InsightVisibilityFilter.teamMemberIds].
  teams,

  /// SALES_REP: only their own `recipientUserId`.
  ownOnly,

  /// No Membership, inactive Membership, or a role without
  /// `Capability.insightView` — the caller may see nothing.
  none,
}

/// Resolved visibility scope `OpportunityCenterBloc` must check before
/// listing `Insight`s — Firestore Security Rules must independently
/// re-verify the same decision once insights get a real Security Rules
/// pass, never trusting this filter as the sole authorization (same
/// disclaimer `CustomerVisibilityFilter`/`TargetVisibilityFilter` already
/// carry).
final class InsightVisibilityFilter {
  const InsightVisibilityFilter({
    required this.organizationId,
    required this.userId,
    required this.mode,
    this.teamMemberIds = const <String>{},
  });

  const InsightVisibilityFilter.none({
    required this.organizationId,
    required this.userId,
  }) : mode = InsightVisibilityMode.none,
       teamMemberIds = const <String>{};

  final String organizationId;
  final String userId;
  final InsightVisibilityMode mode;

  /// Only meaningful when [mode] is [InsightVisibilityMode.teams]: every
  /// teammate id resolved from the manager's visible `Team.memberIds`
  /// (excluding the manager's own [userId], added separately by
  /// [recipientUserIds]).
  final Set<String> teamMemberIds;

  bool get canViewAny => mode != InsightVisibilityMode.none;

  /// The `Insight.recipientUserId` set the caller may query, or `null`
  /// meaning "no recipient filter" (every recipient in the organization —
  /// only for [InsightVisibilityMode.allOrganization]).
  Set<String>? get recipientUserIds {
    return switch (mode) {
      InsightVisibilityMode.allOrganization => null,
      InsightVisibilityMode.teams => <String>{userId, ...teamMemberIds},
      InsightVisibilityMode.ownOnly => <String>{userId},
      InsightVisibilityMode.none => const <String>{},
    };
  }
}
