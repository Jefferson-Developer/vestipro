import { isRevenueRecognized, type OrderAggregationFact } from '../aggregations/aggregation-shared';
import type { ProductLabel } from '../aggregations/aggregation-builders';

/**
 * Server-side, shared domain service for EPIC-28's behavioral product
 * recommendation model (TASK-190). Every function here is pure (no
 * Firestore, no `firebase-functions`) — same "shared calculation core" shape
 * already established by `../demand-forecast/demand-forecast-shared.ts`
 * (TASK-185) and `../replenishment/replenishment-calculation-shared.ts`
 * (TASK-184).
 *
 * ## Sinais usados (documentação exigida por `tasks.md`/TASK-190)
 *
 * O modelo é **co-ocorrência de itens dentro do mesmo pedido** ("basket
 * analysis"/"market basket"), calculado exclusivamente a partir de `Order`
 * documents já persistidos (`organizations/{organizationId}/orders`),
 * reaproveitando literalmente `OrderAggregationFact`/`isRevenueRecognized`/
 * `extractOrderFact` de `../aggregations/aggregation-shared.ts` (TASK-133) —
 * nunca uma segunda leitura/parse de pedido. Concretamente, cada pedido cujo
 * status já é reconhecido como atividade comercial real
 * (`REVENUE_RECOGNIZED_ORDER_STATUSES`) vira uma "cesta" (basket) com o
 * conjunto de produtos distintos daquele pedido; dois produtos que aparecem
 * juntos em muitas cestas têm um sinal forte de "comprados juntos"
 * (`event: product_added_to_order` + `order_submitted`, seção 23 de
 * `tasks.md`).
 *
 * `product_viewed` (também citado na seção 23 de `tasks.md`) é
 * deliberadamente **não** usado nesta versão do modelo: esse evento hoje só
 * é emitido para o Firebase Analytics (client SDK) e nunca é persistido em
 * Firestore de forma consultável por uma Cloud Function — usá-lo exigiria
 * primeiro linkar o projeto ao BigQuery e construir um pipeline de
 * exportação/ingestão, o que é uma decisão de infraestrutura de projeto
 * (Firebase Console/GCP), fora do alcance desta task. Essa limitação é
 * documentada aqui e na conclusão da task para que uma v2 do modelo possa
 * incorporar o sinal de navegação quando essa infraestrutura existir.
 *
 * "Similaridade entre clientes" (também citada no escopo da task) é obtida
 * de forma indireta e honesta: o escopo `customer` agrega a co-ocorrência de
 * todos os produtos que o próprio cliente já comprou — um clássico
 * item-based collaborative filtering, cuja explicação ("você comprou X;
 * clientes com o mesmo perfil de compra também levam Y") é sempre exposta
 * junto com a recomendação, nunca uma caixa preta.
 *
 * ## Cadência de retraining (documentação exigida por `tasks.md`/TASK-190)
 *
 * Semanal (`calculateProductRecommendations`, `every monday 04:30`) — mesma
 * cadência de `calculateReplenishmentSuggestions` (TASK-184): uma
 * recomendação de compra não precisa ser recalculada todo dia, e uma
 * cadência semanal mantém a leitura de {@link DEFAULT_LOOKBACK_DAYS} dias de
 * pedidos limitada por execução.
 */

export const PRODUCT_RECOMMENDATION_MODEL = 'itemCoOccurrenceV1';
export const PRODUCT_RECOMMENDATION_MODEL_VERSION = 'co-occurrence-v1';

/** Rolling window of order history the co-occurrence model is computed
 * from — fixed, not configurable per organization yet (same simplification
 * already accepted by `DEFAULT_LOOKBACK_MONTHS` in
 * `demand-forecast-shared.ts`/TASK-185). */
export const DEFAULT_LOOKBACK_DAYS = 180;

/** Maximum recommended items ever persisted for one scope (product/customer/
 * segment) — keeps every document small and the UI section reviewable. */
export const MAX_RECOMMENDATIONS_PER_SCOPE = 8;

/** Minimum number of baskets two products must have co-occurred in before a
 * `product`-scope pair is considered a real "frequently bought together"
 * signal — a single shared order is noise, not a pattern. */
export const MIN_CO_OCCURRENCE_COUNT = 2;

