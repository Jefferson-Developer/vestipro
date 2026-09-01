import {
  type Insight,
  type InsightAction,
  type InsightContext,
  type InsightEvidence,
  type InsightRule,
  type InsightSeverity,
  type InsightUpSellCategoryCandidate,
  type InsightUpSellVariantCandidate,
} from './insight-engine';

function ticketGapPercentage(
  candidate: InsightUpSellCategoryCandidate,
): number {
  if (candidate.peerAverageTicket <= 0) {
    return 0;
  }
  return (
    (candidate.peerAverageTicket - candidate.customerAverageTicket) /
    candidate.peerAverageTicket
  );
}

function isEligible(candidate: InsightUpSellCategoryCandidate): boolean {
  return (
    candidate.customerAverageTicket > 0 &&
    candidate.customerAverageTicket < candidate.peerAverageTicket
  );
}

function suggestedAdditionalQuantity(
  variant: InsightUpSellVariantCandidate,
): number {
  if (variant.desiredAdditionalQuantity <= 0 || variant.availableStock <= 0) {
    return 0;
  }
  return Math.min(variant.desiredAdditionalQuantity, variant.availableStock);
}

function expandGridAction(
  customerId: string,
  candidate: InsightUpSellCategoryCandidate,
  variantSuggestions: readonly InsightUpSellVariantCandidate[],
): InsightAction {
  const variantQuantities: Record<string, number> = {};
  for (const variant of variantSuggestions) {
    variantQuantities[variant.variantId] = suggestedAdditionalQuantity(variant);
  }
  return {
    type: 'expandGrid',
    label: 'Sugerir grade ampliada',
    route: `/orders/draft/grid?customerId=${customerId}&categoryId=${candidate.categoryId}&suggestedGrid=true`,
    customerId,
    payload: {
      customerId,
      categoryId: candidate.categoryId,
      categoryName: candidate.categoryName,
      suggestedReason: 'up_sell',
      variantQuantities,
    },
  };
}

function severityFor(gap: number): InsightSeverity {
  if (gap >= 0.5) {
    return 'high';
  }
  if (gap >= 0.3) {
    return 'medium';
  }
  return 'low';
}

/**
 * Identifies "up-sell" opportunities: categories the customer already buys
 * where their average ticket/quantity per order sits below a group of
 * similar customers with higher volume in that same category (unlike
 * cross-sell, which only looks at categories the customer does not buy
 * yet). Every quantity suggested for the "Sugerir grade ampliada" quick
 * action is capped by the variant's real stock balance.
 */
export class UpSellInsightRule implements InsightRule {
  evaluate(context: InsightContext): Insight[] {
    const settings = context.dataset.settings;
    const minimumGap = settings.upSellMinimumTicketGapPercentage;
    const expiresAt = new Date(
      context.asOf.getTime() + settings.lifetimeDays * 24 * 60 * 60 * 1000,
    );

    return context.dataset.upSellSnapshots.flatMap((snapshot) => {
      if (
        snapshot.organizationId !== context.organizationId ||
        snapshot.companyId !== context.companyId
      ) {
        return [];
      }

      return snapshot.candidates.flatMap((candidate) => {
        if (!isEligible(candidate)) {
          return [];
        }
        const gap = ticketGapPercentage(candidate);
        if (gap < minimumGap) {
          return [];
        }

        const variantSuggestions = (candidate.variantCandidates ?? []).filter(
          (variant) => suggestedAdditionalQuantity(variant) > 0,
        );
        if (variantSuggestions.length === 0) {
          return [];
        }

        const evidence: InsightEvidence[] = [
          {
            code: 'up_sell_comparison_group',
            label:
              'Base de comparacao (clientes semelhantes de maior volume)',
            value: snapshot.comparisonGroupLabel,
            numericValue: snapshot.comparisonGroupSize,
          },
          {
            code: `up_sell_customer_average_ticket:${candidate.categoryId}`,
            label: `Ticket medio atual do cliente em "${candidate.categoryName}"`,
            value: candidate.customerAverageTicket.toFixed(2),
            numericValue: candidate.customerAverageTicket,
            unit: 'BRL',
          },
          {
            code: `up_sell_peer_average_ticket:${candidate.categoryId}`,
            label: `Ticket medio de clientes semelhantes de maior volume em "${candidate.categoryName}"`,
            value: candidate.peerAverageTicket.toFixed(2),
            numericValue: candidate.peerAverageTicket,
            unit: 'BRL',
          },
          {
            code: `up_sell_ticket_gap:${candidate.categoryId}`,
            label: 'Diferenca percentual em relacao ao grupo de comparacao',
            value: (gap * 100).toFixed(1),
            numericValue: gap * 100,
            unit: 'percent',
          },
        ];

        return [
          {
            id: `up_sell:${snapshot.recipientUserId}:${snapshot.customerId}:${candidate.categoryId}`,
            type: 'upSell',
            title: `Oportunidade de up-sell: ${snapshot.customerName}`,
            description:
              `${snapshot.customerName} compra ${candidate.categoryName} com ` +
              `ticket medio de R$ ${candidate.customerAverageTicket.toFixed(2)}, ` +
              `${(gap * 100).toFixed(1)}% abaixo da media de clientes ` +
              `semelhantes de maior volume (${snapshot.comparisonGroupLabel}, ` +
              `${snapshot.comparisonGroupSize} clientes na base de ` +
              `comparacao), que compram em media R$ ` +
              `${candidate.peerAverageTicket.toFixed(2)} nessa categoria.`,
            evidence,
            estimatedImpact: {
              amount: candidate.peerAverageTicket - candidate.customerAverageTicket,
              percentage: gap,
              currencyCode: 'BRL',
            },
            severity: severityFor(gap),
            confidenceScore: 0.6,
            recommendation:
              `Sugira ampliar a grade de "${candidate.categoryName}" no ` +
              'proximo pedido, dentro da disponibilidade real de estoque.',
            quickAction: expandGridAction(
              snapshot.customerId,
              candidate,
              variantSuggestions,
            ),
            secondaryActions: [],
            organizationId: snapshot.organizationId,
            companyId: snapshot.companyId,
            recipientUserId: snapshot.recipientUserId,
            customerId: snapshot.customerId,
            generatedAt: context.asOf,
            expiresAt,
            status: 'fresh',
          },
        ];
      });
    });
  }
}
