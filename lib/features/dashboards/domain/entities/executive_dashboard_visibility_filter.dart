/// How much of an organization's companies/teams the caller may pick as the
/// Executive Dashboard's scope filter (TASK-134): "usuário sem permissão de
/// visão consolidada não pode selecionar escopo além do seu próprio".
///
/// Deliberately about *which company/team the filter picker may select*,
/// never about whether the page is reachable at all — that is
/// `Capability.reportViewSensitive`'s job (the same capability
/// `firestore.rules` already requires to read any of the five TASK-133
/// aggregation collections), checked once by `ExecutiveDashboardPage`
/// exactly like `Capability.targetView`/`TargetDashboardPage` already does
/// for [TargetVisibilityFilter].
enum ExecutiveDashboardVisibilityMode {
  /// OWNER/ADMIN/FINANCE: every company and every team of the tenant is
  /// selectable — the "visão consolidada" the dashboard's own Objetivo names
  /// this screen for.
  allOrganization,

  /// SALES_MANAGER: only the company/team(s) they manage.
  ownScope,

  /// No Membership, inactive Membership, or a role without
  /// `Capability.reportViewSensitive` — the caller may see nothing (in
  /// practice unreachable, since `ExecutiveDashboardPage`'s own capability
  /// gate already blocks this role from opening the page at all; this mode
  /// exists purely as the safe, explicit default this service falls back to
  /// rather than ever inferring an allowed scope from nothing).
  none,
}

/// Resolved visibility scope `ExecutiveDashboardBloc` must check before
/// letting the company/team filter pickers select anything beyond the
/// caller's own scope — Firestore Security Rules remain the real
/// authorization for the underlying aggregation reads themselves (TASK-133:
/// `report.viewSensitive`), this filter is defense-in-depth/UX only, same
/// disclaimer `TargetVisibilityFilter`/`InsightVisibilityFilter` already
/// carry.
final class ExecutiveDashboardVisibilityFilter {
  const ExecutiveDashboardVisibilityFilter({
    required this.organizationId,
    required this.userId,
    required this.mode,
    this.allowedCompanyIds = const <String>{},
    this.allowedTeamIds = const <String>{},
  });

  const ExecutiveDashboardVisibilityFilter.none({
    required this.organizationId,
    required this.userId,
  }) : mode = ExecutiveDashboardVisibilityMode.none,
       allowedCompanyIds = const <String>{},
       allowedTeamIds = const <String>{};

  final String organizationId;
  final String userId;
  final ExecutiveDashboardVisibilityMode mode;

  /// Only meaningful when [mode] is [ExecutiveDashboardVisibilityMode
  /// .ownScope]: every `Company.id` the caller's team(s) belong to.
  final Set<String> allowedCompanyIds;

  /// Only meaningful when [mode] is [ExecutiveDashboardVisibilityMode
  /// .ownScope]: every `Team.id` the caller manages/belongs to.
  final Set<String> allowedTeamIds;

  bool get canViewAny => mode != ExecutiveDashboardVisibilityMode.none;

  bool canViewCompany(String companyId) {
    return switch (mode) {
      ExecutiveDashboardVisibilityMode.allOrganization => true,
      ExecutiveDashboardVisibilityMode.ownScope => allowedCompanyIds.contains(
        companyId,
      ),
      ExecutiveDashboardVisibilityMode.none => false,
    };
  }

  bool canViewTeam(String teamId) {
    return switch (mode) {
      ExecutiveDashboardVisibilityMode.allOrganization => true,
      ExecutiveDashboardVisibilityMode.ownScope => allowedTeamIds.contains(
        teamId,
      ),
      ExecutiveDashboardVisibilityMode.none => false,
    };
  }
}