/** Fixed `scopeId` for the company-wide "mais vendidos" fallback/segment
 * recommendation (`scopeType: 'segment'`) — a single document per company. */
export const SEGMENT_BEST_SELLERS_SCOPE_ID = 'company-best-sellers';

export type ProductRecommendationScopeType = 'product' | 'customer' | 'segment';

export type RecommendationReasonCode =
  | 'boughtTogether'
  | 'purchaseHistorySimilarity'
  | 'bestSeller';

export interface RecommendationItem {
  productId: string;
  productName: string;
  /** Always `>= 0`. For `boughtTogether`/`purchaseHistorySimilarity` this is
   * a confidence ratio (`0..1`, co-occurrence count divided by the anchor
   * product's own purchase count); for `bestSeller` it is the raw basket
   * count the product appeared in — the two are never compared against each
   * other, only ranked within their own scope/reason. */
  score: number;
  reasonCode: RecommendationReasonCode;
  /** Human-readable explanation, always naming the concrete evidence behind
   * the suggestion — never a recommendation without a visible justification
   * (`tasks.md`/TASK-190: "nunca uma lista sem justificativa alguma"). */
  reasonLabel: string;
  relatedProductId: string | null;
  relatedProductName: string | null;
}

export interface ProductRecommendationResult {
  scopeType: ProductRecommendationScopeType;
  scopeId: string;
  items: RecommendationItem[];
  /** `true` when [items] came from the company-wide best-sellers fallback
   * instead of a personalized/item-specific signal — always surfaced to the
   * UI so a fallback is never presented as if it were personalized. */
  fallbackApplied: boolean;
  /** `true` when [items] is empty because there is genuinely not enough data
   * yet — never because of an error. A caller must render this as an
   * explicit "sem dado suficiente" state, never silently hide the section
   * without explanation (`tasks.md`/TASK-190's own fallback rule). */
  insufficientData: boolean;
  /** Machine-readable list of which signal(s) fed this exact result —
   * `[]` only when [insufficientData] is `true`. */
  signalsUsed: string[];
}

export interface OrderBasket {
  orderId: string;
  customerId: string;
  /** Distinct product ids of the order — a product bought twice in the same
   * order still only counts once per basket for co-occurrence purposes. */
  productIds: string[];
}

/** Builds one basket per revenue-recognized order (`isRevenueRecognized`,
 * reused from `aggregation-shared.ts` — never redefined here), discarding
 * orders with zero distinct products (should not normally happen, defensive
 * only). */
export function buildBaskets(
  facts: readonly OrderAggregationFact[],
): OrderBasket[] {
  return facts
    .filter((fact) => isRevenueRecognized(fact))
    .map((fact) => ({
      orderId: fact.id,
      customerId: fact.customerId,
      productIds: [...new Set(fact.items.map((item) => item.productId))],
    }))
    .filter((basket) => basket.productIds.length > 0);
}

export interface CoOccurrenceModel {
  /** `pairCounts.get(a).get(b)` = number of baskets containing both `a` and
   * `b` — symmetric (`pairCounts.get(a).get(b) === pairCounts.get(b).get(a)`). */
  pairCounts: Map<string, Map<string, number>>;
  /** Number of distinct baskets containing each product. */
  purchaseCounts: Map<string, number>;
}

export function computeCoOccurrence(
  baskets: readonly OrderBasket[],
): CoOccurrenceModel {
  const pairCounts = new Map<string, Map<string, number>>();
  const purchaseCounts = new Map<string, number>();

  for (const basket of baskets) {
    for (const productId of basket.productIds) {
      purchaseCounts.set(productId, (purchaseCounts.get(productId) ?? 0) + 1);
    }
    for (let i = 0; i < basket.productIds.length; i += 1) {
      for (let j = 0; j < basket.productIds.length; j += 1) {
        if (i === j) continue;
        const a = basket.productIds[i];
        const b = basket.productIds[j];
        const row = pairCounts.get(a) ?? new Map<string, number>();
        row.set(b, (row.get(b) ?? 0) + 1);
        pairCounts.set(a, row);
      }
    }
  }

  return { pairCounts, purchaseCounts };
}

function productName(
  productLabels: ReadonlyMap<string, ProductLabel>,
  productId: string,
): string {
  return productLabels.get(productId)?.name ?? productId;
}

