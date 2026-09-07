import type { DocumentData } from 'firebase-admin/firestore';

import type { StockCoverageStatus } from '../inventory/stock-turnover-shared';

/**
 * Server-side, shared domain service for EPIC-27's replenishment engine
 * (TASK-184). Every function here is pure (no Firestore, no
 * `firebase-functions`), the same "shared calculation core" shape already
 * established by `../inventory/stock-turnover-shared.ts` (TASK-094) — this
 * file deliberately *consumes* that module's `StockTurnoverMetricSnapshot`
 * (via {@link ReplenishmentTurnoverEvidence}) instead of recomputing
 * turnover/coverage from raw `StockTurnoverDailyFact`s itself. That is the
 * concrete "reaproveitar giro" the task's own "Escopo técnico" asks for:
 * `calculate-replenishment-suggestions.ts` groups daily facts by variant and
 * calls `buildMetricSnapshot` (TASK-094) exactly once, then feeds the result
 * in here — the formulas for turnover rate/coverage days/average daily sales
 * are never duplicated.
 *
 * Forward-looking note (do NOT act on this in TASK-184, see
 * `docs/tasks/TASK-133-criar-camada-de-agregacao-server-side-CONCLUIDA.md`'s
 * own "Decisão de escopo"): populating `insightStockPositionSnapshots` (the
 * upstream feed TASK-128's `ReplenishmentSuggestionInsightRule` already
 * expects but that no task has produced yet) remains explicitly out of
 * scope. When that follow-up task exists, it can and should reuse this same
 * module — {@link calculateReplenishmentSuggestion}'s
 * `targetStockQuantity`/`suggestedQuantity` is exactly the number
 * `InsightStockPositionSnapshot.suggestedReorderPointQuantity` needs — rather
 * than re-deriving the formula a third time.
 */

/** Per-organization tunables read from
 * `organizations/{organizationId}/replenishmentSettings/default`. Never
 * mutates a suggestion already generated/decided — every persisted
 * `ReplenishmentSuggestion` freezes its own `parametersSnapshot` at
 * calculation time (see `calculate-replenishment-suggestions.ts`), exactly
 * so a later change to this organization-level config can only affect the
 * *next* scheduled run, never retroactively "reinterpret" a suggestion a
 * human already accepted/adjusted/discarded. */
export interface ReplenishmentParameters {
  /** How many days of projected sales the suggested quantity should cover,
   * on top of whatever is already available (current sellable + future
   * stock). */
  coverageTargetDays: number;
  /** A flat minimum stock cushion added on top of the coverage-days target,
   * independent of recent sales velocity. */
  safetyStockQuantity: number;
  /** Multiplies the average daily sales quantity before projecting the
   * coverage target — `1` (the default) means "no seasonal adjustment";
   * an organization expecting a spike (e.g. `1.5`) or a lull (e.g. `0.7`)
   * for the upcoming period can tune this without touching
   * `coverageTargetDays`/`safetyStockQuantity`. */
  seasonalityFactor: number;
}

/** Sensible organization-level defaults, used both to seed a brand-new
 * `replenishmentSettings/default` document on first run and as the
 * in-memory fallback for any field that document is missing/invalid. */
export const DEFAULT_REPLENISHMENT_PARAMETERS: ReplenishmentParameters = {
  coverageTargetDays: 30,
  safetyStockQuantity: 0,
  seasonalityFactor: 1,
};

/** How many days of `stockTurnoverDailyFacts` the scheduled calculation
 * looks back to build each variant's `StockTurnoverMetricSnapshot` (TASK-094
 * scope `'variant'`) — a 12-week moving window, long enough to smooth out a
 * single slow/fast week without going stale for a fast-moving SKU. Not
 * configurable per organization today (unlike {@link ReplenishmentParameters}):
 * revisit only if a real organization needs a materially different window. */
export const DEFAULT_TURNOVER_LOOKBACK_DAYS = 84;

/** The subset of a `StockTurnoverMetricSnapshot` (TASK-094) this module
 * actually needs — kept as its own narrow interface instead of importing
 * the full snapshot type, so a unit test can build one without also
 * satisfying every other unrelated field (`sellThroughRate`, `scopeId`,
 * ...). `calculate-replenishment-suggestions.ts` always builds this by
 * destructuring a real `StockTurnoverMetricSnapshot` — the field names/
 * meanings match exactly. */
export interface ReplenishmentTurnoverEvidence {
  averageDailySalesQuantity: number;
  stockCoverageDays: number;
  turnoverRate: number;
  coverageStatus: StockCoverageStatus;
}

