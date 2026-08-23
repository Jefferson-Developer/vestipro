enum PortfolioAssignmentScopeType { customer, criteria }

extension PortfolioAssignmentScopeTypeCode on PortfolioAssignmentScopeType {
  String get code {
    return switch (this) {
      PortfolioAssignmentScopeType.customer => 'customer',
      PortfolioAssignmentScopeType.criteria => 'criteria',
    };
  }

  static PortfolioAssignmentScopeType fromCode(String code) {
    return switch (code) {
      'customer' => PortfolioAssignmentScopeType.customer,
      'criteria' => PortfolioAssignmentScopeType.criteria,
      _ => throw ArgumentError.value(code, 'code', 'Unknown scope type.'),
    };
  }
}

enum PortfolioAssignmentStatus { active, reassigned, archived }

extension PortfolioAssignmentStatusCode on PortfolioAssignmentStatus {
  String get code {
    return switch (this) {
      PortfolioAssignmentStatus.active => 'active',
      PortfolioAssignmentStatus.reassigned => 'reassigned',
      PortfolioAssignmentStatus.archived => 'archived',
    };
  }

  static PortfolioAssignmentStatus fromCode(String code) {
    return switch (code) {
      'active' => PortfolioAssignmentStatus.active,
      'reassigned' => PortfolioAssignmentStatus.reassigned,
      'archived' => PortfolioAssignmentStatus.archived,
      _ => throw ArgumentError.value(code, 'code', 'Unknown status.'),
    };
  }
}

/// Responsibility scope for a portfolio assignment.
///
/// TASK-045 deliberately does not model `Customer`. For an individual
/// customer assignment [customerId] is only an external id/contract consumed
/// later by TASK-051. For criteria assignments, [region] and [segment] are
/// planning filters; TASK-051 must materialize matching customers with a
/// primary seller/team before those customer documents become readable.
final class PortfolioAssignmentScope {
  const PortfolioAssignmentScope.customer(this.customerId)
    : type = PortfolioAssignmentScopeType.customer,
      region = null,
      segment = null;

  const PortfolioAssignmentScope.criteria({this.region, this.segment})
    : type = PortfolioAssignmentScopeType.criteria,
      customerId = null;

  final PortfolioAssignmentScopeType type;
  final String? customerId;
  final String? region;
  final String? segment;

  bool get isCustomer => type == PortfolioAssignmentScopeType.customer;

  String get label {
    return switch (type) {
      PortfolioAssignmentScopeType.customer => 'Cliente ${customerId ?? ''}',
      PortfolioAssignmentScopeType.criteria => [
        if (region != null && region!.isNotEmpty) 'Regiao: $region',
        if (segment != null && segment!.isNotEmpty) 'Segmento: $segment',
      ].join(' | '),
    };
  }
}

/// Seller-to-portfolio responsibility link scoped by organization/company.
///
/// A customer has exactly one active primary seller in this MVP contract.
/// Shared portfolios are not supported in TASK-045: reassignment closes the
/// previous active customer assignment and creates a new active one, preserving
/// the assignment trail and all future customer history.
final class PortfolioAssignment {
  const PortfolioAssignment({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.teamId,
    required this.scope,
    required this.status,
    required this.version,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.endedAt,
    this.endedBy,
    this.deletedAt,
  });

  final String id;
  final String organizationId;
  final String companyId;
  final String userId;
  final String teamId;
  final PortfolioAssignmentScope scope;
  final PortfolioAssignmentStatus status;
  final int version;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final DateTime? endedAt;
  final String? endedBy;
  final DateTime? deletedAt;
}