function roundScore(value: number): number {
  if (!Number.isFinite(value)) return 0;
  return Math.round(value * 10000) / 10000;
}

/** Company-wide "mais vendidos" ranking (by number of baskets a product
 * appeared in, desc — ties broken by `productId` for a deterministic order),
 * used both as the standalone `segment` scope and as the fallback source for
 * `customer`-scope recommendations with insufficient personal history. */
export function computeBestSellers(params: {
  model: CoOccurrenceModel;
  productLabels: ReadonlyMap<string, ProductLabel>;
  lookbackDays: number;
  excludeProductIds?: ReadonlySet<string>;
  limit?: number;
}): RecommendationItem[] {
  const exclude = params.excludeProductIds ?? new Set<string>();
  const limit = params.limit ?? MAX_RECOMMENDATIONS_PER_SCOPE;

  return [...params.model.purchaseCounts.entries()]
    .filter(([productId]) => !exclude.has(productId))
    .sort(([aId, aCount], [bId, bCount]) => bCount - aCount || aId.localeCompare(bId))
    .slice(0, limit)
    .map(([productId, count]) => ({
      productId,
      productName: productName(params.productLabels, productId),
      score: count,
      reasonCode: 'bestSeller' as const,
      reasonLabel:
        `Um dos produtos mais vendidos da empresa nos últimos ` +
        `${params.lookbackDays} dias (presente em ${count} pedido(s)).`,
      relatedProductId: null,
      relatedProductName: null,
    }));
}

/** `segment` scope: the company-wide best-sellers themselves, exposed as a
 * standalone recommendation (e.g. a generic "mais vendidos" catalog shelf,
 * usable without a specific product/customer context). */
export function buildSegmentScopeRecommendation(params: {
  model: CoOccurrenceModel;
  productLabels: ReadonlyMap<string, ProductLabel>;
  lookbackDays: number;
}): ProductRecommendationResult {
  const items = computeBestSellers(params);
  return {
    scopeType: 'segment',
    scopeId: SEGMENT_BEST_SELLERS_SCOPE_ID,
    items,
    fallbackApplied: false,
    insufficientData: items.length === 0,
    signalsUsed: items.length > 0 ? ['order_submitted_item_co_occurrence'] : [],
  };
}

/** `product` scope: "clientes que compraram X também compraram Y", for the
 * catalog grid/detail page. Deliberately never falls back to best-sellers —
 * attributing "clientes que compraram X" to a product that was never
 * actually co-purchased with anything would be a fabricated justification
 * (`tasks.md`/TASK-190: "nunca uma lista sem justificativa alguma"). A
 * product with no qualifying co-occurrence simply has no recommendation
 * document at all (`insufficientData: true`, caller does not persist it —
 * see `calculate-product-recommendations.ts`).
 */
export function buildProductScopeRecommendation(params: {
  anchorProductId: string;
  model: CoOccurrenceModel;
  productLabels: ReadonlyMap<string, ProductLabel>;
  maxItems?: number;
  minCoOccurrenceCount?: number;
}): ProductRecommendationResult {
  const maxItems = params.maxItems ?? MAX_RECOMMENDATIONS_PER_SCOPE;
  const minCount = params.minCoOccurrenceCount ?? MIN_CO_OCCURRENCE_COUNT;
  const anchorPurchaseCount = params.model.purchaseCounts.get(params.anchorProductId) ?? 0;
  const related = params.model.pairCounts.get(params.anchorProductId);

  if (!related || anchorPurchaseCount === 0) {
    return {
      scopeType: 'product',
      scopeId: params.anchorProductId,
      items: [],
      fallbackApplied: false,
      insufficientData: true,
      signalsUsed: [],
    };
  }

  const anchorName = productName(params.productLabels, params.anchorProductId);
  const items: RecommendationItem[] = [...related.entries()]
    .filter(([, count]) => count >= minCount)
    .map(([candidateProductId, count]) => ({
      productId: candidateProductId,
      productName: productName(params.productLabels, candidateProductId),
      score: roundScore(count / anchorPurchaseCount),
      reasonCode: 'boughtTogether' as const,
      reasonLabel:
        `Clientes que compraram ${anchorName} também compraram ` +
        `${productName(params.productLabels, candidateProductId)} ` +
        `(${count} de ${anchorPurchaseCount} pedido(s) com ${anchorName}).`,
      relatedProductId: params.anchorProductId,
      relatedProductName: anchorName,
    }))
    .sort((a, b) => b.score - a.score || a.productId.localeCompare(b.productId))
    .slice(0, maxItems);

  return {
    scopeType: 'product',
    scopeId: params.anchorProductId,
    items,
    fallbackApplied: false,
    insufficientData: items.length === 0,
    signalsUsed: items.length > 0 ? ['order_submitted_item_co_occurrence'] : [],
  };
}

