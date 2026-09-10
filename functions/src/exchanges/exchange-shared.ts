import { HttpsError } from 'firebase-functions/v2/https';
import type { DocumentData, DocumentReference, Query, QuerySnapshot } from 'firebase-admin/firestore';

import { requireString } from '../returns/return-shared';

/**
 * Categorized reason an `ExchangeRequest` (TASK-200, EPIC-30) was opened for
 * — mirrors `ReturnReasonCategory`'s own "motivo obrigatório categorizado"
 * contract (TASK-199), with a troca-specific vocabulary (tamanho errado,
 * preferência de cor) in place of devolução's own. Free-text
 * `reasonDetails` may add context but never substitutes for one of these.
 */
export type ExchangeReasonCategory =
  | 'size_issue'
  | 'color_preference'
  | 'defect'
  | 'wrong_item'
  | 'other';

export const EXCHANGE_REASON_CATEGORIES: ReadonlySet<string> = new Set<string>([
  'size_issue',
  'color_preference',
  'defect',
  'wrong_item',
  'other',
]);

export function requireExchangeReasonCategory(value: unknown): ExchangeReasonCategory {
  if (typeof value !== 'string' || !EXCHANGE_REASON_CATEGORIES.has(value)) {
    throw new HttpsError(
      'invalid-argument',
      'reasonCategory é obrigatório e deve ser uma categoria válida.',
    );
  }
  return value as ExchangeReasonCategory;
}

export interface ExchangeDestinationVariant {
  id: string;
  /** The variant's own product — `createExchangeRequest`/
   * `resolveExchangeRequest` both require this to match the *origin* item's
   * own `productId` (`tasks.md`'s own "troca de variante — cor/tamanho",
   * never a swap into an unrelated product, which would sidestep every
   * catalog/assortment control this codebase otherwise enforces). */
  productId: string;
  status: string;
}

export function mapExchangeDestinationVariant(
  id: string,
  data: DocumentData | undefined,
): ExchangeDestinationVariant {
  if (!data) {
    throw new HttpsError('failed-precondition', 'Variante de destino não encontrada.');
  }
  return {
    id,
    productId: requireString(data.productId, 'destinationVariant.productId'),
    status: requireString(data.status, 'destinationVariant.status'),
  };
}

export interface FulfillableBalance {
  ref: DocumentReference;
  /** `null` only for a balance predating TASK-101's own `warehouseId`
   * denormalization — mirrors the exact same tolerance
   * `resolveItemAvailability` (`submitOrder`) already applies. */
  warehouseId: string | null;
}

/**
 * The one inventory balance (if any) that alone can fulfill [quantity] units
 * of [variantId] — same "a single line never splits across warehouses"
 * contract `submitOrder`'s own `resolveItemAvailability` already enforces,
 * reused here so a troca's destination-variant availability check (both at
 * `createExchangeRequest` time and, revalidated, at `resolveExchangeRequest`
 * time) never drifts from how every other stock-decrementing flow in this
 * codebase already decides "is this fulfillable". [reader] is either
 * `(query) => query.get()` (a plain, non-transactional read) or
 * `(query) => transaction.get(query)` — the caller decides which, since
 * Firestore transactions require every read staged before any write.
 */
export async function findFulfillableBalance(
  reader: (query: Query) => Promise<QuerySnapshot>,
  organizationRef: DocumentReference,
  variantId: string,
  quantity: number,
): Promise<FulfillableBalance | null> {
  const snapshot = await reader(
    organizationRef.collection('inventory').where('variantId', '==', variantId),
  );
  const fulfillable = snapshot.docs
    .map((doc) => ({ ref: doc.ref, data: doc.data() }))
    .filter((balance) => sellableQuantity(balance.data) >= quantity)
    .sort((left, right) => left.ref.id.localeCompare(right.ref.id))[0];
  if (!fulfillable) return null;
  return {
    ref: fulfillable.ref,
    warehouseId:
      typeof fulfillable.data.warehouseId === 'string' ? fulfillable.data.warehouseId : null,
  };
}

function sellableQuantity(data: DocumentData | undefined): number {
  const physical = typeof data?.physicalQuantity === 'number' ? data.physicalQuantity : 0;
  const reserved = typeof data?.reservedQuantity === 'number' ? data.reservedQuantity : 0;
  const blocked = typeof data?.blockedQuantity === 'number' ? data.blockedQuantity : 0;
  return physical - reserved - blocked;
}