export interface ReplenishmentCalculationInput {
  /** `null` when there is no `StockTurnoverDailyFact` at all for this
   * variant in the lookback window (brand-new product, never sold) — a
   * distinct "no history" case from `coverageStatus === 'noRecentSales'`
   * (some history, but no sales) or `'noStockBaseline'` (sales recorded
   * with no opening/received stock, e.g. a data quality gap). */
  turnover: ReplenishmentTurnoverEvidence | null;
  /** Current sellable quantity for this variant/warehouse (TASK-090,
   * `physicalQuantity - reservedQuantity - blockedQuantity`, floored at
   * `0`) — the caller is responsible for computing this the same way
   * `VariantStockBalance.sellableQuantity` does on the client. */
  currentSellableQuantity: number;
  /** Stock already known to arrive before the projected coverage window
   * ends (TASK-091). Always `0` today: `FutureStockEntry` (TASK-091) is
   * currently derived from `ProductVariant.manualAvailabilityStatus`/
   * `manualFutureAvailableAt`/`manualAvailableQuantity`, and production DI
   * wires `SharedPreferencesProductVariantRepository` — i.e. `ProductVariant`
   * is a local-only, unsynced entity today (confirmed by reading
   * `lib/app/injection.config.dart`; `FirestoreProductVariantRepository`
   * exists but is not the one actually registered). There is no Firestore
   * collection a Cloud Function could read future stock from yet. Kept as
   * an explicit parameter (not hardcoded inside this function) so this gap
   * is the *caller's* documented decision, and so a future task that adds a
   * synced future-stock collection only has to change the caller, never
   * this pure calculation. */
  futureStockQuantity: number;
  parameters: ReplenishmentParameters;
}

export type ReplenishmentInsufficientDataReason =
  | 'noTurnoverHistory'
  | 'noStockBaseline'
  | 'noRecentSales';

export interface ReplenishmentCalculationResult {
  insufficientData: boolean;
  insufficientDataReason: ReplenishmentInsufficientDataReason | null;
  /** Target total stock (current + incoming) the organization's
   * `coverageTargetDays`/`safetyStockQuantity`/`seasonalityFactor` call for.
   * Always `0` when {@link insufficientData} is `true` — never an arbitrary
   * number derived from a coverage status that means "we don't actually
   * know this variant's sales velocity" (`tasks.md`/TASK-184: "Itens sem
   * histórico suficiente ... não geram sugestão numérica arbitrária"). */
  targetStockQuantity: number;
  /** `currentSellableQuantity + futureStockQuantity`, both floored at `0`
   * first (a negative sellable/future value — e.g. an over-reservation edge
   * case — never *reduces* how much is considered "already available"). */
  projectedAvailableQuantity: number;
  /** `max(0, targetStockQuantity - projectedAvailableQuantity)` — never
   * negative (a variant that already has more stock than its target simply
   * suggests `0`, not a "de-stock" instruction; EPIC-27 is about
   * replenishment, not the inverse). */
  suggestedQuantity: number;
}

/**
 * Computes how many units of one variant/warehouse should be reordered,
 * given its recent turnover (already computed by `stock-turnover-shared.ts`),
 * current + future stock and the organization's own
 * {@link ReplenishmentParameters}. Always server-side only
 * (`calculate-replenishment-suggestions.ts`'s scheduled Cloud Function) —
 * never duplicated client-side, per `tasks.md`/TASK-184: "Cálculo sempre
 * roda server-side ... para evitar divergência entre vendedores e
 * gestores".
 */
export function calculateReplenishmentSuggestion(
  input: ReplenishmentCalculationInput,
): ReplenishmentCalculationResult {
  const { turnover, currentSellableQuantity, futureStockQuantity, parameters } =
    input;
  const projectedAvailableQuantity =
    nonNegative(currentSellableQuantity) + nonNegative(futureStockQuantity);

  if (!turnover || turnover.coverageStatus !== 'ready') {
    return {
      insufficientData: true,
      insufficientDataReason: resolveInsufficientDataReason(turnover),
      targetStockQuantity: 0,
      projectedAvailableQuantity,
      suggestedQuantity: 0,
    };
  }

  const coverageTargetDays = nonNegative(parameters.coverageTargetDays);
  const safetyStockQuantity = nonNegative(parameters.safetyStockQuantity);
  const seasonalityFactor =
    parameters.seasonalityFactor > 0 ? parameters.seasonalityFactor : 1;

  const targetStockQuantity = Math.round(
    turnover.averageDailySalesQuantity * coverageTargetDays * seasonalityFactor +
      safetyStockQuantity,
  );
  const suggestedQuantity = Math.max(
    0,
    targetStockQuantity - projectedAvailableQuantity,
  );

  return {
    insufficientData: false,
    insufficientDataReason: null,
    targetStockQuantity,
    projectedAvailableQuantity,
    suggestedQuantity,
  };
}

