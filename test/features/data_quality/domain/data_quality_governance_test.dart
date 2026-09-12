import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/data_quality/data_quality.dart';

void main() {
  final now = DateTime(2026, 9, 12);

  MasterDataRecord customer(
    String id, {
    String organizationId = 'org-1',
    String name = 'Loja Centro',
    String? taxDocument = '12.345.678/0001-90',
    String? address = 'Rua 1',
  }) {
    return MasterDataRecord(
      id: id,
      organizationId: organizationId,
      entityType: MasterDataEntityType.customer,
      fields: {'name': name, 'taxDocument': taxDocument, 'address': address},
    );
  }

  test('detects strong and weak duplicates without crossing tenants', () {
    const detector = DuplicateDetector();

    final candidates = detector.detect([
      customer('a'),
      customer('b'),
      customer('c', taxDocument: '00.000.000/0001-00'),
      customer('d', organizationId: 'org-2'),
    ]);

    expect(
      candidates.where(
        (item) => item.strength == DuplicateMatchStrength.strong,
      ),
      hasLength(1),
    );
    expect(
      candidates.where((item) => item.strength == DuplicateMatchStrength.weak),
      isNotEmpty,
    );
    expect(candidates.map((item) => item.organizationId).toSet(), {'org-1'});
  });

  test('plans merge preserving history references and legacy id map', () {
    const planner = MergePlanner();

    final request = planner.plan(
      id: 'merge-1',
      requestedAt: now,
      requestedBy: 'manager-1',
      organizationId: 'org-1',
      entityType: MasterDataEntityType.customer,
      targetEntityId: 'customer-a',
      sourceEntityIds: const ['customer-a', 'customer-b'],
      referenceCountsByCollection: const {'orders': 10, 'invoices': 2},
    );

    expect(request.requiresHumanApproval, isTrue);
    expect(request.impactPreview['orders'], 10);
    expect(request.legacyIdMap['customer-b'], 'customer-a');
  });

  test('applies organization configurable quality rules', () {
    const engine = DataQualityEngine();

    final issues = engine.evaluate(
      detectedAt: now,
      rules: const [
        DataQualityRule(
          id: 'customer-address',
          organizationId: 'org-1',
          entityType: MasterDataEntityType.customer,
          type: DataQualityRuleType.customerWithoutAddress,
          name: 'Endereco obrigatorio',
          requiredFields: ['address'],
          enabled: true,
          severity: DataQualitySeverity.high,
        ),
        DataQualityRule(
          id: 'customer-address-other',
          organizationId: 'org-2',
          entityType: MasterDataEntityType.customer,
          type: DataQualityRuleType.customerWithoutAddress,
          name: 'Endereco obrigatorio',
          requiredFields: ['address'],
          enabled: true,
          severity: DataQualitySeverity.high,
        ),
      ],
      records: [customer('a', address: '')],
    );

    expect(issues, hasLength(1));
    expect(issues.single.organizationId, 'org-1');
  });

  test('enforces RBAC for fix approval and score visibility', () {
    const visibility = DataQualityVisibilityService();
    final issue = DataQualityIssue(
      id: 'issue-1',
      organizationId: 'org-1',
      entityType: MasterDataEntityType.customer,
      entityId: 'customer-1',
      ruleId: 'rule-1',
      type: DataQualityRuleType.requiredField,
      severity: DataQualitySeverity.medium,
      status: DataQualityIssueStatus.assigned,
      message: 'Campo ausente',
      detectedAt: now,
      assigneeUserId: 'user-1',
    );

    expect(
      visibility.canViewScore(isOwnerOrAdmin: false, isManager: true),
      isTrue,
    );
    expect(
      visibility.canFixIssue(
        isOwnerOrAdmin: false,
        isManager: false,
        currentUserId: 'user-1',
        issue: issue,
      ),
      isTrue,
    );
    expect(
      visibility.canApproveMerge(isOwnerOrAdmin: false, isManager: false),
      isFalse,
    );
  });

  test('marks insight confidence as low when master data score is weak', () {
    const service = InsightConfidenceService();
    final score = MasterDataScore(
      organizationId: 'org-1',
      entityType: MasterDataEntityType.customer,
      totalRecords: 10,
      openIssues: 4,
      score: 60,
      calculatedAt: now,
    );

    final indicator = service.indicatorFor(score);

    expect(indicator.score, 60);
    expect(indicator.message, contains('Baixa confianca'));
  });
}
