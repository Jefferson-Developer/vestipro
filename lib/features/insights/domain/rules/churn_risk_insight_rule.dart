import 'package:injectable/injectable.dart';

import '../entities/insight.dart';
import '../entities/insight_action.dart';
import '../entities/insight_context.dart';
import '../entities/insight_estimated_impact.dart';
import '../entities/insight_evidence.dart';
import '../entities/insight_organization_settings.dart';
import '../services/insight_rule.dart';
import '../value_objects/insight_action_type.dart';
import '../value_objects/insight_severity.dart';
import '../value_objects/insight_status.dart';
import '../value_objects/insight_type.dart';

/// Combines three independent churn signals — decline in purchase frequency,
/// decline in revenue, and the customer health score (TASK-062) — into a
/// single, explainable churn-risk score, prioritized for display by the
/// customer's financial impact rather than by the risk score alone.
@lazySingleton
final class ChurnRiskInsightRule implements InsightRule {
  const ChurnRiskInsightRule();

  @override
  List<Insight> evaluate(InsightContext context) {
    final insights = <Insight>[];
    final settings = context.dataset.settings;
    for (final snapshot in context.dataset.churnRiskSnapshots) {
      if (snapshot.organizationId != context.organizationId ||
          snapshot.companyId != context.companyId) {
        continue;
      }

      // Customers with too little purchase history do not yield a reliable
      // churn-risk signal (e.g. a brand-new customer naturally has low
      // frequency) — skip rather than raise a false positive.
      if (snapshot.historicalOrderCount <
          settings.churnRiskMinimumHistoricalOrders) {
        continue;
      }

      final frequencySignal = snapshot.frequencyDeclineRatio;
      final valueSignal = snapshot.revenueDeclineRatio;
      final healthSignal = snapshot.healthScoreRiskRatio;
      final riskScore = _composeRiskScore(
        settings: settings,
        frequencySignal: frequencySignal,
        valueSignal: valueSignal,
        healthSignal: healthSignal,
      );

      final band = _bandFor(riskScore, settings);
      if (band == null) {
        // "Baixo" risk: nothing actionable yet, avoid alert noise.
        continue;
      }

      final financialImpact = snapshot.financialImpactBase * riskScore;
      final expiresAt = context.asOf.add(settings.defaultLifetime);

      insights.add(
        Insight(
          id: 'churn_risk:${snapshot.recipientUserId}:${snapshot.customerId}',
          type: InsightType.churnRisk,
          title: 'Risco de churn: ${snapshot.customerName}',
          description:
              '${snapshot.customerName} apresenta risco de churn '
              '${band.label.toLowerCase()} (score ${(riskScore * 100).toStringAsFixed(0)}'
              '/100), combinando queda de frequencia de compra, queda de '
              'faturamento e health score do cliente.',
          evidence: <InsightEvidence>[
            InsightEvidence(
              code: 'frequency_decline_ratio',
              label: 'Queda de frequencia de compra',
              value: (frequencySignal * 100).toStringAsFixed(1),
              numericValue: frequencySignal * 100,
              unit: 'percent',
            ),
            InsightEvidence(
              code: 'frequency_signal_weight',
              label: 'Peso do sinal de frequencia',
              value: (settings.churnRiskFrequencyWeight * 100).toStringAsFixed(
                0,
              ),
              numericValue: settings.churnRiskFrequencyWeight * 100,
              unit: 'percent',
            ),
            InsightEvidence(
              code: 'value_decline_ratio',
              label: 'Queda de faturamento',
              value: (valueSignal * 100).toStringAsFixed(1),
              numericValue: valueSignal * 100,
              unit: 'percent',
            ),
            InsightEvidence(
              code: 'value_signal_weight',
              label: 'Peso do sinal de faturamento',
              value: (settings.churnRiskValueWeight * 100).toStringAsFixed(0),
              numericValue: settings.churnRiskValueWeight * 100,
              unit: 'percent',
            ),
            InsightEvidence(
              code: 'health_score',
              label: 'Health score do cliente',
              value: '${snapshot.healthScore}',
              numericValue: snapshot.healthScore.toDouble(),
              unit: 'score',
            ),
            InsightEvidence(
              code: 'health_score_signal_weight',
              label: 'Peso do sinal de health score',
              value: (settings.churnRiskHealthScoreWeight * 100)
                  .toStringAsFixed(0),
              numericValue: settings.churnRiskHealthScoreWeight * 100,
              unit: 'percent',
            ),
            InsightEvidence(
              code: 'churn_risk_score',
              label: 'Score de risco de churn',
              value: (riskScore * 100).toStringAsFixed(1),
              numericValue: riskScore * 100,
              unit: 'percent',
            ),
            InsightEvidence(
              code: 'churn_risk_band',
              label: 'Faixa de risco',
              value: band.label,
            ),
          ],
          estimatedImpact: InsightEstimatedImpact(
            amount: financialImpact,
            percentage: riskScore,
          ),
          severity: band.severity,
          confidenceScore: 0.80,
          recommendation:
              'Priorize um contato comercial com o cliente e revise o '
              'historico de pedidos para entender a causa da queda antes '
              'que o relacionamento se perca.',
          quickAction: InsightAction(
            type: InsightActionType.scheduleContact,
            label: 'Agendar contato prioritario',
            customerId: snapshot.customerId,
            payload: <String, Object?>{
              'customerId': snapshot.customerId,
              'suggestedReason': 'churn_risk',
            },
          ),
          secondaryActions: <InsightAction>[
            InsightAction(
              type: InsightActionType.openCustomer,
              label: 'Abrir cliente 360',
              route: '/customers/${snapshot.customerId}',
              customerId: snapshot.customerId,
            ),
          ],
          organizationId: snapshot.organizationId,
          companyId: snapshot.companyId,
          recipientUserId: snapshot.recipientUserId,
          customerId: snapshot.customerId,
          generatedAt: context.asOf,
          expiresAt: expiresAt,
          status: InsightStatus.fresh,
        ),
      );
    }
    return insights;
  }

  /// Weighted average of the three normalized (0..1) risk signals, using the
  /// organization-configured weights. Weights are normalized by their sum so
  /// that misconfigured weights (not summing to 1) never produce a score
  /// outside the 0..1 range.
  double _composeRiskScore({
    required InsightOrganizationSettings settings,
    required double frequencySignal,
    required double valueSignal,
    required double healthSignal,
  }) {
    final totalWeight =
        settings.churnRiskFrequencyWeight +
        settings.churnRiskValueWeight +
        settings.churnRiskHealthScoreWeight;
    if (totalWeight <= 0) {
      return 0;
    }
    final weighted =
        (frequencySignal * settings.churnRiskFrequencyWeight) +
        (valueSignal * settings.churnRiskValueWeight) +
        (healthSignal * settings.churnRiskHealthScoreWeight);
    return (weighted / totalWeight).clamp(0, 1);
  }

  _ChurnRiskBand? _bandFor(double score, InsightOrganizationSettings settings) {
    if (score >= settings.churnRiskCriticalThreshold) {
      return const _ChurnRiskBand('Critico', InsightSeverity.critical);
    }
    if (score >= settings.churnRiskHighThreshold) {
      return const _ChurnRiskBand('Alto', InsightSeverity.high);
    }
    if (score >= settings.churnRiskMediumThreshold) {
      return const _ChurnRiskBand('Medio', InsightSeverity.medium);
    }
    return null;
  }
}

final class _ChurnRiskBand {
  const _ChurnRiskBand(this.label, this.severity);

  final String label;
  final InsightSeverity severity;
}
