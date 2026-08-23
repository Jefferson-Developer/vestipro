enum CustomerVisibilityMode { allOrganization, teams, ownCustomers, none }

/// Query contract that TASK-051 must consume when implementing Customer.
///
/// Customer documents must live at `organizations/{organizationId}/customers`
/// and expose these denormalized fields for both client queries and Firestore
/// Rules:
///
/// - `organizationId`: same id as the path tenant.
/// - `companyId`: active company scope.
/// - `primarySalesRepId`: one primary seller; shared portfolio is unsupported.
/// - `teamId`: primary commercial team responsible for the customer.
/// - `deletedAt`: nullable soft-delete marker.
///
/// TASK-051's CustomerRepository must translate this filter as:
///
/// - Always: query by `companyId` and `deletedAt == null`.
/// - [CustomerVisibilityMode.allOrganization]: no additional visibility filter.
/// - [CustomerVisibilityMode.teams]: add `teamId in`.
/// - [CustomerVisibilityMode.ownCustomers]: query by `companyId` and
///   `primarySalesRepId == userId`.
/// - [CustomerVisibilityMode.none]: do not query.
final class CustomerVisibilityFilter {
  const CustomerVisibilityFilter({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.mode,
    this.teamIds = const <String>{},
  });

  const CustomerVisibilityFilter.none({
    required this.organizationId,
    required this.companyId,
    required this.userId,
  }) : mode = CustomerVisibilityMode.none,
       teamIds = const <String>{};

  final String organizationId;
  final String companyId;
  final String userId;
  final CustomerVisibilityMode mode;
  final Set<String> teamIds;

  bool get canReadAny => mode != CustomerVisibilityMode.none;

  bool get requiresActiveCustomerFilter => canReadAny;

  bool get requiresPrimarySalesRepFilter =>
      mode == CustomerVisibilityMode.ownCustomers;

  bool get requiresTeamFilter => mode == CustomerVisibilityMode.teams;
}
