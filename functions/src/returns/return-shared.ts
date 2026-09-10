import { HttpsError } from 'firebase-functions/v2/https';
import type { DocumentData, DocumentReference, Timestamp } from 'firebase-admin/firestore';

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
