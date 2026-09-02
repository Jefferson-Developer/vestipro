import {
  type Insight,
  type InsightAction,
  type InsightContext,
  type InsightEvidence,
  type InsightRule,
  type InsightSeverity,
  type InsightStockPositionSnapshot,
} from './insight-engine';

function resolveByCategory(
  categoryId: string,
  thresholdsByCategory: Record<string, number>,
  fallback: number,
): number {
  const normalized = categoryId.trim();
  if (!normalized) {
    return fallback;
  }
  return thresholdsByCategory[normalized] ?? fallback;
}

function displayName(snapshot: InsightStockPositionSnapshot): string {
  return snapshot.variantLabel
    ? `${snapshot.productName} (${snapshot.variantLabel})`
    : snapshot.productName;
}

function severityFor(coverageExcessRatio: number): InsightSeverity {
  if (coverageExcessRatio >= 1.0) {
    return 'high';
  }
  if (coverageExcessRatio >= 0.5) {
    return 'medium';
  }
  return 'low';
}

function suggestCampaignAction(
  snapshot: InsightStockPositionSnapshot,
  entityId: string,
): InsightAction {
  const variantQuery = snapshot.variantId
    ? `&variantId=${snapshot.variantId}`
    : '';
  return {
    type: 'suggestCampaign',
    label: 'Sugerir campanha/desconto',
    route:
      `/pricing/campaigns/new?productId=${snapshot.productId}` +
      `${variantQuery}&categoryId=${snapshot.categoryId}` +
      '&suggestedReason=high_stock_low_turnover',
    productId: entityId,
    payload: {
      productId: snapshot.productId,
      variantId: snapshot.variantId ?? null,
      categoryId: snapshot.categoryId,
      suggestedReason: 'high_stock_low_turnover',
    },
  };
}

/**
 * Identifies products/variants whose stock balance covers more days than
 * the organization/category-configured coverage threshold while rotating
 * below the minimum expected turnover index (TASK-094) — excess stock
 * parked with little to no sales movement, and therefore candidates for a
 * liquidation/promotional campaign.
 *
 * This is the mirror-opposite signal of `ReplenishmentSuggestionInsightRule`:
 * by construction, the two rules can never both fire for the same
 * product/variant in the same cycle, as long as the organization's
 * thresholds are configured consistently.
 *
 * Discontinued/out-of-current-collection products are not excluded here —
 * they are, in fact, prime liquidation candidates.
 */
export class HighStockLowTurnoverInsightRule implements InsightRule {
  evaluate(context: InsightContext): Insight[] {
    const settings = context.dataset.settings;
    const expiresAt = new Date(
      context.asOf.getTime() + settings.lifetimeDays * 24 * 60 * 60 * 1000,
    );

    return context.dataset.stockPositionSnapshots.flatMap((snapshot) => {
      if (
        snapshot.organizationId !== context.organizationId ||
        snapshot.companyId !== context.companyId
      ) {
        return [];
      }

      const coverageThreshold = resolveByCategory(
        snapshot.categoryId,
        settings.highStockCoverageDaysThresholdByCategory,
        settings.highStockCoverageDaysThreshold,
      );
      const turnoverThreshold = resolveByCategory(
        snapshot.categoryId,
        settings.lowTurnoverIndexThresholdByCategory,
        settings.lowTurnoverIndexThreshold,
      );
      if (
        snapshot.coverageDays < coverageThreshold ||
        snapshot.turnoverIndex > turnoverThreshold
      ) {
        return [];
      }

      const entityId = snapshot.variantId ?? snapshot.productId;
      const name = displayName(snapshot);
      const coverageExcessRatio =
        coverageThreshold <= 0
          ? 1
          : (snapshot.coverageDays - coverageThreshold) / coverageThreshold;

      const evidence: InsightEvidence[] = [
        {
          code: 'high_stock_current_quantity',
          label: 'Saldo atual em estoque',
          value: `${snapshot.currentStockQuantity}`,
          numericValue: snapshot.currentStockQuantity,
          unit: 'unidades',
        },
        {
          code: 'high_stock_coverage_days',
          label: 'Cobertura estimada em dias',
          value: snapshot.coverageDays.toFixed(1),
          numericValue: snapshot.coverageDays,
          unit: 'dias',
        },
        {
          code: 'high_stock_turnover_index',
          label: 'Indice de giro',
          value: snapshot.turnoverIndex.toFixed(2),
          numericValue: snapshot.turnoverIndex,
        },
        {
          code: 'high_stock_days_without_relevant_sale',
          label: 'Dias parado sem saida relevante',
          value: `${snapshot.daysWithoutRelevantSale}`,
          numericValue: snapshot.daysWithoutRelevantSale,
          unit: 'dias',
        },
      ];

      return [
        {
          id: `high_stock_low_turnover:${snapshot.recipientUserId}:${entityId}`,
          type: 'highStockLowTurnover',
          title: `Estoque alto e giro baixo: ${name}`,
          description:
            `${name} tem ${snapshot.currentStockQuantity} unidade(s) em ` +
            `estoque, com cobertura estimada de ` +
            `${snapshot.coverageDays.toFixed(0)} dia(s) — acima do limiar ` +
            `de ${coverageThreshold.toFixed(0)} dia(s) para a categoria ` +
            `${snapshot.categoryName} — e indice de giro de ` +
            `${snapshot.turnoverIndex.toFixed(2)}, abaixo do minimo ` +
            `esperado de ${turnoverThreshold.toFixed(2)}. Sem saida ` +
            `relevante ha ${snapshot.daysWithoutRelevantSale} dia(s).`,
          evidence,
          estimatedImpact: {
            percentage: coverageExcessRatio,
          },
          severity: severityFor(coverageExcessRatio),
          confidenceScore: 0.6,
          recommendation:
            'Avalie incluir o produto em uma campanha promocional ou ' +
            'liquidacao para acelerar o giro e liberar capital parado em ' +
            'estoque.',
          quickAction: suggestCampaignAction(snapshot, entityId),
          secondaryActions: [],
          organizationId: snapshot.organizationId,
          companyId: snapshot.companyId,
          recipientUserId: snapshot.recipientUserId,
          productId: entityId,
          generatedAt: context.asOf,
          expiresAt,
          status: 'fresh',
        },
      ];
    });
  }
}
