import '../../features/organizations/domain/value_objects/system_role_name.dart';
import 'capability.dart';

/// Data-driven RBAC matrix (`tasks.md`, seção 3.3): exactly which
/// [Capability]s each of VestiPro's 7 built-in [SystemRoleName] roles is
/// granted. Kept as a single, auditable, testable table — per AGENTS.md
/// ("Regras De Implementação"), no other code in the app may reimplement
/// this decision with a scattered `if (role == ...)`.
///
/// [SystemRoleName.owner] is always resolved as the full [Capability.values]
/// set, so it is guaranteed — by construction, not by manual enumeration —
/// to be a superset of every other role, including
/// [SystemRoleName.admin] (which has every capability except
/// [Capability.organizationTransferOwnership]).
/// [SystemRoleName.readOnly] is deliberately mapped to an empty set: it
/// never has a single write/delete/approve capability.
///
/// Custom (non-system) roles — future work, see `Role.isSystemRole` — are
/// not modeled by this table yet: [capabilitiesForRoleName] returns an
/// empty (default-deny) set for any role name outside [SystemRoleName],
/// since `Role` does not persist its own capability list yet.
abstract final class RolePermissionMatrix {
  static final Set<Capability> _ownerCapabilities =
      Set<Capability>.unmodifiable(Capability.values);

  static final Set<Capability> _adminCapabilities =
      Set<Capability>.unmodifiable(
        Capability.values.where(
          (capability) =>
              capability != Capability.organizationTransferOwnership,
        ),
      );

  static const Set<Capability> _salesManagerCapabilities = <Capability>{
    Capability.customerView,
    Capability.customerCreate,
    Capability.customerUpdate,
    Capability.customerDelete,
    Capability.leadView,
    Capability.leadCreate,
    Capability.leadQualify,
    Capability.opportunityView,
    Capability.opportunityManage,
    Capability.pipelineStageManage,
    Capability.orderCreate,
    Capability.orderView,
    Capability.orderApprove,
    Capability.discountApproveAboveLimit,
    Capability.teamManage,
    Capability.reportExport,
    Capability.reportViewSensitive,
    // TASK-115: SALES_MANAGER cadastra/edita metas para sua equipe; OWNER
    // and ADMIN already get it via the full/near-full capability set above.
    Capability.targetManage,
    // TASK-116: SALES_MANAGER acompanha o dashboard de atingimento da
    // própria meta e da equipe.
    Capability.targetView,
    // TASK-132: SALES_MANAGER acessa a Central de Oportunidades para a
    // própria carteira e a de sua equipe.
    Capability.insightView,
    // TASK-145: SALES_MANAGER compartilha uma visualização salva com a
    // própria equipe ou com toda a organização.
    Capability.reportShareTeam,
    Capability.reportShareOrganization,
  };

  static const Set<Capability> _salesRepCapabilities = <Capability>{
    Capability.customerView,
    Capability.customerCreate,
    Capability.customerUpdate,
    Capability.leadView,
    Capability.leadCreate,
    Capability.leadQualify,
    Capability.opportunityView,
    Capability.opportunityManage,
    Capability.orderCreate,
    Capability.orderView,
    // TASK-116: SALES_REP acompanha o dashboard de atingimento da própria
    // meta.
    Capability.targetView,
    // TASK-132: SALES_REP acessa a Central de Oportunidades para a própria
    // carteira.
    Capability.insightView,
    // TASK-145: SALES_REP compartilha uma visualização salva no máximo com a
    // própria equipe — nunca com toda a organização
    // (Capability.reportShareOrganization, deliberadamente ausente aqui).
    Capability.reportShareTeam,
  };

  static const Set<Capability> _salesAssistantCapabilities = <Capability>{
    Capability.customerCreate,
    Capability.customerUpdate,
    Capability.leadCreate,
  };

  static const Set<Capability> _financeCapabilities = <Capability>{
    Capability.financeView,
    Capability.financeManage,
    Capability.discountApproveAboveLimit,
    Capability.reportExport,
    Capability.reportViewSensitive,
    Capability.leadView,
    // TASK-083: Price List management is restricted to OWNER/ADMIN/FINANCE
    // — OWNER and ADMIN already get it via the full/near-full capability
    // set above, FINANCE needs it added explicitly here.
    Capability.priceListManage,
    // TASK-145: FINANCE compartilha uma visualização salva com a própria
    // equipe ou com toda a organização, mesma amplitude de report.* já
    // concedida acima.
    Capability.reportShareTeam,
    Capability.reportShareOrganization,
  };

  static const Set<Capability> _readOnlyCapabilities = <Capability>{};

  static Map<SystemRoleName, Set<Capability>> get _byRole => {
    SystemRoleName.owner: _ownerCapabilities,
    SystemRoleName.admin: _adminCapabilities,
    SystemRoleName.salesManager: _salesManagerCapabilities,
    SystemRoleName.salesRep: _salesRepCapabilities,
    SystemRoleName.salesAssistant: _salesAssistantCapabilities,
    SystemRoleName.finance: _financeCapabilities,
    SystemRoleName.readOnly: _readOnlyCapabilities,
  };

  /// Every [Capability] granted to [role] — the single source of truth an
  /// audit screen (or a test) can use to answer "what exactly can this role
  /// do".
  static Set<Capability> capabilitiesFor(SystemRoleName role) {
    return _byRole[role] ?? const <Capability>{};
  }

  /// Same as [capabilitiesFor], but resolved directly from the raw
  /// [Membership.roleName]/`Role.name` string as stored in Firestore (e.g.
  /// `'OWNER'`), so callers holding a live Membership never need to parse it
  /// into a [SystemRoleName] themselves. Unknown/custom role names resolve
  /// to an empty, default-deny set (see class docs).
  static Set<Capability> capabilitiesForRoleName(String roleName) {
    for (final role in SystemRoleName.values) {
      if (role.code == roleName) return capabilitiesFor(role);
    }
    return const <Capability>{};
  }

  /// Convenience predicate equivalent to
  /// `capabilitiesFor(role).contains(capability)`.
  static bool hasCapability(SystemRoleName role, Capability capability) {
    return capabilitiesFor(role).contains(capability);
  }
}
