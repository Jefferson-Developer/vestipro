import 'package:injectable/injectable.dart';

import '../entities/insight.dart';
import '../entities/insight_action.dart';
import '../entities/insight_context.dart';
import '../entities/insight_estimated_impact.dart';
import '../entities/insight_evidence.dart';
import '../entities/insight_organization_settings.dart';
import '../entities/insight_sales_rep_below_target_snapshot.dart';
import '../services/insight_rule.dart';
import '../value_objects/insight_action_type.dart';
import '../value_objects/insight_severity.dart';
import '../value_objects/insight_status.dart';
import '../value_objects/insight_type.dart';

/// Detects a sales representative whose pace, extrapolated linearly to the
/// end of the target's period (TASK-115, EPIC-15), would not reach the goal
/// cadastrado — surfaced only to that seller's sales manager/admin (never to
/// the seller themselves), so the manager can act before the period closes.
///
/// This rule intentionally never re-fetches or re-derives "meta"/"realizado"
/// on its own: both numbers, and the relevant-day counts used to pace them,
/// come straight from [InsightSalesRepBelowTargetSnapshot] (TASK-133
/// aggregation layer), so this insight can never numerically disagree with
/// the achievement/projection dashboards (TASK-116/TASK-119) built on the
/// same underlying target.
@lazySingleton
final class SalesRepBelowTargetInsightRule implements InsightRule {
  const SalesRepBelowTargetInsightRule();

  @override
  List<Insight> evaluate(InsightContext context) {
    final insights = <Insight>[];
    final settings = context.dataset.settings;

    for (final snapshot in context.dataset.salesRepBelowTargetSnapshots) {
      if (snapshot.organizationId != context.organizationId ||
          snapshot.companyId != context.companyId) {
        continue;
      }

      // Invalid/degenerate period or target data: nothing meaningful to
      // project.
      if (snapshot.totalRelevantDays <= 0 || snapshot.targetValue <= 0) {
        continue;
      }

      // Too little of the period has elapsed to trust the pace yet — avoids
      // a false alarm in the opening days (e.g. "so a partir do 5o dia
      // util").
      if (snapshot.elapsedRelevantDays <
          settings.sellerBelowTargetMinimumElapsedDays) {
        continue;
      }

      final band = _bandFor(snapshot.underAchievementRatio, settings);
      if (band == null) {
        // On track: nothing actionable yet, avoid alert noise.
        continue;
      }

      final projectedPercentage = snapshot.projectedAchievementPercentage;
      final requiredDailyPace = snapshot.requiredDailyPaceForRemainingDays;
      final shortfallAmount = (snapshot.targetValue - snapshot.projectedValue)
          .clamp(0, snapshot.targetValue);
      final expiresAt = context.asOf.add(settings.defaultLifetime);

      insights.add(
        Insight(
          id: 'seller_below_target:${snapshot.recipientUserId}:${snapshot.sellerId}',
          type: InsightType.sellerBelowTarget,
          title: '${band.label}: ${snapshot.sellerName}',
          description:
              '${snapshot.sellerName} esta projetado a atingir '
              '${projectedPercentage.toStringAsFixed(0)}% da meta de '
              '${snapshot.periodLabel}, no ritmo atual de R\$ '
              '${snapshot.currentDailyPace.toStringAsFixed(2)}/dia contra os '
              '${_formatDailyPace(requiredDailyPace)} necessarios nos '
              '${snapshot.remainingRelevantDays} dia(s) uteis restantes.',
          evidence: <InsightEvidence>[
            InsightEvidence(
              code: 'period_label',
              label: 'Periodo',
              value: snapshot.periodLabel,
            ),
            InsightEvidence(
              code: 'target_value',
              label: 'Meta do periodo',
              value: snapshot.targetValue.toStringAsFixed(2),
              numericValue: snapshot.targetValue,
              unit: 'BRL',
            ),
            InsightEvidence(
              code: 'realized_value',
              label: 'Realizado ate o momento',
              value: snapshot.realizedValue.toStringAsFixed(2),
              numericValue: snapshot.realizedValue,
              unit: 'BRL',
            ),
            InsightEvidence(
              code: 'elapsed_relevant_days',
              label: 'Dias decorridos no periodo',
              value: '${snapshot.elapsedRelevantDays}',
              numericValue: snapshot.elapsedRelevantDays.toDouble(),
              unit: 'days',
            ),
            InsightEvidence(
              code: 'remaining_relevant_days',
              label: 'Dias restantes no periodo',
              value: '${snapshot.remainingRelevantDays}',
              numericValue: snapshot.remainingRelevantDays.toDouble(),
              unit: 'days',
            ),
            InsightEvidence(
              code: 'current_daily_pace',
              label: 'Ritmo medio atual',
              value: snapshot.currentDailyPace.toStringAsFixed(2),
              numericValue: snapshot.currentDailyPace,
              unit: 'BRL/day',
            ),
            InsightEvidence(
              code: 'required_daily_pace',
              label: 'Ritmo necessario nos dias restantes',
              value: _formatDailyPace(requiredDailyPace),
              numericValue: requiredDailyPace.isFinite
                  ? requiredDailyPace
                  : null,
              unit: 'BRL/day',
            ),
            InsightEvidence(
              code: 'projected_achievement_percentage',
              label: 'Percentual de atingimento projetado',
              value: projectedPercentage.toStringAsFixed(1),
              numericValue: projectedPercentage,
              unit: 'percent',
            ),
            InsightEvidence(
              code: 'seller_below_target_band',
              label: 'Faixa de risco',
              value: band.label,
            ),
          ],
          estimatedImpact: InsightEstimatedImpact(
            amount: shortfallAmount.toDouble(),
            percentage: snapshot.underAchievementRatio,
          ),
          severity: band.severity,
          confidenceScore: 0.80,
          recommendation:
              'Reveja com o vendedor as contas prioritarias da carteira e '
              'monte um plano de acao para os dias restantes do periodo.',
          quickAction: InsightAction(
            type: InsightActionType.viewSellerDetail,
            label: 'Ver detalhe do vendedor',
            route: '/team/sellers/${snapshot.sellerId}',
            sellerId: snapshot.sellerId,
            payload: <String, Object?>{
              'sellerId': snapshot.sellerId,
              'periodStartDate': snapshot.periodStartDate.toIso8601String(),
              'periodEndDate': snapshot.periodEndDate.toIso8601String(),
              'targetValue': snapshot.targetValue,
              'realizedValue': snapshot.realizedValue,
            },
          ),
          secondaryActions: <InsightAction>[
            InsightAction(
              type: InsightActionType.viewOpportunities,
              label: 'Sugerir plano de acao',
              route: '/opportunities?sellerId=${snapshot.sellerId}',
              sellerId: snapshot.sellerId,
              payload: <String, Object?>{
                'sellerId': snapshot.sellerId,
                'suggestedReason': 'seller_below_target',
              },
            ),
          ],
          organizationId: snapshot.organizationId,
          companyId: snapshot.companyId,
          recipientUserId: snapshot.recipientUserId,
          sellerId: snapshot.sellerId,
          generatedAt: context.asOf,
          expiresAt: expiresAt,
          status: InsightStatus.fresh,
        ),
      );
    }
    return insights;
  }

