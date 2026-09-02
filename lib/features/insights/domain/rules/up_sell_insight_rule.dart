import 'package:injectable/injectable.dart';

import '../entities/insight.dart';
import '../entities/insight_action.dart';
import '../entities/insight_context.dart';
import '../entities/insight_estimated_impact.dart';
import '../entities/insight_evidence.dart';
import '../entities/insight_up_sell_category_candidate.dart';
import '../entities/insight_up_sell_variant_candidate.dart';
import '../services/insight_rule.dart';
import '../value_objects/insight_action_type.dart';
import '../value_objects/insight_severity.dart';
import '../value_objects/insight_status.dart';
import '../value_objects/insight_type.dart';

/// Identifies "up-sell" opportunities: categories the customer already buys
/// where their average ticket/quantity per order sits below a group of
/// similar customers with higher volume in that same category (unlike
/// cross-sell, TASK-125, which only looks at categories the customer does
/// not buy yet). Every quantity suggested for the "Sugerir grade ampliada"
/// quick action is capped by the variant's real stock balance (TASK-090).
@lazySingleton
final class UpSellInsightRule implements InsightRule {
  const UpSellInsightRule();

  @override
  List<Insight> evaluate(InsightContext context) {
    final insights = <Insight>[];
    final settings = context.dataset.settings;
    final minimumGap = settings.upSellMinimumTicketGapPercentage;
    final expiresAt = context.asOf.add(settings.defaultLifetime);

    for (final snapshot in context.dataset.upSellSnapshots) {
      if (snapshot.organizationId != context.organizationId ||
          snapshot.companyId != context.companyId) {
        continue;
      }

      for (final candidate in snapshot.candidates) {
        if (!candidate.isEligible) {
          continue;
        }
        final gap = candidate.ticketGapPercentage;
        if (gap < minimumGap) {
          continue;
        }

        final variantSuggestions = candidate.variantCandidates
            .where((variant) => variant.hasSuggestion)
            .toList();
        if (variantSuggestions.isEmpty) {
          continue;
        }

        final estimatedAmount =
            candidate.peerAverageTicket - candidate.customerAverageTicket;

        insights.add(
          Insight(
            id: 'up_sell:${snapshot.recipientUserId}:${snapshot.customerId}:${candidate.categoryId}',
            type: InsightType.upSell,
            title: 'Oportunidade de up-sell: ${snapshot.customerName}',
            description:
                '${snapshot.customerName} compra ${candidate.categoryName} '
                'com ticket medio de R\$ '
                '${candidate.customerAverageTicket.toStringAsFixed(2)}, '
                '${(gap * 100).toStringAsFixed(1)}% abaixo da media de '
                'clientes semelhantes de maior volume '
                '(${snapshot.comparisonGroupLabel}, '
                '${snapshot.comparisonGroupSize} clientes na base de '
                'comparacao), que compram em media R\$ '
                '${candidate.peerAverageTicket.toStringAsFixed(2)} nessa '
                'categoria.',
            evidence: <InsightEvidence>[
              InsightEvidence(
                code: 'up_sell_comparison_group',
                label:
                    'Base de comparacao (clientes semelhantes de maior volume)',
                value: snapshot.comparisonGroupLabel,
                numericValue: snapshot.comparisonGroupSize.toDouble(),
              ),
              InsightEvidence(
                code: 'up_sell_customer_average_ticket:${candidate.categoryId}',
                label:
                    'Ticket medio atual do cliente em "${candidate.categoryName}"',
                value: candidate.customerAverageTicket.toStringAsFixed(2),
                numericValue: candidate.customerAverageTicket,
                unit: 'BRL',
              ),
              InsightEvidence(
                code: 'up_sell_peer_average_ticket:${candidate.categoryId}',
                label:
                    'Ticket medio de clientes semelhantes de maior volume em "${candidate.categoryName}"',
                value: candidate.peerAverageTicket.toStringAsFixed(2),
                numericValue: candidate.peerAverageTicket,
                unit: 'BRL',
              ),
              InsightEvidence(
                code: 'up_sell_ticket_gap:${candidate.categoryId}',
                label: 'Diferenca percentual em relacao ao grupo de comparacao',
                value: (gap * 100).toStringAsFixed(1),
                numericValue: gap * 100,
                unit: 'percent',
              ),
            ],
            estimatedImpact: InsightEstimatedImpact(
              amount: estimatedAmount,
              percentage: gap,
            ),
            severity: _severityFor(gap),
            confidenceScore: 0.6,
            recommendation:
                'Sugira ampliar a grade de "${candidate.categoryName}" no '
                'proximo pedido, dentro da disponibilidade real de estoque.',
            quickAction: _expandGridAction(
              snapshot.customerId,
              candidate,
              variantSuggestions,
            ),
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
    }
    return insights;
  }

  InsightAction _expandGridAction(
    String customerId,
    InsightUpSellCategoryCandidate candidate,
    List<InsightUpSellVariantCandidate> variantSuggestions,
  ) {
    return InsightAction(
      type: InsightActionType.expandGrid,
      label: 'Sugerir grade ampliada',
      route:
          '/orders/draft/grid?customerId=$customerId&categoryId=${candidate.categoryId}&suggestedGrid=true',
      customerId: customerId,
      payload: <String, Object?>{
        'customerId': customerId,
        'categoryId': candidate.categoryId,
        'categoryName': candidate.categoryName,
        'suggestedReason': 'up_sell',
        'variantQuantities': <String, Object?>{
          for (final variant in variantSuggestions)
            variant.variantId: variant.suggestedAdditionalQuantity,
        },
      },
    );
  }

  InsightSeverity _severityFor(double ticketGapPercentage) {
    if (ticketGapPercentage >= 0.5) {
      return InsightSeverity.high;
    }
    if (ticketGapPercentage >= 0.3) {
      return InsightSeverity.medium;
    }
    return InsightSeverity.low;
  }
}
