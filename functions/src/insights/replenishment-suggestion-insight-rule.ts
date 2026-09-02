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

function severityFor(coverageDeficitRatio: number): InsightSeverity {
  if (coverageDeficitRatio >= 0.7) {
    return 'high';
  }
  if (coverageDeficitRatio >= 0.3) {
    return 'medium';
  }
  return 'low';
}

function notifyReplenishmentAction(
  snapshot: InsightStockPositionSnapshot,
  entityId: string,
): InsightAction {
  const variantQuery = snapshot.variantId
    ? `&variantId=${snapshot.variantId}`
    : '';
  return {
    type: 'notifyReplenishment',
    label: 'Notificar compras/reposicao',
    route:
      `/inventory/replenishment?productId=${snapshot.productId}` +
      `${variantQuery}&suggestedReason=replenishment_suggestion`,
    productId: entityId,
    payload: {
      productId: snapshot.productId,
      variantId: snapshot.variantId ?? null,
      categoryId: snapshot.categoryId,
      suggestedReorderPointQuantity: snapshot.suggestedReorderPointQuantity,
      suggestedReason: 'replenishment_suggestion',
    },
  };
}

/**
 * Identifies products/variants with a high turnover index (TASK-094) whose
 * stock coverage has dropped below the organization/category configured
 * minimum, signaling a risk of rupture — surfaced early enough for the
 * purchasing/replenishment team to act, cross-referencing the low-stock
 * alerts already raised by TASK-093.
 *
 * This is the mirror-opposite signal of `HighStockLowTurnoverInsightRule`:
 * by construction, the two rules can never both fire for the same
 * product/variant in the same cycle, as long as the organization's
 * thresholds are configured consistently.
 *
 * This rule never generates a purchase order automatically — it only raises
 * an insight/notification for the responsible team; automating the actual
 * replenishment is out of scope (EPIC-27). Discontinued/out of
 * current-collection products are always excluded.
 */
export class ReplenishmentSuggestionInsightRule implements InsightRule {
  evaluate(context: InsightContext): Insight[] {
    const settings = context.dataset.settings;
    const expiresAt = new Date(
      context.asOf.getTime() + settings.lifetimeDays * 24 * 60 * 60 * 1000,
    );

    return context.dataset.stockPositionSnapshots.flatMap((snapshot) => {
      if (
        snapshot.organizationId !== context.organizationId ||
        snapshot.companyId !== context.companyId ||
        snapshot.isDiscontinued
      ) {
        return [];
      }

      const coverageThreshold = resolveByCategory(
        snapshot.categoryId,
        settings.replenishmentLowCoverageDaysThresholdByCategory,
        settings.replenishmentLowCoverageDaysThreshold,
      );
      const turnoverThreshold = resolveByCategory(
        snapshot.categoryId,
        settings.replenishmentHighTurnoverIndexThresholdByCategory,
        settings.replenishmentHighTurnoverIndexThreshold,
      );
      if (
        snapshot.coverageDays > coverageThreshold ||
        snapshot.turnoverIndex < turnoverThreshold
      ) {
        return [];
      }

      const entityId = snapshot.variantId ?? snapshot.productId;
      const name = displayName(snapshot);
      const coverageDeficitRatio =
        coverageThreshold <= 0
          ? 1
          : (coverageThreshold - snapshot.coverageDays) / coverageThreshold;
      const clampedDeficitRatio = Math.min(1, Math.max(0, coverageDeficitRatio));

      const evidence: InsightEvidence[] = [
        {
          code: 'replenishment_turnover_index',
          label: 'Indice de giro',
          value: snapshot.turnoverIndex.toFixed(2),
          numericValue: snapshot.turnoverIndex,
        },
        {
          code: 'replenishment_coverage_days',
          label: 'Cobertura atual em dias',
          value: snapshot.coverageDays.toFixed(1),
          numericValue: snapshot.coverageDays,
          unit: 'dias',
        },
        {
          code: 'replenishment_suggested_reorder_point',
          label: 'Ponto de ressuprimento sugerido',
          value: snapshot.suggestedReorderPointQuantity.toFixed(0),
          numericValue: snapshot.suggestedReorderPointQuantity,
          unit: 'unidades',
        },
        {
          code: 'replenishment_average_daily_consumption',
          label: 'Consumo medio diario recente',
          value: snapshot.averageDailyConsumption.toFixed(2),
          numericValue: snapshot.averageDailyConsumption,
          unit: 'unidades/dia',
        },
      ];

      return [
        {
          id: `replenishment_suggestion:${snapshot.recipientUserId}:${entityId}`,
          type: 'replenishmentSuggestion',
          title: `Risco de ruptura, sugestao de reposicao: ${name}`,
          description:
            `${name} tem indice de giro de ` +
            `${snapshot.turnoverIndex.toFixed(2)} — acima do minimo de ` +
            `${turnoverThreshold.toFixed(2)} esperado para a categoria ` +
            `${snapshot.categoryName} — mas cobertura atual de apenas ` +
            `${snapshot.coverageDays.toFixed(0)} dia(s), abaixo do limiar ` +
            `de ${coverageThreshold.toFixed(0)} dia(s). Ponto de ` +
            `ressuprimento sugerido: ` +
            `${snapshot.suggestedReorderPointQuantity.toFixed(0)} unidade(s).`,
          evidence,
          estimatedImpact: {
            percentage: clampedDeficitRatio,
          },
          severity: severityFor(coverageDeficitRatio),
          confidenceScore: 0.65,
          recommendation:
            'Notifique o time de compras/reposicao para avaliar um novo ' +
            'pedido antes que o estoque se esgote.',
          quickAction: notifyReplenishmentAction(snapshot, entityId),
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
