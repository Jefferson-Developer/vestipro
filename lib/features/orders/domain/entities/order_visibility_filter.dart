/// How much of an organization's Order collection [OrderVisibilityService]
/// resolved the caller may see (`tasks.md`, TASK-102's own "vendedor vê por
/// padrão apenas os próprios pedidos; gestores/perfis com permissão veem
/// pedidos da equipe/organização").
enum OrderVisibilityMode {
  /// OWNER/ADMIN: every Order of the company, no seller restriction.
  allCompany,

  /// SALES_MANAGER whose managed teams resolved to at least one seller:
  /// restricted to [OrderVisibilityFilter.sellerIds].
  sellerSubset,

  /// SALES_REP (or a SALES_MANAGER whose managed teams resolved to no
  /// seller at all): restricted to the caller's own orders.
  ownOnly,

  /// No Membership, inactive Membership, or a role without
  /// [Capability.orderView] — the caller may see nothing.
  none,
}

/// Resolved visibility scope [ListOrdersUseCase] must translate into the
/// [OrderListFilters.sellerIds] constraint passed down to
/// `OrderListRepository` — Firestore Security Rules independently re-verify
/// the very same decision (`canReadOrder`/`managerCanReadOrder`,
/// `firestore.rules`), so this filter is defense-in-depth/UX, never the sole
/// authorization.
final class OrderVisibilityFilter {
  const OrderVisibilityFilter({
    required this.mode,
    this.sellerIds = const <String>{},
  });

  const OrderVisibilityFilter.none()
    : mode = OrderVisibilityMode.none,
      sellerIds = const <String>{};

  final OrderVisibilityMode mode;

  /// Only meaningful when [mode] is [OrderVisibilityMode.sellerSubset] or
  /// [OrderVisibilityMode.ownOnly] (a single-element set with the caller's
  /// own id in the latter case).
  final Set<String> sellerIds;

  bool get canReadAny => mode != OrderVisibilityMode.none;
}
