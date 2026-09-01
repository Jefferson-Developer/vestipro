import {
  type Insight,
  type InsightAction,
  type InsightContext,
  type InsightCrossSellCategoryCandidate,
  type InsightEvidence,
  type InsightRule,
  type InsightSeverity,
} from './insight-engine';

/** Maximum number of category suggestions bundled per customer insight. */
const MAX_SUGGESTIONS_PER_CUSTOMER = 3;

function isEligible(candidate: InsightCrossSellCategoryCandidate): boolean {
  return (
    !candidate.alreadyPurchasedByCustomer &&
    candidate.isAvailableInCustomerPriceList !== false &&
    candidate.isActiveCollection !== false &&
    candidate.peerAdoptionRate > 0
  );
}

function relevanceScore(candidate: InsightCrossSellCategoryCandidate): number {
  return candidate.peerAdoptionRate * candidate.peerAverageTicket;
}

function categoryAction(
  customerId: string,
  candidate: InsightCrossSellCategoryCandidate,
): InsightAction {
  return {
    type: 'startOrder',
    label: `Adicionar ${candidate.categoryName} ao pedido`,
    route: `/catalog?customerId=${customerId}&categoryId=${candidate.categoryId}&addToDraftOrder=true`,
    customerId,
    payload: {
      customerId,
      categoryId: candidate.categoryId,
      categoryName: candidate.categoryName,
      suggestedReason: 'cross_sell',
    },
  };
}

function severityFor(peerAdoptionRate: number): InsightSeverity {
  if (peerAdoptionRate >= 0.6) {
    return 'high';
  }
  if (peerAdoptionRate >= 0.35) {
    return 'medium';
  }
  return 'low';
}

/**
 * Identifies categories that a group of "similar customers" buys but a
 * given customer does not, suggesting cross-sell opportunities. The
 * comparison basis (the similarity group) is always explained in the
 * evidence, never a black box.
 */
export class CrossSellInsightRule implements InsightRule {
  evaluate(context: InsightContext): Insight[] {
    return context.dataset.crossSellSnapshots.flatMap((snapshot) => {
      if (
        snapshot.organizationId !== context.organizationId ||
        snapshot.companyId !== context.companyId
      ) {
        return [];
      }

      const eligible = snapshot.candidates
        .filter(isEligible)
        .sort((a, b) => relevanceScore(b) - relevanceScore(a));
      if (eligible.length === 0) {
        return [];
      }

      const suggestions = eligible.slice(0, MAX_SUGGESTIONS_PER_CUSTOMER);
      const top = suggestions[0];
      const expiresAt = new Date(
        context.asOf.getTime() + context.dataset.settings.lifetimeDays * 24 * 60 * 60 * 1000,
      );

      const evidence: InsightEvidence[] = [
        {
          code: 'similarity_group',
          label: 'Base de comparacao (clientes semelhantes)',
          value: snapshot.similarityGroupLabel,
          numericValue: snapshot.similarityGroupSize,
        },
        ...suggestions.flatMap((candidate) => [
          {
            code: `cross_sell_category_adoption:${candidate.categoryId}`,
            label: `Adesao de "${candidate.categoryName}" entre clientes semelhantes`,
            value: (candidate.peerAdoptionRate * 100).toFixed(1),
            numericValue: candidate.peerAdoptionRate * 100,
            unit: 'percent',
          },
          {
            code: `cross_sell_category_ticket:${candidate.categoryId}`,
            label: `Ticket medio de "${candidate.categoryName}" entre clientes semelhantes`,
            value: candidate.peerAverageTicket.toFixed(2),
            numericValue: candidate.peerAverageTicket,
            unit: 'BRL',
          },
        ]),
      ];

      return [
        {
          id: `cross_sell:${snapshot.recipientUserId}:${snapshot.customerId}:${top.categoryId}`,
          type: 'crossSell',
          title: `Oportunidade de cross-sell: ${snapshot.customerName}`,
          description:
            `${snapshot.customerName} ainda nao compra ${suggestions.length} ` +
            `categoria(s) populares entre clientes semelhantes ` +
            `(${snapshot.similarityGroupLabel}, ${snapshot.similarityGroupSize} ` +
            `clientes na base de comparacao). Categoria com maior potencial: ` +
            `${top.categoryName}, comprada por ` +
            `${(top.peerAdoptionRate * 100).toFixed(1)}% desses clientes, com ` +
            `ticket medio de R$ ${top.peerAverageTicket.toFixed(2)}.`,
          evidence,
          estimatedImpact: {
            amount: suggestions.reduce(
              (sum, candidate) => sum + candidate.peerAverageTicket,
              0,
            ),
            percentage: top.peerAdoptionRate,
            currencyCode: 'BRL',
          },
          severity: severityFor(top.peerAdoptionRate),
          confidenceScore: 0.65,
          recommendation:
            'Apresente as categorias sugeridas no proximo contato e ' +
            'aproveite para incluir os itens no pedido em rascunho do cliente.',
          quickAction: categoryAction(snapshot.customerId, top),
          secondaryActions: suggestions
            .slice(1)
            .map((candidate) => categoryAction(snapshot.customerId, candidate)),
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
  }
}
