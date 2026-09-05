import { Timestamp, type DocumentData } from 'firebase-admin/firestore';

/**
 * The snapshot dimensions this layer pre-computes (TASK-133/TASK-140, `tasks.md`
 * seção 22: "Dashboards complexos não devem executar centenas de consultas
 * do cliente... Criar snapshots/agregações server-side"). Every dashboard in
 * EPIC-17 (TASK-134 a TASK-143) that needs revenue/order-count/quantity by
 * time, customer, product/category/collection, seller or region reads one of
 * these — never raw `orders`.
 *
 * `productMonthly` intentionally also carries `categoryId`/`collectionId` as
 * denormalized labels (see {@link AggregateSnapshotDoc.labels}) instead of
 * being split into three separate dimensions ("por produto/categoria/
 * coleção" in the task's own scope) — one snapshot per product per month,
 * with category/collection already attached, lets a dashboard group/filter
 * client-side without a second round-trip, while still never touching the
 * raw `orders`/`products` collections directly.
 */
export type AggregationDimension =
  | 'salesDaily'
  | 'sellerDaily'
  | 'representativeMonthly'
  | 'customerMonthly'
  | 'productMonthly'
  | 'sellerMonthly'
  | 'regionMonthly';

export const AGGREGATE_COLLECTION_BY_DIMENSION: Readonly<
  Record<AggregationDimension, string>
> = {
  salesDaily: 'salesDailyAggregates',
  sellerDaily: 'sellerDailyAggregates',
  representativeMonthly: 'representativeMonthlyAggregates',
  customerMonthly: 'customerMonthlyAggregates',
  productMonthly: 'productMonthlyAggregates',
  sellerMonthly: 'sellerMonthlyAggregates',
  regionMonthly: 'regionMonthlyAggregates',
};

/**
 * Order statuses counted as "real" commercial activity for every aggregate
 * in this module. Deliberately excludes `draft`/`pending_sync` (never
 * persisted server-side — `submitOrder` is the only writer of `orders`
 * documents, and it always starts a document at `submitted`/`under_review`)
 * and `rejected`/`cancelled` (never became revenue). Mirrors the lifecycle
 * in `lib/features/orders/domain/value_objects/order_status.dart` and the
 * string values `OrderMapper` persists to Firestore.
 */
export const REVENUE_RECOGNIZED_ORDER_STATUSES: ReadonlySet<string> = new Set<
  string
>([
  'submitted',
  'under_review',
  'approved',
  'processing',
  'invoiced',
  'partially_invoiced',
  'shipped',
  'delivered',
]);

export interface OrderAggregationItemFact {
  productId: string;
  quantity: number;
  subtotal: number;
}

/**
 * The subset of an `organizations/{orgId}/orders/{orderId}` document this
 * module needs, extracted once per order and shared by every aggregator
 * (salesDaily, customerMonthly, productMonthly, sellerMonthly,
 * regionMonthly) so each order is only parsed once even though it feeds
 * multiple
 * different snapshot dimensions.
 */
export interface OrderAggregationFact {
  id: string;
  organizationId: string;
  companyId: string;
  customerId: string;
  sellerId: string;
  /** `deliveryAddress.state` — the only region signal already persisted on
   * every order (no separate `region` field exists on `Order` today). */
  region: string;
  /** Delivery city. Kept optional for backwards-compatible unit fixtures. */
  city?: string;
  status: string;
  createdAt: Timestamp;
  itemsSubtotal: number;
  discountAmount: number;
  surchargeAmount: number;
  shippingAmount: number;
  itemQuantity: number;
  items: readonly OrderAggregationItemFact[];
}

