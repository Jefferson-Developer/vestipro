import { FieldValue } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import type { DocumentData, DocumentReference, Timestamp, Transaction } from 'firebase-admin/firestore';

/**
 * Categorized reason a `ReturnRequest` was opened for (TASK-199, EPIC-30) —
 * `tasks.md`'s own "motivo obrigatório categorizado — ex.: defeito, troca de
 * decisão, erro de pedido". A free-text [ReturnRequestInput.reasonDetails]
 * may add context but never substitutes for one of these (`tasks.md`: "texto
 * livre nunca substitui a categoria").
 */
export type ReturnReasonCategory =
  | 'defect'
  | 'wrong_item'
  | 'change_of_mind'
  | 'order_error'
  | 'other';

export const RETURN_REASON_CATEGORIES: ReadonlySet<string> = new Set<string>([
  'defect',
  'wrong_item',
  'change_of_mind',
  'order_error',
  'other',
]);

export type ReturnRequestStatus = 'requested' | 'approved' | 'rejected';

/** Order statuses a `ReturnRequest` may ever be opened against (TASK-199) —
 * a devolução only ever makes sense once goods have actually left the
 * warehouse/been billed; a pedido still `draft`/`under_review`/`processing`
 * has nothing to return yet. Mirrors the exact set
 * `OrderStatusTransitionValidator` (Dart) allows transitioning *from* into
 * `partiallyReturned`/`returned`. */
export const RETURN_ELIGIBLE_ORDER_STATUSES: ReadonlySet<string> = new Set<string>([
  'invoiced',
  'partially_invoiced',
  'shipped',
  'delivered',
  'partially_returned',
]);

export interface ReturnRequestOrderItem {
  id: string;
  productId: string;
  variantId: string;
  quantity: number;
  unitPrice: number;
  warehouseId: string | null;
}

export interface ReturnRequestOrder {
  id: string;
  organizationId: string;
  companyId: string;
  customerId: string;
  sellerId: string;
  orderNumber: string | null;
  currency: string;
  status: string;
  items: ReturnRequestOrderItem[];
}

export function mapReturnRequestOrder(id: string, data: DocumentData | undefined): ReturnRequestOrder {
  if (!data) throw new HttpsError('failed-precondition', 'Pedido não encontrado.');
  const items = Array.isArray(data.items) ? data.items.map((item, index) => mapOrderItem(item, index)) : [];
  return {
    id,
    organizationId: requireString(data.organizationId, 'organizationId'),
    companyId: requireString(data.companyId, 'companyId'),
    customerId: requireString(data.customerId, 'customerId'),
    sellerId: requireString(data.sellerId, 'sellerId'),
    orderNumber: optionalString(data.orderNumber) ?? null,
    currency: optionalString(data.currency) ?? 'BRL',
    status: requireString(data.status, 'status'),
    items,
  };
}

function mapOrderItem(value: unknown, index: number): ReturnRequestOrderItem {
  const data = value as DocumentData | null;
  if (!data || typeof data !== 'object') {
    throw new HttpsError('failed-precondition', `Order item ${index} is invalid.`);
  }
  return {
    id: optionalString(data.id) ?? `item-${index}`,
    productId: requireString(data.productId, `items[${index}].productId`),
    variantId: requireString(data.variantId, `items[${index}].variantId`),
    quantity: requireMoney(data.quantity, `items[${index}].quantity`),
    unitPrice: requireMoney(data.unitPrice, `items[${index}].unitPrice`),
    warehouseId: optionalString(data.warehouseId) ?? null,
  };
}

export function requireReasonCategory(value: unknown): ReturnReasonCategory {
  if (typeof value !== 'string' || !RETURN_REASON_CATEGORIES.has(value)) {
    throw new HttpsError(
      'invalid-argument',
      'reasonCategory é obrigatório e deve ser uma categoria válida.',
    );
  }
  return value as ReturnReasonCategory;
}