function resolveInsufficientDataReason(
  turnover: ReplenishmentTurnoverEvidence | null,
): ReplenishmentInsufficientDataReason {
  if (!turnover) return 'noTurnoverHistory';
  return turnover.coverageStatus === 'noStockBaseline'
    ? 'noStockBaseline'
    : 'noRecentSales';
}

function nonNegative(value: number): number {
  return Number.isFinite(value) && value > 0 ? value : 0;
}

/**
 * Every status a `ReplenishmentSuggestion` document can hold. `'suggested'`/
 * `'insufficientData'` are the only two the scheduled calculation
 * (`calculate-replenishment-suggestions.ts`) ever writes; `'accepted'`/
 * `'adjusted'`/`'discarded'` are exclusively set by a human decision
 * (`decide-replenishment-suggestion.ts`) and, once set, are permanently
 * frozen — see {@link FROZEN_REPLENISHMENT_STATUSES}.
 */
export type ReplenishmentSuggestionStatus =
  | 'suggested'
  | 'insufficientData'
  | 'accepted'
  | 'adjusted'
  | 'discarded';

/**
 * The three terminal statuses a human decision
 * (`decide-replenishment-suggestion.ts`) can put a `ReplenishmentSuggestion`
 * into. Once a document's `status` is one of these, the scheduled
 * calculation (`calculate-replenishment-suggestions.ts`) must never
 * overwrite it again for that exact `periodEnd` — `tasks.md`/TASK-184:
 * "Alteração de parâmetros de cálculo por organização não altera
 * retroativamente cálculos já aceitos".
 */
export const FROZEN_REPLENISHMENT_STATUSES: ReadonlySet<ReplenishmentSuggestionStatus> =
  new Set<ReplenishmentSuggestionStatus>(['accepted', 'adjusted', 'discarded']);

/** Raw shape of one `organizations/{organizationId}/inventory/{id}` document
 * (TASK-090's `VariantStockBalance`, mirrored here for the Admin SDK side —
 * collection name confirmed by reading
 * `lib/features/inventory/data/datasources/firestore_variant_stock_balance_data_source.dart`,
 * which is `'inventory'`, not `'variantStockBalances'`). */
export interface ReplenishmentVariantStockBalance {
  id: string;
  organizationId: string;
  companyId: string;
  productId: string;
  variantId: string;
  warehouseId: string;
  physicalQuantity: number;
  reservedQuantity: number;
  blockedQuantity: number;
}

/** Same "validate everything, return `null` on any mismatch" contract as
 * `stock-turnover-shared.ts`'s `asStockTurnoverDailyFact` — a malformed
 * document is skipped, never thrown, so one corrupted balance can never
 * abort an entire organization's scheduled run. */
export function asReplenishmentVariantStockBalance(
  id: string,
  data: DocumentData | undefined,
): ReplenishmentVariantStockBalance | null {
  if (!data) return null;
  if (
    typeof data.organizationId !== 'string' ||
    typeof data.companyId !== 'string' ||
    typeof data.productId !== 'string' ||
    typeof data.variantId !== 'string' ||
    typeof data.warehouseId !== 'string' ||
    typeof data.physicalQuantity !== 'number' ||
    typeof data.reservedQuantity !== 'number' ||
    typeof data.blockedQuantity !== 'number'
  ) {
    return null;
  }
  return {
    id,
    organizationId: data.organizationId,
    companyId: data.companyId,
    productId: data.productId,
    variantId: data.variantId,
    warehouseId: data.warehouseId,
    physicalQuantity: data.physicalQuantity,
    reservedQuantity: data.reservedQuantity,
    blockedQuantity: data.blockedQuantity,
  };
}

/** Same clamped formula as the Flutter `VariantStockBalance.sellableQuantity`
 * getter (`lib/features/inventory/domain/entities/variant_stock_balance.dart`)
 * — kept in sync manually (there is no shared Dart/TS layer for this), but
 * both sides are simple enough (one line) that drift risk is low. */
export function sellableQuantityOf(
  balance: ReplenishmentVariantStockBalance,
): number {
  const value =
    balance.physicalQuantity - balance.reservedQuantity - balance.blockedQuantity;
  return value < 0 ? 0 : value;
}