  String _formatDailyPace(double dailyPace) {
    if (!dailyPace.isFinite) {
      return 'meta inalcancavel no periodo restante';
    }
    return 'R\$ ${dailyPace.toStringAsFixed(2)}/dia';
  }

  /// Guards the band comparisons below against floating-point drift from the
  /// chained division/multiplication in
  /// [InsightSalesRepBelowTargetSnapshot.underAchievementRatio] (e.g. a
  /// seller landing on an exact `90%` projection must never be missed just
  /// because `9000.0 / 10000.0 * 100` resolves to `89.99999999999999`).
  static const double _thresholdEpsilon = 1e-9;

  _SalesRepBelowTargetBand? _bandFor(
    double underAchievementRatio,
    InsightOrganizationSettings settings,
  ) {
    if (underAchievementRatio + _thresholdEpsilon >=
        settings.sellerBelowTargetCriticalThreshold) {
      return const _SalesRepBelowTargetBand(
        'Risco critico de meta',
        InsightSeverity.critical,
      );
    }
    if (underAchievementRatio + _thresholdEpsilon >=
        settings.sellerBelowTargetHighThreshold) {
      return const _SalesRepBelowTargetBand(
        'Risco alto de meta',
        InsightSeverity.high,
      );
    }
    if (underAchievementRatio + _thresholdEpsilon >=
        settings.sellerBelowTargetMediumThreshold) {
      return const _SalesRepBelowTargetBand(
        'Risco moderado de meta',
        InsightSeverity.medium,
      );
    }
    return null;
  }
}

final class _SalesRepBelowTargetBand {
  const _SalesRepBelowTargetBand(this.label, this.severity);

  final String label;
  final InsightSeverity severity;
}
