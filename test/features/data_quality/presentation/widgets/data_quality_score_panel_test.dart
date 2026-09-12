import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/data_quality/data_quality.dart';

void main() {
  testWidgets('renders score and issue queue', (tester) async {
    final now = DateTime(2026, 9, 12);
    final score = MasterDataScore(
      organizationId: 'org-1',
      entityType: MasterDataEntityType.customer,
      totalRecords: 10,
      openIssues: 1,
      score: 90,
      calculatedAt: now,
    );
    final issue = DataQualityIssue(
      id: 'issue-1',
      organizationId: 'org-1',
      entityType: MasterDataEntityType.customer,
      entityId: 'customer-1',
      ruleId: 'rule-1',
      type: DataQualityRuleType.customerWithoutContact,
      severity: DataQualitySeverity.high,
      status: DataQualityIssueStatus.open,
      message: 'Cliente sem contato.',
      detectedAt: now,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DataQualityScorePanel(score: score, issues: [issue]),
        ),
      ),
    );

    expect(find.text('Qualidade cadastral'), findsOneWidget);
    expect(find.text('90% - 1 pendencia(s) abertas'), findsOneWidget);
    expect(find.text('Cliente sem contato.'), findsOneWidget);
  });
}