export function balanceDocId(variantId: string, warehouseId: string): string {
  return `${variantId}_${warehouseId}`;
}

export function inventoryBalanceRef(
  organizationRef: DocumentReference,
  variantId: string,
  warehouseId: string,
): DocumentReference {
  return organizationRef.collection('inventory').doc(balanceDocId(variantId, warehouseId));
}

/** Whether [status] is one of [RETURN_ELIGIBLE_ORDER_STATUSES] — the only
 * pedido statuses a devolução may ever be requested/decided against. */
export function isReturnEligibleOrderStatus(status: string): boolean {
  return RETURN_ELIGIBLE_ORDER_STATUSES.has(status);
}

/** The order's own next status once this devolução is approved (TASK-199):
 * `returned` when every unit of every original item is now covered by an
 * approved devolução (this one included), `partiallyReturned` otherwise.
 * Both values are already known to `commission-shared.ts`'s
 * `isReversalOrderStatus` (EPIC-29), so writing either one onto the order
 * document automatically triggers `calculateOrderCommissionOnWrite` and
 * reverses the seller's commission for this pedido — no separate reversal
 * logic is duplicated here. */
export function resolveOrderStatusAfterApproval(
  orderItems: ReturnRequestOrderItem[],
  returnedQuantityByOrderItemId: Map<string, number>,
): 'returned' | 'partiallyReturned' {
  const fullyReturned = orderItems.every(
    (item) => (returnedQuantityByOrderItemId.get(item.id) ?? 0) >= item.quantity,
  );
  return fullyReturned ? 'returned' : 'partiallyReturned';
}

export function requireString(value: unknown, field: string): string {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new HttpsError('failed-precondition', `${field} is required.`);
  }
  return value.trim();
}

export function optionalString(value: unknown): string | undefined {
  return typeof value === 'string' && value.trim().length > 0 ? value.trim() : undefined;
}

export function stringArray(value: unknown): string[] {
  return Array.isArray(value)
    ? value.filter((item): item is string => typeof item === 'string' && item.trim().length > 0)
    : [];
}

export function requireMoney(value: unknown, field: string): number {
  if (typeof value !== 'number' || Number.isNaN(value) || value < 0) {
    throw new HttpsError('failed-precondition', `${field} must be zero or greater.`);
  }
  return roundMoney(value);
}