export function extractOrderFact(
  id: string,
  data: DocumentData | undefined,
): OrderAggregationFact | null {
  if (!data) return null;
  if (
    typeof data.organizationId !== 'string' ||
    typeof data.companyId !== 'string' ||
    typeof data.customerId !== 'string' ||
    typeof data.sellerId !== 'string' ||
    typeof data.status !== 'string' ||
    !(data.createdAt instanceof Timestamp) ||
    !Array.isArray(data.items)
  ) {
    return null;
  }

  const items: OrderAggregationItemFact[] = data.items
    .map((item: DocumentData) => {
      if (
        typeof item?.productId !== 'string' ||
        typeof item?.quantity !== 'number' ||
        typeof item?.subtotal !== 'number'
      ) {
        return null;
      }
      return {
        productId: item.productId,
        quantity: item.quantity,
        subtotal: item.subtotal,
      };
    })
    .filter((item: OrderAggregationItemFact | null): item is OrderAggregationItemFact => item != null);

  const region =
    typeof data.deliveryAddress?.state === 'string' &&
    data.deliveryAddress.state.trim().length > 0
      ? (data.deliveryAddress.state as string).trim().toUpperCase()
      : 'UNKNOWN';
  const city =
    typeof data.deliveryAddress?.city === 'string' &&
    data.deliveryAddress.city.trim().length > 0
      ? (data.deliveryAddress.city as string).trim()
      : 'UNKNOWN';

  return {
    id,
    organizationId: data.organizationId,
    companyId: data.companyId,
    customerId: data.customerId,
    sellerId: data.sellerId,
    region,
    city,
    status: data.status,
    createdAt: data.createdAt,
    itemsSubtotal: sumField(items, 'subtotal'),
    discountAmount: numberOrZero(data.discountAmount),
    surchargeAmount: numberOrZero(data.surchargeAmount),
    shippingAmount: numberOrZero(data.shippingAmount),
    itemQuantity: sumField(items, 'quantity'),
    items,
  };
}

export function isRevenueRecognized(fact: OrderAggregationFact): boolean {
  return REVENUE_RECOGNIZED_ORDER_STATUSES.has(fact.status);
}

/**
 * Definitive per-order revenue formula used by every order-level aggregate
 * (`salesDaily`/`customerMonthly`/`sellerMonthly`/`regionMonthly`). No
 * canonical "order total" field/getter exists yet anywhere in the codebase
 * (`Order.itemsSubtotal` in `lib/features/orders/domain/entities/order.dart`
 * is explicitly documented as partial — "before order-level discountAmount/
 * surchargeAmount/shippingAmount/taxAmount"); this is the sum of every
 * monetary component actually persisted on the order today. If a future
 * order task models a definitive total, every aggregator here must be
 * updated to use it instead.
 */
export function netRevenueOf(fact: OrderAggregationFact): number {
  return roundCurrency(
    fact.itemsSubtotal -
      fact.discountAmount +
      fact.surchargeAmount +
      fact.shippingAmount,
  );
}

export interface AggregateSnapshotDoc {
  organizationId: string;
  companyId: string;
  dimension: AggregationDimension;
  /** `companyId` itself for `salesDaily` (company-wide, no sub-scope);
   * sellerId for seller dimensions; customerId/productId/region otherwise. */
  scopeId: string;
  /** `YYYY-MM-DD` for daily dimensions, `YYYY-MM` for monthly dimensions. */
  periodKey: string;
  revenueGross: number;
  revenueNet: number;
  discountAmount: number;
  orderCount: number;
  itemQuantity: number;
  /** Denormalized display fields (customerName, sellerName, productName,
   * categoryId, categoryName, collectionId, collectionName, segment...) so a
   * dashboard never has to re-fetch the source entity just to render a
   * label. Always a plain string map — never sensitive/PII beyond what
   * already exists on the referenced entity itself. */
  labels: Readonly<Record<string, string>>;
  generatedAt: Timestamp;
  version: number;
}

export function buildAggregateDocId(
  companyId: string,
  scopeId: string,
  periodKey: string,
): string {
  return `${companyId}_${scopeId}_${periodKey}`;
}

export function formatDayKey(date: Date): string {
  return date.toISOString().slice(0, 10);
}

export function formatMonthKey(date: Date): string {
  return date.toISOString().slice(0, 7);
}

export function monthRange(monthKey: string): { start: Date; end: Date } {
  const [yearStr, monthStr] = monthKey.split('-');
  const year = Number(yearStr);
  const month = Number(monthStr);
  const start = new Date(Date.UTC(year, month - 1, 1, 0, 0, 0, 0));
  const end = new Date(Date.UTC(year, month, 0, 23, 59, 59, 999));
  return { start, end };
}

export function dayRange(dayKey: string): { start: Date; end: Date } {
  const start = new Date(`${dayKey}T00:00:00.000Z`);
  const end = new Date(`${dayKey}T23:59:59.999Z`);
  return { start, end };
}

export function roundCurrency(value: number): number {
  if (!Number.isFinite(value)) return 0;
  return Math.round(value * 100) / 100;
}

function numberOrZero(value: unknown): number {
  return typeof value === 'number' && Number.isFinite(value) ? value : 0;
}

function sumField<T>(
  items: readonly T[],
  field: keyof T & string,
): number {
  return items.reduce((sum, item) => {
    const value = item[field];
    return sum + (typeof value === 'number' ? value : 0);
  }, 0);
}
