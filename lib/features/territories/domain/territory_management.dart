enum TerritoryStatus { active, inactive }

enum CoverageStatus { covered, uncovered, underserved, highPotential, conflict }

final class SalesTerritory {
  const SalesTerritory({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.name,
    required this.regionCode,
    required this.salesRepIds,
    required this.teamIds,
    required this.customerIds,
    required this.exclusive,
    required this.effectiveFrom,
    this.parentTerritoryId,
    this.effectiveTo,
    this.status = TerritoryStatus.active,
  });

  final String id;
  final String organizationId;
  final String companyId;
  final String name;
  final String regionCode;
  final List<String> salesRepIds;
  final List<String> teamIds;
  final List<String> customerIds;
  final bool exclusive;
  final DateTime effectiveFrom;
  final String? parentTerritoryId;
  final DateTime? effectiveTo;
  final TerritoryStatus status;

  bool containsCustomer(String customerId) => customerIds.contains(customerId);
}

final class CustomerTerritoryAssignment {
  const CustomerTerritoryAssignment({
    required this.customerId,
    required this.territoryId,
    required this.salesRepId,
    required this.effectiveFrom,
    required this.assignedBy,
    this.effectiveTo,
    this.replacedByAssignmentId,
  });

  final String customerId;
  final String territoryId;
  final String salesRepId;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final String assignedBy;
  final String? replacedByAssignmentId;

  bool get isCurrent => effectiveTo == null;

  CustomerTerritoryAssignment close({
    required DateTime at,
    required String replacementId,
  }) {
    return CustomerTerritoryAssignment(
      customerId: customerId,
      territoryId: territoryId,
      salesRepId: salesRepId,
      effectiveFrom: effectiveFrom,
      effectiveTo: at,
      assignedBy: assignedBy,
      replacedByAssignmentId: replacementId,
    );
  }
}

final class TerritoryReassignmentResult {
  const TerritoryReassignmentResult({
    required this.closedPreviousAssignments,
    required this.newAssignment,
  });

  final List<CustomerTerritoryAssignment> closedPreviousAssignments;
  final CustomerTerritoryAssignment newAssignment;
}

final class TerritoryAssignmentService {
  const TerritoryAssignmentService();

  TerritoryReassignmentResult reassignCustomer({
    required String newAssignmentId,
    required String customerId,
    required String territoryId,
    required String salesRepId,
    required DateTime effectiveFrom,
    required String assignedBy,
    required Iterable<CustomerTerritoryAssignment> existingAssignments,
  }) {
    final closed = existingAssignments
        .where(
          (assignment) =>
              assignment.customerId == customerId && assignment.isCurrent,
        )
        .map(
          (assignment) => assignment.close(
            at: effectiveFrom,
            replacementId: newAssignmentId,
          ),
        )
        .toList(growable: false);

    return TerritoryReassignmentResult(
      closedPreviousAssignments: closed,
      newAssignment: CustomerTerritoryAssignment(
        customerId: customerId,
        territoryId: territoryId,
        salesRepId: salesRepId,
        effectiveFrom: effectiveFrom,
        assignedBy: assignedBy,
      ),
    );
  }
}

final class CustomerPotentialEvidence {
  const CustomerPotentialEvidence({
    required this.historicalRevenueCents,
    required this.segmentWeight,
    required this.regionWeight,
    required this.mixBreadth,
    required this.purchaseFrequency,
    required this.storeSizeWeight,
    this.externalSignalWeight = 0,
  });

  final int historicalRevenueCents;
  final double segmentWeight;
  final double regionWeight;
  final double mixBreadth;
  final double purchaseFrequency;
  final double storeSizeWeight;
  final double externalSignalWeight;
}

final class CustomerPotentialScore {
  const CustomerPotentialScore({
    required this.customerId,
    required this.formulaVersion,
    required this.score,
    required this.label,
    required this.evidence,
  });

  final String customerId;
  final String formulaVersion;
  final double score;
  final String label;
  final Map<String, double> evidence;
}

final class CustomerPotentialScorer {
  const CustomerPotentialScorer({this.formulaVersion = 'potential-v1'});

  final String formulaVersion;

  CustomerPotentialScore score({
    required String customerId,
    required CustomerPotentialEvidence evidence,
  }) {
    final revenue = (evidence.historicalRevenueCents / 1000000).clamp(0, 40);
    final weighted =
        revenue +
        evidence.segmentWeight * 15 +
        evidence.regionWeight * 10 +
        evidence.mixBreadth * 15 +
        evidence.purchaseFrequency * 10 +
        evidence.storeSizeWeight * 5 +
        evidence.externalSignalWeight * 5;
    final score = weighted.clamp(0, 100).toDouble();
    return CustomerPotentialScore(
      customerId: customerId,
      formulaVersion: formulaVersion,
      score: score,
      label: score >= 70
          ? 'Alto'
          : score >= 40
          ? 'Medio'
          : 'Baixo',
      evidence: {
        'historicalRevenue': revenue.toDouble(),
        'segment': evidence.segmentWeight,
        'region': evidence.regionWeight,
        'mix': evidence.mixBreadth,
        'frequency': evidence.purchaseFrequency,
        'storeSize': evidence.storeSizeWeight,
        'externalSignal': evidence.externalSignalWeight,
      },
    );
  }
}

