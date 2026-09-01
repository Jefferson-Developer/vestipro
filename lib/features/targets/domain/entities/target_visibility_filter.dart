import '../value_objects/target_dimension_type.dart';

/// How much of an organization's `Target` set the caller may view on the
/// achievement dashboard (TASK-116, EPIC-15: "um SALES_REP só vê a própria
/// meta e a de sua equipe se explicitamente permitido; gestor vê sua
/// equipe/empresa").
enum TargetVisibilityMode {
  /// OWNER/ADMIN: every dimension of the tenant.
  allOrganization,

  /// SALES_MANAGER: their own `salesRep` dimension, any teammate's, any of
  /// their managed [TargetVisibilityFilter.teamIds], or any
  /// company/collection/category-level goal.
  teams,

  /// SALES_REP: only their own `salesRep` dimension — the "e a de sua
  /// equipe se explicitamente permitido" carve-out has no
  /// `OrganizationSettings` toggle to read yet, same gap
  /// `Capability.targetManage`'s own docs already flag, so it is not
  /// modeled here either.
  ownOnly,

  /// No Membership, inactive Membership, or a role without
  /// `Capability.targetView` — the caller may see nothing.
  none,
}

/// Resolved visibility scope `TargetDashboardCubit` must check before
/// loading/switching to any dimension — `firestore.rules`/a future Cloud
/// Function must independently re-verify the same decision once `Target`
/// gets its Firestore-backed repository; this filter is defense-in-depth/UX
/// only, exactly like `OrderVisibilityFilter`/`CustomerVisibilityFilter`.
final class TargetVisibilityFilter {
  const TargetVisibilityFilter({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.mode,
    this.teamIds = const <String>{},
    this.teamMemberIds = const <String>{},
  });

  const TargetVisibilityFilter.none({
    required this.organizationId,
    required this.companyId,
    required this.userId,
  }) : mode = TargetVisibilityMode.none,
       teamIds = const <String>{},
       teamMemberIds = const <String>{};

  final String organizationId;
  final String companyId;
  final String userId;
  final TargetVisibilityMode mode;

  /// Only meaningful when [mode] is [TargetVisibilityMode.teams]: the
  /// `Team.id`s the caller manages/belongs to.
  final Set<String> teamIds;

  /// Only meaningful when [mode] is [TargetVisibilityMode.teams]: every
  /// seller id resolved from [teamIds]' `Team.memberIds`.
  final Set<String> teamMemberIds;

  bool get canViewAny => mode != TargetVisibilityMode.none;

  /// Whether the caller may view the achievement dashboard for
  /// [dimensionType]/[dimensionId]. Company/collection/category dimensions
  /// are never tied to one person, so any [TargetVisibilityMode.teams]
  /// caller (a manager already trusted with cross-cutting reporting
  /// capabilities) may view them; only [TargetVisibilityMode.allOrganization]
  /// may view them without being a manager.
  bool canView({
    required TargetDimensionType dimensionType,
    required String dimensionId,
  }) {
    switch (mode) {
      case TargetVisibilityMode.allOrganization:
        return true;
      case TargetVisibilityMode.teams:
        return switch (dimensionType) {
          TargetDimensionType.salesRep =>
            dimensionId == userId || teamMemberIds.contains(dimensionId),
          TargetDimensionType.team => teamIds.contains(dimensionId),
          TargetDimensionType.company ||
          TargetDimensionType.collection ||
          TargetDimensionType.category => true,
        };
      case TargetVisibilityMode.ownOnly:
        return dimensionType == TargetDimensionType.salesRep &&
            dimensionId == userId;
      case TargetVisibilityMode.none:
        return false;
    }
  }
}