export function roundMoney(value: number): number {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

export function timestampToDate(value: unknown): Date | undefined {
  const timestamp = value as Timestamp | undefined;
  return typeof timestamp?.toDate === 'function' ? timestamp.toDate() : undefined;
}

// -----------------------------------------------------------------------
// Restock reintegration (originally `resolveReturnRequest`-only, TASK-199;
// exported here so `resolveExchangeRequest` (TASK-200, EPIC-30) can reuse the
// exact same "read every plan before any write, tolerate an untracked
// variant" logic for reintegrating the exchanged-away variant, instead of a
// second, independently-drifting reimplementation of the same Firestore
// transaction-ordering rules).
// -----------------------------------------------------------------------

export interface RestockableItem {
  variantId: string;
  quantity: number;
  warehouseId: string | null;
}

export interface RestockPlan {
  balanceRef: DocumentReference;
  quantity: number;
}

/**
 * Reads (never writes — Firestore transactions require every read staged
 * before any write) every item's exact inventory balance to reintegrate
 * quantity into: the warehouse denormalized on the order item at submission
 * time (TASK-101) whenever present, or — only for orders predating that
 * denormalization — the first (lexicographically smallest) balance already
 * tracking that variant, same fallback `resolveItemAvailability`
 * (`submitOrder`) already uses for the opposite (decrement) direction. An
 * item whose variant has no tracked balance at all is skipped: there is
 * nothing to reintegrate into, never a blocking error (mirrors
 * `submitOrder`'s own "stock not tracked" tolerance).
 */
export async function resolveRestockPlans(
  transaction: Transaction,
  organizationRef: DocumentReference,
  items: RestockableItem[],
): Promise<RestockPlan[]> {
  const plans: RestockPlan[] = [];
  for (const item of items) {
    if (item.quantity <= 0) continue;
    if (item.warehouseId) {
      plans.push({
        balanceRef: inventoryBalanceRef(organizationRef, item.variantId, item.warehouseId),
        quantity: item.quantity,
      });
      continue;
    }
    const balanceSnapshots = await transaction.get(
      organizationRef.collection('inventory').where('variantId', '==', item.variantId),
    );
    if (balanceSnapshots.empty) continue;
    const fallback = balanceSnapshots.docs.sort((left, right) => left.id.localeCompare(right.id))[0];
    plans.push({ balanceRef: fallback.ref, quantity: item.quantity });
  }
  return plans;
}

export function normalizeTeamIds(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.filter((entry): entry is string => typeof entry === 'string');
}

/**
 * Guards who may act (solicitar uma devolução *or* uma troca, TASK-199/
 * TASK-200) on behalf of a given [ReturnRequestOrder] — exported so both
 * `createReturnRequest` and `createExchangeRequest` share one single
 * definition of "quem pode agir neste pedido" instead of two independently-
 * drifting copies: OWNER/ADMIN always may; the portal only for its own
 * pedido; a SALES_REP only for their own pedido; a SALES_MANAGER only for a
 * pedido whose vendedor shares at least one team with them. Every other role
 * is denied — the caller is expected to have already checked its own
 * `ROLES_ALLOWED_TO_REQUEST_*` set before reaching here.
 */
export async function ensureRequesterMayActOnOrder(
  transaction: Transaction,
  organizationRef: DocumentReference,
  input: {
    roleName: string;
    uid: string;
    order: ReturnRequestOrder;
    portalCustomerId?: string;
    requesterTeamIds: string[];
  },
): Promise<void> {
  if (input.roleName === 'OWNER' || input.roleName === 'ADMIN') return;

  if (input.roleName === 'CUSTOMER_PORTAL') {
    if (input.portalCustomerId !== input.order.customerId) {
      throw new HttpsError(
        'permission-denied',
        'O portal só pode agir sobre os próprios pedidos.',
      );
    }
    return;
  }

  if (input.roleName === 'SALES_REP') {
    if (input.order.sellerId !== input.uid) {
      throw new HttpsError(
        'permission-denied',
        'O pedido só pode ter uma solicitação aberta pelo próprio vendedor responsável.',
      );
    }
    return;
  }

  if (input.roleName === 'SALES_MANAGER') {
    const sellerSnapshot = await transaction.get(
      organizationRef.collection('members').doc(input.order.sellerId),
    );
    const sellerTeamIds = normalizeTeamIds(sellerSnapshot.data()?.teamIds);
    const sharesTeam = sellerTeamIds.some((teamId) => input.requesterTeamIds.includes(teamId));
    if (!sharesTeam) {
      throw new HttpsError(
        'permission-denied',
        'Você só pode agir sobre pedidos da sua própria equipe.',
      );
    }
    return;
  }

  throw new HttpsError('permission-denied', 'Seu perfil não pode realizar esta ação.');
}

/** Writes every reintegration [plans] staged by [resolveRestockPlans] —
 * always additive (`FieldValue.increment`), so two concurrent
 * reintegrations of different quantities for the same balance never clobber
 * one another. [source] tags `inventory.lastSource` so a balance's own
 * movement history can tell a devolução's reintegration apart from a
 * troca's. */
export function applyRestockMovements(
  transaction: Transaction,
  plans: RestockPlan[],
  context: { uid: string; now: Timestamp; source: string },
): void {
  for (const plan of plans) {
    transaction.set(
      plan.balanceRef,
      {
        physicalQuantity: FieldValue.increment(plan.quantity),
        updatedAt: context.now,
        updatedBy: context.uid,
        lastSource: context.source,
        version: FieldValue.increment(1),
      },
      { merge: true },
    );
  }
}