final class CustomerCoverageInput {
  const CustomerCoverageInput({
    required this.customerId,
    required this.salesRepId,
    required this.daysSinceLastVisit,
    required this.potentialScore,
  });

  final String customerId;
  final String? salesRepId;
  final int? daysSinceLastVisit;
  final CustomerPotentialScore potentialScore;
}

final class CustomerCoverageRow {
  const CustomerCoverageRow({
    required this.customerId,
    required this.status,
    required this.priority,
    required this.reason,
  });

  final String customerId;
  final CoverageStatus status;
  final int priority;
  final String reason;
}

final class TerritoryConflict {
  const TerritoryConflict({
    required this.customerId,
    required this.territoryIds,
    required this.message,
  });

  final String customerId;
  final List<String> territoryIds;
  final String message;
}

final class TerritoryCoverageDashboard {
  const TerritoryCoverageDashboard({
    required this.rows,
    required this.conflicts,
  });

  final List<CustomerCoverageRow> rows;
  final List<TerritoryConflict> conflicts;
}

final class TerritoryCoverageService {
  const TerritoryCoverageService({
    this.underservedAfterDays = 45,
    this.highPotentialThreshold = 70,
  });

  final int underservedAfterDays;
  final double highPotentialThreshold;

  TerritoryCoverageDashboard build({
    required Iterable<SalesTerritory> territories,
    required Iterable<CustomerCoverageInput> customers,
  }) {
    final conflicts = _exclusiveConflicts(territories);
    final conflictCustomerIds = conflicts
        .map((conflict) => conflict.customerId)
        .toSet();

    final rows =
        customers
            .map((customer) {
              if (conflictCustomerIds.contains(customer.customerId)) {
                return CustomerCoverageRow(
                  customerId: customer.customerId,
                  status: CoverageStatus.conflict,
                  priority: 100,
                  reason: 'Cliente em territorios exclusivos conflitantes.',
                );
              }
              if (customer.salesRepId == null || customer.salesRepId!.isEmpty) {
                return CustomerCoverageRow(
                  customerId: customer.customerId,
                  status: CoverageStatus.uncovered,
                  priority: 90,
                  reason: 'Cliente sem vendedor/carteira ativa.',
                );
              }
              if ((customer.daysSinceLastVisit ?? 9999) >
                  underservedAfterDays) {
                return CustomerCoverageRow(
                  customerId: customer.customerId,
                  status: CoverageStatus.underserved,
                  priority: 80,
                  reason: 'Cliente com baixa frequencia de visita.',
                );
              }
              if (customer.potentialScore.score >= highPotentialThreshold) {
                return CustomerCoverageRow(
                  customerId: customer.customerId,
                  status: CoverageStatus.highPotential,
                  priority: 70,
                  reason: 'Cliente de alto potencial para proxima visita.',
                );
              }
              return CustomerCoverageRow(
                customerId: customer.customerId,
                status: CoverageStatus.covered,
                priority: 10,
                reason: 'Cobertura em dia.',
              );
            })
            .toList(growable: false)
          ..sort((a, b) => b.priority.compareTo(a.priority));

    return TerritoryCoverageDashboard(rows: rows, conflicts: conflicts);
  }

  List<TerritoryConflict> _exclusiveConflicts(
    Iterable<SalesTerritory> territories,
  ) {
    final ownersByCustomer = <String, List<String>>{};
    for (final territory in territories.where((item) => item.exclusive)) {
      for (final customerId in territory.customerIds) {
        ownersByCustomer
            .putIfAbsent(customerId, () => <String>[])
            .add(territory.id);
      }
    }
    return ownersByCustomer.entries
        .where((entry) => entry.value.length > 1)
        .map(
          (entry) => TerritoryConflict(
            customerId: entry.key,
            territoryIds: entry.value,
            message: 'Cliente em mais de um territorio exclusivo.',
          ),
        )
        .toList(growable: false);
  }
}

final class TerritoryVisibilityService {
  const TerritoryVisibilityService();

  bool canViewCustomerPotential({
    required bool isOwnerOrAdmin,
    required bool isSalesManager,
    required String currentUserId,
    required Set<String> managerTeamIds,
    required SalesTerritory territory,
    required String salesRepId,
  }) {
    if (isOwnerOrAdmin) {
      return true;
    }
    if (territory.salesRepIds.contains(currentUserId)) {
      return salesRepId == currentUserId;
    }
    if (isSalesManager &&
        territory.teamIds.any((teamId) => managerTeamIds.contains(teamId))) {
      return true;
    }
    return false;
  }
}