/** `customer` scope: personalized recommendation aggregating the
 * co-occurrence of every product the customer already purchased, excluding
 * products already purchased. Falls back to company best-sellers
 * (`fallbackApplied: true`) when the customer has no purchase history yet or
 * no qualifying candidate was found; falls back further to an explicit
 * `insufficientData: true` (never a silently empty list) when even the
 * best-sellers pool has nothing to offer (`tasks.md`/TASK-190's own
 * "cliente novo" fallback rule).
 */
export function buildCustomerScopeRecommendation(params: {
  customerId: string;
  purchasedProductIds: ReadonlySet<string>;
  model: CoOccurrenceModel;
  productLabels: ReadonlyMap<string, ProductLabel>;
  bestSellers: readonly RecommendationItem[];
  maxItems?: number;
}): ProductRecommendationResult {
  const maxItems = params.maxItems ?? MAX_RECOMMENDATIONS_PER_SCOPE;
  const candidates = new Map<
    string,
    { score: number; relatedProductId: string; relatedProductName: string; relatedCount: number }
  >();

  for (const purchasedProductId of params.purchasedProductIds) {
    const purchaseCount = params.model.purchaseCounts.get(purchasedProductId) ?? 0;
    if (purchaseCount === 0) continue;
    const related = params.model.pairCounts.get(purchasedProductId);
    if (!related) continue;
    for (const [candidateProductId, count] of related) {
      if (params.purchasedProductIds.has(candidateProductId)) continue;
      const confidence = count / purchaseCount;
      const current = candidates.get(candidateProductId);
      if (!current || confidence > current.score) {
        candidates.set(candidateProductId, {
          score: confidence,
          relatedProductId: purchasedProductId,
          relatedProductName: productName(params.productLabels, purchasedProductId),
          relatedCount: count,
        });
      }
    }
  }

  const personalizedItems: RecommendationItem[] = [...candidates.entries()]
    .map(([candidateProductId, candidate]) => ({
      productId: candidateProductId,
      productName: productName(params.productLabels, candidateProductId),
      score: roundScore(candidate.score),
      reasonCode: 'purchaseHistorySimilarity' as const,
      reasonLabel:
        `Você já comprou ${candidate.relatedProductName}; clientes com o ` +
        `mesmo perfil de compra também levaram ` +
        `${productName(params.productLabels, candidateProductId)} ` +
        `(${candidate.relatedCount} pedido(s) com esse padrão).`,
      relatedProductId: candidate.relatedProductId,
      relatedProductName: candidate.relatedProductName,
    }))
    .sort((a, b) => b.score - a.score || a.productId.localeCompare(b.productId))
    .slice(0, maxItems);

  if (personalizedItems.length > 0) {
    return {
      scopeType: 'customer',
      scopeId: params.customerId,
      items: personalizedItems,
      fallbackApplied: false,
      insufficientData: false,
      signalsUsed: ['order_submitted_item_co_occurrence'],
    };
  }

  const fallbackItems = params.bestSellers
    .filter((item) => !params.purchasedProductIds.has(item.productId))
    .slice(0, maxItems);

  if (fallbackItems.length > 0) {
    return {
      scopeType: 'customer',
      scopeId: params.customerId,
      items: fallbackItems,
      fallbackApplied: true,
      insufficientData: false,
      signalsUsed: ['best_sellers_fallback'],
    };
  }

  return {
    scopeType: 'customer',
    scopeId: params.customerId,
    items: [],
    fallbackApplied: false,
    insufficientData: true,
    signalsUsed: [],
  };
}

export function productRecommendationDocumentId(
  companyId: string,
  scopeType: ProductRecommendationScopeType,
  scopeId: string,
): string {
  return `${companyId}_${scopeType}_${scopeId}`;
}
