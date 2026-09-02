import {
  type Insight,
  type InsightAction,
  type InsightContext,
  type InsightEvidence,
  type InsightInsufficientMixCategoryCandidate,
  type InsightOrganizationSettings,
  type InsightRule,
  type InsightSeverity,
} from './insight-engine';

const MAX_MISSING_CATEGORIES_PER_CUSTOMER = 5;

function resolveExcludedCategoryIds(
  settings: InsightOrganizationSettings,
  segment: string | null | undefined,
): Set<string> {
  const normalized = segment?.trim().toLowerCase();
  const bySegment = normalized
    ? settings.insufficientMixExcludedCategoryIdsBySegment[normalized]
    : undefined;
  if (!bySegment || bySegment.length === 0) {
    return new Set(settings.insufficientMixExcludedCategoryIds);
  }
  return new Set([
    ...settings.insufficientMixExcludedCategoryIds,
    ...bySegment,
  ]);
}

function missingCategoriesAction(
  customerId: string,
  missingCategories: readonly InsightInsufficientMixCategoryCandidate[],
): InsightAction {
  const categoryIds = missingCategories.map((candidate) => candidate.categoryId);
  const categoryNames = missingCategories.map(
    (candidate) => candidate.categoryName,
  );
  return {
    type: 'viewCategory',
    label: 'Ver categorias ausentes',
    route: `/catalog?customerId=${customerId}&categoryIds=${categoryIds.join(',')}&addToDraftOrder=true`,
    customerId,
    payload: {
      customerId,
      categoryIds,
      categoryNames,
      suggestedReason: 'insufficient_mix',
    },
  };
}

function severityFor(gap: number): InsightSeverity {
  if (gap >= 0.6) {
    return 'high';
  }
  if (gap >= 0.35) {
    return 'medium';
  }
  return 'low';
}

/**
 * Identifies customers whose mix (number of distinct categories purchased)
 * sits below the benchmark of an organization-configured comparison group
 * (segment, region, porte, or a combination). The benchmark is never
 * hardcoded: it is derived, category by category, from each candidate's
 * `peerAdoptionRate` — by linearity of expectation, the sum of adoption
 * rates across the comparison universe equals the group's average number of
 * distinct categories purchased per customer — so the comparison basis is
 * always explainable, never a black box.
 */
export class InsufficientMixInsightRule implements InsightRule {
  evaluate(context: InsightContext): Insight[] {
    const settings = context.dataset.settings;
    const threshold = settings.insufficientMixThresholdPercentage;
    const expiresAt = new Date(
      context.asOf.getTime() + settings.lifetimeDays * 24 * 60 * 60 * 1000,
    );

    return context.dataset.insufficientMixSnapshots.flatMap((snapshot) => {
      if (
        snapshot.organizationId !== context.organizationId ||
        snapshot.companyId !== context.companyId
      ) {
        return [];
      }

      const excludedCategoryIds = resolveExcludedCategoryIds(
        settings,
        snapshot.segment,
      );
      const eligibleCandidates = snapshot.candidates.filter(
        (candidate) => !excludedCategoryIds.has(candidate.categoryId),
      );
      if (eligibleCandidates.length === 0) {
        return [];
      }

      const benchmarkCategoryCount = eligibleCandidates.reduce(
        (sum, candidate) => sum + candidate.peerAdoptionRate,
        0,
      );
      if (benchmarkCategoryCount <= 0) {
        return [];
      }

      const customerCategoryCount = eligibleCandidates.filter(
        (candidate) => candidate.purchasedByCustomer,
      ).length;
      const ratio = customerCategoryCount / benchmarkCategoryCount;
      if (ratio >= threshold) {
        return [];
      }

      const missingCategories = eligibleCandidates
        .filter((candidate) => !candidate.purchasedByCustomer)
        .sort((a, b) => b.peerAdoptionRate - a.peerAdoptionRate);
      if (missingCategories.length === 0) {
        return [];
      }

      const suggestions = missingCategories.slice(
        0,
        MAX_MISSING_CATEGORIES_PER_CUSTOMER,
      );
      const gap = 1 - ratio;

      const evidence: InsightEvidence[] = [
        {
          code: 'insufficient_mix_comparison_group',
          label: 'Base de comparacao (clientes semelhantes)',
          value: snapshot.comparisonGroupLabel,
          numericValue: snapshot.comparisonGroupSize,
        },
        {
          code: 'insufficient_mix_customer_category_count',
          label: 'Categorias distintas compradas pelo cliente',
          value: `${customerCategoryCount}`,
          numericValue: customerCategoryCount,
        },
        {
          code: 'insufficient_mix_benchmark_category_count',
          label: 'Benchmark de categorias distintas do grupo de comparacao',
          value: benchmarkCategoryCount.toFixed(1),
          numericValue: benchmarkCategoryCount,
        },
        {
          code: 'insufficient_mix_ratio',
          label: 'Percentual do benchmark atingido pelo cliente',
          value: (ratio * 100).toFixed(1),
          numericValue: ratio * 100,
          unit: 'percent',
        },
        ...suggestions.map((candidate) => ({
          code: `insufficient_mix_missing_category:${candidate.categoryId}`,
          label: `Categoria ausente no mix: "${candidate.categoryName}"`,
          value: (candidate.peerAdoptionRate * 100).toFixed(1),
          numericValue: candidate.peerAdoptionRate * 100,
          unit: 'percent',
        })),
      ];

      return [
        {
          id: `insufficient_mix:${snapshot.recipientUserId}:${snapshot.customerId}`,
          type: 'insufficientMix',
          title: `Mix abaixo do ideal: ${snapshot.customerName}`,
          description:
            `${snapshot.customerName} compra ${customerCategoryCount} ` +
            `categoria(s) distinta(s), abaixo do benchmark de ` +
            `${benchmarkCategoryCount.toFixed(1)} de clientes semelhantes ` +
            `(${snapshot.comparisonGroupLabel}, ` +
            `${snapshot.comparisonGroupSize} clientes na base de ` +
            `comparacao) — ${(ratio * 100).toFixed(1)}% do benchmark do ` +
            'grupo.',
          evidence,
          estimatedImpact: {
            percentage: gap,
          },
          severity: severityFor(gap),
          confidenceScore: 0.6,
          recommendation:
            'Apresente as categorias ausentes no proximo contato e ' +
            'aproveite para incluir os itens no pedido em rascunho do ' +
            'cliente.',
          quickAction: missingCategoriesAction(
            snapshot.customerId,
            suggestions,
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
  }
}
