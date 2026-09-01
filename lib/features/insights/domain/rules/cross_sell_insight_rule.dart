import 'package:injectable/injectable.dart';

import '../entities/insight.dart';
import '../entities/insight_action.dart';
import '../entities/insight_context.dart';
import '../entities/insight_cross_sell_category_candidate.dart';
import '../entities/insight_estimated_impact.dart';
import '../entities/insight_evidence.dart';
import '../services/insight_rule.dart';
import '../value_objects/insight_action_type.dart';
import '../value_objects/insight_severity.dart';
import '../value_objects/insight_status.dart';
import '../value_objects/insight_type.dart';

/// Maximum number of category suggestions bundled into a single cross-sell
/// insight per customer.
const int _maxSuggestionsPerCustomer = 3;

/// Identifies categories that a group of "similar customers" buys but a
/// given customer does not, suggesting cross-sell opportunities. The
/// comparison basis (the similarity group) is always explained in the
/// evidence, never a black box.
@lazySingleton
final class CrossSellInsightRule implements InsightRule {
  const CrossSellInsightRule();

  @override
  List<Insight> evaluate(InsightContext context) {
    final insights = <Insight>[];

    for (final snapshot in context.dataset.crossSellSnapshots) {
      if (snapshot.organizationId != context.organizationId ||
          snapshot.companyId != context.companyId) {
        continue;
      }

      final eligible =
          snapshot.candidates.where((candidate) => candidate.isEligible).toList()
            ..sort(
              (a, b) => b.relevanceScore.compareTo(a.relevanceScore),
            );
      if (eligible.isEmpty) {
        continue;
      }

      final suggestions = eligible.take(_maxSuggestionsPerCustomer).toList();
      final top = suggestions.first;
      final expiresAt = context.asOf.add(
        context.dataset.settings.defaultLifetime,
      );

      insights.add(
        Insight(
          id: 'cross_sell:${snapshot.recipientUserId}:${snapshot.customerId}:${top.categoryId}',
          type: InsightType.crossSell,
          title: 'Oportunidade de cross-sell: ${snapshot.customerName}',
          description:
              '${snapshot.customerName} ainda nao compra '
              '${suggestions.length} categoria(s) populares entre clientes '
              'semelhantes (${snapshot.similarityGroupLabel}, '
              '${snapshot.similarityGroupSize} clientes na base de '
              'comparacao). Categoria com maior potencial: '
              '${top.categoryName}, comprada por '
              '${(top.peerAdoptionRate * 100).toStringAsFixed(1)}% desses '
              'clientes, com ticket medio de R\$ '
              '${top.peerAverageTicket.toStringAsFixed(2)}.',
          evidence: <InsightEvidence>[
            InsightEvidence(
              code: 'similarity_group',
              label: 'Base de comparacao (clientes semelhantes)',
              value: snapshot.similarityGroupLabel,
              numericValue: snapshot.similarityGroupSize.toDouble(),
            ),
            for (final candidate in suggestions) ...<InsightEvidence>[
              InsightEvidence(
                code: 'cross_sell_category_adoption:${candidate.categoryId}',
                label:
                    'Adesao de "${candidate.categoryName}" entre clientes semelhantes',
                value: (candidate.peerAdoptionRate * 100).toStringAsFixed(1),
                numericValue: candidate.peerAdoptionRate * 100,
                unit: 'percent',
              ),
              InsightEvidence(
                code: 'cross_sell_category_ticket:${candidate.categoryId}',
                label:
                    'Ticket medio de "${candidate.categoryName}" entre clientes semelhantes',
                value: candidate.peerAverageTicket.toStringAsFixed(2),
                numericValue: candidate.peerAverageTicket,
                unit: 'BRL',
              ),
            ],
          ],
          estimatedImpact: InsightEstimatedImpact(
            amount: suggestions.fold<double>(
              0,
              (sum, candidate) => sum + candidate.peerAverageTicket,
            ),
            percentage: top.peerAdoptionRate,
          ),
          severity: _severityFor(top.peerAdoptionRate),
          confidenceScore: 0.65,
          recommendation:
              'Apresente as categorias sugeridas no proximo contato e '
              'aproveite para incluir os itens no pedido em rascunho do '
              'cliente.',
          quickAction: _categoryAction(snapshot.customerId, top),
          secondaryActions: <InsightAction>[
            for (final candidate in suggestions.skip(1))
              _categoryAction(snapshot.customerId, candidate),
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

  InsightAction _categoryAction(
    String customerId,
    InsightCrossSellCategoryCandidate candidate,
  ) {
    return InsightAction(
      type: InsightActionType.startOrder,
      label: 'Adicionar ${candidate.categoryName} ao pedido',
      route:
          '/catalog?customerId=$customerId&categoryId=${candidate.categoryId}&addToDraftOrder=true',
      customerId: customerId,
      payload: <String, Object?>{
        'customerId': customerId,
        'categoryId': candidate.categoryId,
        'categoryName': candidate.categoryName,
        'suggestedReason': 'cross_sell',
      },
    );
  }

  InsightSeverity _severityFor(double peerAdoptionRate) {
    if (peerAdoptionRate >= 0.6) {
      return InsightSeverity.high;
    }
    if (peerAdoptionRate >= 0.35) {
      return InsightSeverity.medium;
    }
    return InsightSeverity.low;
  }
}
