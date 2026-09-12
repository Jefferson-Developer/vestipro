import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/territories/territories.dart';

void main() {
  final now = DateTime(2026, 9, 12);

  SalesTerritory territory({
    String id = 'territory-1',
    List<String> customerIds = const ['customer-1'],
    List<String> salesRepIds = const ['rep-1'],
    List<String> teamIds = const ['team-1'],
    bool exclusive = true,
  }) {
    return SalesTerritory(
      id: id,
      organizationId: 'org-1',
      companyId: 'company-1',
      name: id,
      regionCode: 'SP',
      salesRepIds: salesRepIds,
      teamIds: teamIds,
      customerIds: customerIds,
      exclusive: exclusive,
      effectiveFrom: now,
    );
  }

  CustomerPotentialScore score(String customerId, double value) {
    return CustomerPotentialScore(
      customerId: customerId,
      formulaVersion: 'potential-v1',
      score: value,
      label: 'Alto',
      evidence: const {},
    );
  }

  test('reassigns territory while preserving assignment history', () {
    const service = TerritoryAssignmentService();
    final previous = CustomerTerritoryAssignment(
      customerId: 'customer-1',
      territoryId: 'old',
      salesRepId: 'rep-1',
      effectiveFrom: now.subtract(const Duration(days: 30)),
      assignedBy: 'manager-1',
    );

    final result = service.reassignCustomer(
      newAssignmentId: 'assignment-2',
      customerId: 'customer-1',
      territoryId: 'new',
      salesRepId: 'rep-2',
      effectiveFrom: now,
      assignedBy: 'manager-1',
      existingAssignments: [previous],
    );

    expect(result.closedPreviousAssignments.single.effectiveTo, now);
    expect(
      result.closedPreviousAssignments.single.replacedByAssignmentId,
      'assignment-2',
    );
    expect(result.newAssignment.salesRepId, 'rep-2');
  });

  test('calculates versioned explainable potential score', () {
    const scorer = CustomerPotentialScorer(formulaVersion: 'potential-v2');

    final result = scorer.score(
      customerId: 'customer-1',
      evidence: const CustomerPotentialEvidence(
        historicalRevenueCents: 20000000,
        segmentWeight: 1,
        regionWeight: 1,
        mixBreadth: 1,
        purchaseFrequency: 1,
        storeSizeWeight: 1,
        externalSignalWeight: 1,
      ),
    );

    expect(result.formulaVersion, 'potential-v2');
    expect(result.score, 80);
    expect(result.label, 'Alto');
    expect(result.evidence.keys, containsAll(['segment', 'region', 'mix']));
  });

  test('enforces visibility by rep, manager team and owner/admin', () {
    const visibility = TerritoryVisibilityService();
    final currentTerritory = territory();

    expect(
      visibility.canViewCustomerPotential(
        isOwnerOrAdmin: false,
        isSalesManager: false,
        currentUserId: 'rep-1',
        managerTeamIds: const {},
        territory: currentTerritory,
        salesRepId: 'rep-1',
      ),
      isTrue,
    );
    expect(
      visibility.canViewCustomerPotential(
        isOwnerOrAdmin: false,
        isSalesManager: false,
        currentUserId: 'rep-2',
        managerTeamIds: const {},
        territory: currentTerritory,
        salesRepId: 'rep-1',
      ),
      isFalse,
    );
    expect(
      visibility.canViewCustomerPotential(
        isOwnerOrAdmin: false,
        isSalesManager: true,
        currentUserId: 'manager-1',
        managerTeamIds: const {'team-1'},
        territory: currentTerritory,
        salesRepId: 'rep-1',
      ),
      isTrue,
    );
  });

  test(
    'builds coverage dashboard with uncovered underserved and high potential',
    () {
      const service = TerritoryCoverageService(underservedAfterDays: 30);

      final dashboard = service.build(
        territories: [territory()],
        customers: [
          CustomerCoverageInput(
            customerId: 'uncovered',
            salesRepId: null,
            daysSinceLastVisit: null,
            potentialScore: score('uncovered', 20),
          ),
          CustomerCoverageInput(
            customerId: 'underserved',
            salesRepId: 'rep-1',
            daysSinceLastVisit: 45,
            potentialScore: score('underserved', 35),
          ),
          CustomerCoverageInput(
            customerId: 'high',
            salesRepId: 'rep-1',
            daysSinceLastVisit: 5,
            potentialScore: score('high', 80),
          ),
        ],
      );

      expect(
        dashboard.rows.map((row) => row.status),
        containsAll([
          CoverageStatus.uncovered,
          CoverageStatus.underserved,
          CoverageStatus.highPotential,
        ]),
      );
    },
  );

  test('flags customers assigned to conflicting exclusive territories', () {
    const service = TerritoryCoverageService();

    final dashboard = service.build(
      territories: [
        territory(id: 'a', customerIds: const ['customer-1']),
        territory(id: 'b', customerIds: const ['customer-1']),
      ],
      customers: [
        CustomerCoverageInput(
          customerId: 'customer-1',
          salesRepId: 'rep-1',
          daysSinceLastVisit: 5,
          potentialScore: score('customer-1', 80),
        ),
      ],
    );

    expect(dashboard.conflicts.single.customerId, 'customer-1');
    expect(dashboard.rows.single.status, CoverageStatus.conflict);
  });
}
