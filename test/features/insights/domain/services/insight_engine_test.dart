import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/insights/insights.dart';

void main() {
  group('InsightEngine', () {
    const validator = InsightStructuralValidator();
    final context = InsightContext(
      organizationId: 'org-1',
      companyId: 'company-1',
      asOf: DateTime.utc(2026, 9, 1, 12),
      dataset: const InsightDataset(settings: InsightOrganizationSettings()),
    );

    test('returns no insights when no rule triggers', () {
      final engine = InsightEngine(<InsightRule>[
        _FakeRule(const <Insight>[]),
      ], validator);

      final result = engine.evaluate(context);

      expect(result, isEmpty);
    });

    test('aggregates multiple rules, deduplicates and sorts by impact', () {
      final lowImpact = _buildInsight(
        id: 'i-1',
        customerId: 'customer-1',
        amount: 100,
        generatedAt: DateTime.utc(2026, 9, 1, 12),
      );
      final higherDuplicate = _buildInsight(
        id: 'i-2',
        customerId: 'customer-1',
        amount: 400,
        generatedAt: DateTime.utc(2026, 9, 1, 13),
      );
      final other = _buildInsight(
        id: 'i-3',
        type: InsightType.revenueDrop,
        customerId: 'customer-2',
        amount: 250,
        generatedAt: DateTime.utc(2026, 9, 1, 11),
      );
      final engine = InsightEngine(<InsightRule>[
        _FakeRule(<Insight>[lowImpact, other]),
        _FakeRule(<Insight>[higherDuplicate]),
      ], validator);

      final result = engine.evaluate(context);

      expect(result.map((item) => item.id), <String>['i-2', 'i-3']);
    });
  });
}

final class _FakeRule implements InsightRule {
  const _FakeRule(this._insights);

  final List<Insight> _insights;

  @override
  List<Insight> evaluate(InsightContext context) => _insights;
}

Insight _buildInsight({
  required String id,
  required String customerId,
  required double amount,
  InsightType type = InsightType.inactiveCustomer,
  DateTime? generatedAt,
}) {
  return Insight(
    id: id,
    type: type,
    title: 'Insight $id',
    description: 'Descricao',
    evidence: const <InsightEvidence>[
      InsightEvidence(code: 'e1', label: 'E1', value: 'valor'),
    ],
    estimatedImpact: InsightEstimatedImpact(amount: amount),
    severity: InsightSeverity.medium,
    confidenceScore: 0.9,
    recommendation: 'Recomendar acao',
    quickAction: const InsightAction(
      type: InsightActionType.openCustomer,
      label: 'Abrir cliente',
    ),
    organizationId: 'org-1',
    companyId: 'company-1',
    recipientUserId: 'seller-1',
    customerId: customerId,
    generatedAt: generatedAt ?? DateTime.utc(2026, 9, 1, 12),
    expiresAt: DateTime.utc(2026, 9, 8, 12),
    status: InsightStatus.fresh,
  );
}
