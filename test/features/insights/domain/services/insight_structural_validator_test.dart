import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/insights/insights.dart';

void main() {
  group('InsightStructuralValidator', () {
    const validator = InsightStructuralValidator();

    test('rejects insight without evidence', () {
      expect(
        () => validator.validate(
          _baseInsight(evidence: const <InsightEvidence>[]),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects insight without impact', () {
      expect(
        () => validator.validate(
          _baseInsight(impact: const InsightEstimatedImpact()),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects insight without recommendation', () {
      expect(
        () => validator.validate(_baseInsight(recommendation: '  ')),
        throwsA(isA<Exception>()),
      );
    });
  });
}

Insight _baseInsight({
  List<InsightEvidence>? evidence,
  InsightEstimatedImpact? impact,
  String recommendation = 'Acao recomendada',
}) {
  return Insight(
    id: 'insight-1',
    type: InsightType.inactiveCustomer,
    title: 'Cliente inativo',
    description: 'Descricao',
    evidence:
        evidence ??
        const <InsightEvidence>[
          InsightEvidence(
            code: 'last_order',
            label: 'Ultimo pedido',
            value: '2026-07-01',
          ),
        ],
    estimatedImpact: impact ?? const InsightEstimatedImpact(amount: 1200),
    severity: InsightSeverity.medium,
    confidenceScore: 0.8,
    recommendation: recommendation,
    quickAction: const InsightAction(
      type: InsightActionType.scheduleContact,
      label: 'Agendar contato',
    ),
    organizationId: 'org-1',
    companyId: 'company-1',
    recipientUserId: 'seller-1',
    customerId: 'customer-1',
    generatedAt: DateTime.utc(2026, 9, 1, 12),
    expiresAt: DateTime.utc(2026, 9, 8, 12),
    status: InsightStatus.fresh,
  );
}
