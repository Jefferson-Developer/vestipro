import { createHash } from 'node:crypto';

import { HttpsError } from 'firebase-functions/v2/https';
import type { DocumentData } from 'firebase-admin/firestore';

import {
  ensureRequesterMayActOnOrder,
  mapReturnRequestOrder,
  normalizeTeamIds,
  optionalString,
  requireString,
  type ReturnRequestOrder,
  type ReturnRequestOrderItem,
} from '../returns/return-shared';

export { ensureRequesterMayActOnOrder, mapReturnRequestOrder, normalizeTeamIds, optionalString, requireString };

/** A `Shipment`/romaneio is always opened against the exact same pedido
 * shape (`items`, `customerId`, `sellerId`...) a devolução is — reusing
 * `returns/return-shared.ts`'s own `ReturnRequestOrder`/`mapReturnRequestOrder`
 * instead of a second, independently-drifting reimplementation of "read the
 * order's own persisted items" (`AGENTS.md`: não duplicar regra). Only
 * `id`/`productId`/`variantId`/`quantity` are ever used here — `unitPrice`/
 * `warehouseId` are irrelevant to expedição but harmless to carry along. */
export type ShipmentOrder = ReturnRequestOrder;
export type ShipmentOrderItem = ReturnRequestOrderItem;

// ---------------------------------------------------------------------------
// Enumerations (TASK-214, EPIC-32 — expedição, romaneio, tracking e
// ocorrências). Every code below is the exact string persisted in Firestore
// and mirrored 1:1 by the Dart value objects under
// `lib/features/fulfillment/domain/value_objects/`.
// ---------------------------------------------------------------------------

/** Pedido statuses a `Shipment`/romaneio may ever be opened against
 * (`tasks.md`/TASK-214: "Pedido só pode avançar para expedição quando
 * estiver em estado comercial/financeiro permitido"). Deliberately narrower
 * than `POST_SALE_EVENT_ELIGIBLE_ORDER_STATUSES` (`after-sales-shared.ts`,
 * which also allows the pre-fatura `processing` status for its own informal
 * milestone notes): a formal expedição/romaneio only ever starts once the
 * pedido is already faturado — mirrors exactly the set
 * `OrderStatusTransitionValidator` (Dart) accepts a transition *into*
 * `shipped` from. */
export const SHIPMENT_ELIGIBLE_ORDER_STATUSES: ReadonlySet<string> = new Set<string>([
  'invoiced',
  'partially_invoiced',
]);

export function isShipmentEligibleOrderStatus(status: string): boolean {
  return SHIPMENT_ELIGIBLE_ORDER_STATUSES.has(status);
}

/** Every status a `Shipment` document may carry. `pending` is the initial
 * status `createShipment` writes; every other value is only ever reached by
 * `registerTrackingEvent`/`handleShipmentTrackingWebhook`'s own transition
 * table below. `cancelled` is reachable only by an explicit administrative
 * action outside this task's scope (no Function here ever writes it —
 * documented as a known limitation, see this task's "Pendências"). */
export type ShipmentStatus =
  | 'pending'
  | 'picking'
  | 'packed'
  | 'shipped'
  | 'in_transit'
  | 'out_for_delivery'
  | 'partially_delivered'
  | 'delivered'
  | 'returned'
  | 'cancelled';

export const OPEN_SHIPMENT_STATUSES: ReadonlySet<ShipmentStatus> = new Set<ShipmentStatus>([
  'pending',
  'picking',
  'packed',
  'shipped',
  'in_transit',
  'out_for_delivery',
  'partially_delivered',
]);

/** Every milestone a `TrackingEvent` may carry — TASK-214: "Tracking event é
 * append-only; correção cria novo evento de ajuste, não sobrescreve
 * histórico" ([adjustment] is exactly that correction event: it never moves
 * `Shipment.status` by itself, it only carries a note tied back to
 * [TrackingEvent.correctionOfEventId]). */
export type TrackingEventType =
  | 'picking_started'
  | 'packed'
  | 'shipped'
  | 'in_transit'
  | 'out_for_delivery'
  | 'delivered'
  | 'partially_delivered'
  | 'returned_to_carrier'
  | 'adjustment';

const TRACKING_EVENT_TYPES: ReadonlySet<string> = new Set<string>([
  'picking_started',
  'packed',
  'shipped',
  'in_transit',
  'out_for_delivery',
  'delivered',
  'partially_delivered',
  'returned_to_carrier',
  'adjustment',
]);

export type TrackingEventSource = 'webhook' | 'manual' | 'admin';

export type LogisticsIssueType =
  | 'delay'
  | 'damage'
  | 'volume_divergence'
  | 'invalid_address'
  | 'carrier_return'
  | 'other';

const LOGISTICS_ISSUE_TYPES: ReadonlySet<string> = new Set<string>([
  'delay',
  'damage',
  'volume_divergence',
  'invalid_address',
  'carrier_return',
  'other',
]);

export type LogisticsIssueStatus = 'open' | 'in_progress' | 'resolved';

export function requireTrackingEventType(value: unknown): TrackingEventType {
  if (typeof value !== 'string' || !TRACKING_EVENT_TYPES.has(value)) {
    throw new HttpsError('invalid-argument', 'type deve ser um marco de tracking válido.');
  }
  return value as TrackingEventType;
}

export function requireLogisticsIssueType(value: unknown): LogisticsIssueType {
  if (typeof value !== 'string' || !LOGISTICS_ISSUE_TYPES.has(value)) {
    throw new HttpsError('invalid-argument', 'type deve ser um tipo de ocorrência válido.');
  }
  return value as LogisticsIssueType;
}

/** The pedido's own next status once [eventType] lands (TASK-214) — the
 * server-side bridge that finally drives `Order.status` into `shipped`/
 * `delivered` for the first time in this codebase (no other Function ever
 * wrote either value before this task). Mirrors exactly the two relevant
 * edges of `OrderStatusTransitionValidator._allowedTransitions` (Dart):
 * `invoiced | partially_invoiced -> shipped` and `shipped -> delivered`.
 * Returns `null` whenever [eventType] carries no order-level milestone (e.g.
 * `picking_started`/`adjustment`) or the pedido is not currently in the
 * exact status that edge requires — the caller must never fall back to
 * forcing the status in that case, only skip the order update entirely
 * (`partially_delivered` deliberately never transitions the order: there is
 * no partial-delivery `OrderStatus` value, the pedido stays `shipped` until
 * every item is fully delivered). */
export function resolveOrderStatusForTrackingEvent(
  currentOrderStatus: string,
  eventType: TrackingEventType,
): 'shipped' | 'delivered' | null {
  if (eventType === 'shipped' && SHIPMENT_ELIGIBLE_ORDER_STATUSES.has(currentOrderStatus)) {
    return 'shipped';
  }
  if (eventType === 'delivered' && currentOrderStatus === 'shipped') {
    return 'delivered';
  }
  return null;
}

/** `Shipment.status` [eventType] resolves to for every milestone that is not
 * a delivery outcome (those are resolved separately by
 * [resolveDeliveryOutcome], since they depend on accumulated per-item
 * quantity, not just the event type alone). Returns `null` for `adjustment`
 * (never moves the aggregate status, TASK-214: "correção... não sobrescreve
 * histórico") and for the two delivery types (handled elsewhere). */
export function shipmentStatusForMilestone(eventType: TrackingEventType): ShipmentStatus | null {
  switch (eventType) {
    case 'picking_started':
      return 'picking';
    case 'packed':
      return 'packed';
    case 'shipped':
      return 'shipped';
    case 'in_transit':
      return 'in_transit';
    case 'out_for_delivery':
      return 'out_for_delivery';
    case 'returned_to_carrier':
      return 'returned';
    case 'delivered':
    case 'partially_delivered':
    case 'adjustment':
      return null;
  }
}

// ---------------------------------------------------------------------------
// Order + package validation (mirrors `returns/return-shared.ts`'s own
// `mapReturnRequestOrder`/`resolveRestockPlans` shape: every read happens
// against the order's own persisted `items`, never the client's recollection
// of them).
// ---------------------------------------------------------------------------

export interface ShipmentPackageItemInput {
  orderItemId: string;
  quantity: number;
}

export interface ShipmentPackageInput {
  packageNumber: number;
  weightKg?: number;
  items: ShipmentPackageItemInput[];
}

export interface ShipmentPackageItemRecord {
  orderItemId: string;
  productId: string;
  variantId: string;
  quantity: number;
}

export interface ShipmentPackageRecord {
  packageNumber: number;
  weightKg: number | null;
  items: ShipmentPackageItemRecord[];
}

/** Sums, per `orderItemId`, every quantity already committed to a still-open
 * (not `cancelled`) shipment of the same pedido — never letting a new
 * romaneio push the total shipped quantity above what the pedido's own item
 * actually carries. Mirrors `returns/return-shared.ts`'s own
 * `sumCommittedQuantities`. */
export function sumShippedQuantities(existingShipments: DocumentData[]): Map<string, number> {
  const totals = new Map<string, number>();
  for (const shipment of existingShipments) {
    if (shipment.status === 'cancelled') continue;
    const packages = Array.isArray(shipment.packages) ? shipment.packages : [];
    for (const pkg of packages) {
      const items = Array.isArray(pkg?.items) ? pkg.items : [];
      for (const item of items) {
        const orderItemId = item?.orderItemId as string | undefined;
        if (!orderItemId) continue;
        const quantity = typeof item?.quantity === 'number' ? item.quantity : 0;
        totals.set(orderItemId, (totals.get(orderItemId) ?? 0) + quantity);
      }
    }
  }
  return totals;
}

/** Validates/normalizes [inputPackages] against [order]'s own persisted
 * items — every `orderItemId` must belong to the order, every quantity must
 * be a positive integer, package numbers must be unique, and the cumulative
 * quantity across [alreadyShipped] plus this new romaneio may never exceed
 * the order item's own original quantity (TASK-214: "Entrega parcial deve
 * preservar itens/quantidades por volume para evitar divergência no
 * pós-venda" starts here, at creation time, not just at delivery time). */
export function buildShipmentPackages(
  inputPackages: ShipmentPackageInput[],
  order: ShipmentOrder,
  alreadyShipped: Map<string, number>,
): ShipmentPackageRecord[] {
  if (!Array.isArray(inputPackages) || inputPackages.length === 0) {
    throw new HttpsError('invalid-argument', 'packages é obrigatório e não pode ser vazio.');
  }
  const seenPackageNumbers = new Set<number>();
  const committedThisShipment = new Map<string, number>();
  const records: ShipmentPackageRecord[] = [];

  for (const pkg of inputPackages) {
    const packageNumber = pkg?.packageNumber;
    if (typeof packageNumber !== 'number' || !Number.isInteger(packageNumber) || packageNumber <= 0) {
      throw new HttpsError('invalid-argument', 'packageNumber deve ser um inteiro positivo.');
    }
    if (seenPackageNumbers.has(packageNumber)) {
      throw new HttpsError('invalid-argument', `packageNumber ${packageNumber} está duplicado.`);
    }
    seenPackageNumbers.add(packageNumber);

    const weightKg = pkg.weightKg;
    if (weightKg !== undefined && (typeof weightKg !== 'number' || weightKg < 0)) {
      throw new HttpsError('invalid-argument', 'weightKg deve ser zero ou maior.');
    }

    if (!Array.isArray(pkg.items) || pkg.items.length === 0) {
      throw new HttpsError(
        'invalid-argument',
        `packages[packageNumber=${packageNumber}].items é obrigatório e não pode ser vazio.`,
      );
    }

    const items: ShipmentPackageItemRecord[] = pkg.items.map((item) => {
      const orderItemId = requireString(item.orderItemId, 'items[].orderItemId');
      const quantity = requirePositiveInteger(item.quantity, 'items[].quantity');
      const orderItem = order.items.find((candidate) => candidate.id === orderItemId);
      if (!orderItem) {
        throw new HttpsError(
          'invalid-argument',
          `O item "${orderItemId}" não pertence a este pedido.`,
        );
      }
      const alreadyCommitted =
        (alreadyShipped.get(orderItemId) ?? 0) + (committedThisShipment.get(orderItemId) ?? 0);
      if (alreadyCommitted + quantity > orderItem.quantity) {
        throw new HttpsError(
          'failed-precondition',
          `A quantidade expedida para o item "${orderItemId}" excede a quantidade ` +
            'disponível neste pedido.',
        );
      }
      committedThisShipment.set(orderItemId, alreadyCommitted + quantity);
      return {
        orderItemId,
        productId: orderItem.productId,
        variantId: orderItem.variantId,
        quantity,
      };
    });

    records.push({ packageNumber, weightKg: weightKg ?? null, items });
  }

  return records;
}

/** Total packaged quantity, per `orderItemId`, across every package of one
 * `Shipment` — the ceiling [resolveDeliveryStatus] compares accumulated
 * delivered quantity against. */
export function totalQuantityByOrderItem(packages: ShipmentPackageRecord[]): Map<string, number> {
  const totals = new Map<string, number>();
  for (const pkg of packages) {
    for (const item of pkg.items) {
      totals.set(item.orderItemId, (totals.get(item.orderItemId) ?? 0) + item.quantity);
    }
  }
  return totals;
}

export interface DeliveredItemInput {
  orderItemId: string;
  quantity: number;
}

/** Validates [deliveredItems] (this single delivery event's own quantities,
 * never cumulative) against [totalByItem] and [previouslyDelivered] — every
 * `orderItemId` must belong to a package of this shipment and the new
 * cumulative total may never exceed what was actually packaged (TASK-214:
 * "Entrega parcial deve preservar itens/quantidades por volume para evitar
 * divergência no pós-venda"). Returns the updated cumulative map; never
 * mutates [previouslyDelivered]. */
export function applyDeliveredItems(
  deliveredItems: DeliveredItemInput[],
  totalByItem: Map<string, number>,
  previouslyDelivered: Map<string, number>,
): Map<string, number> {
  const next = new Map(previouslyDelivered);
  for (const entry of deliveredItems) {
    const total = totalByItem.get(entry.orderItemId);
    if (total === undefined) {
      throw new HttpsError(
        'invalid-argument',
        `O item "${entry.orderItemId}" não pertence a nenhum volume desta expedição.`,
      );
    }
    const already = next.get(entry.orderItemId) ?? 0;
    if (already + entry.quantity > total) {
      throw new HttpsError(
        'failed-precondition',
        `A quantidade entregue para o item "${entry.orderItemId}" excede a quantidade expedida.`,
      );
    }
    next.set(entry.orderItemId, already + entry.quantity);
  }
  return next;
}

/** Whether [cumulativeDelivered] now covers every unit of [totalByItem]
 * (`delivered`) or still leaves at least one item short (`partially_delivered`)
 * — computed server-side from the real accumulated ledger, never trusted
 * from whatever label the webhook/caller itself used for this event. */
export function resolveDeliveryStatus(
  totalByItem: Map<string, number>,
  cumulativeDelivered: Map<string, number>,
): 'delivered' | 'partially_delivered' {
  for (const [orderItemId, total] of totalByItem) {
    if ((cumulativeDelivered.get(orderItemId) ?? 0) < total) return 'partially_delivered';
  }
  return 'delivered';
}

export function requirePositiveInteger(value: unknown, field: string): number {
  if (typeof value !== 'number' || !Number.isInteger(value) || value <= 0) {
    throw new HttpsError('invalid-argument', `${field} deve ser um inteiro positivo.`);
  }
  return value;
}

export function requireDeliveredItems(value: unknown): DeliveredItemInput[] {
  if (!Array.isArray(value) || value.length === 0) {
    throw new HttpsError('invalid-argument', 'deliveredItems é obrigatório e não pode ser vazio.');
  }
  return value.map((entry, index) => {
    const data = entry as DocumentData | null;
    if (!data || typeof data !== 'object') {
      throw new HttpsError('invalid-argument', `deliveredItems[${index}] is invalid.`);
    }
    return {
      orderItemId: requireString(data.orderItemId, `deliveredItems[${index}].orderItemId`),
      quantity: requirePositiveInteger(data.quantity, `deliveredItems[${index}].quantity`),
    };
  });
}

/** Deterministic `TrackingEvent` document id for a webhook delivery
 * (TASK-214: "sempre com idempotência por evento externo") — the exact same
 * `carrierId`/`shipmentId`/`externalEventId` tuple always hashes to the same
 * id, so a retried delivery (network retry, at-least-once queue) can never
 * create a second event for the same underlying occurrence. Mirrors
 * `webhooks/webhook-shared.ts`'s own `computeWebhookEventId` shape. */
export function computeTrackingEventId(
  carrierId: string,
  shipmentId: string,
  externalEventId: string,
): string {
  return createHash('sha256').update([carrierId, shipmentId, externalEventId].join('|')).digest('hex');
}

/** Only these roles may ever create a `Shipment`, register a tracking
 * event/ocorrência or resolve one (TASK-214) — mirrors exactly
 * `postSaleEventRegister`'s own grant list (`role_permission_matrix.dart`):
 * OWNER/ADMIN always; SALES_MANAGER/SALES_REP only for a pedido they may
 * already act on (`ensureRequesterMayActOnOrder`, reused as-is from
 * `returns/return-shared.ts`). CUSTOMER_PORTAL is deliberately absent — a
 * cliente never creates/edits its own tracking data, only ever reads it. */
export const ROLES_ALLOWED_TO_MANAGE_SHIPMENT: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
  'SALES_MANAGER',
  'SALES_REP',
]);

export function requireOptionalBoundedString(
  value: unknown,
  field: string,
  maxLength: number,
): string | undefined {
  const normalized = optionalString(value);
  if (normalized && normalized.length > maxLength) {
    throw new HttpsError('invalid-argument', `${field} must stay under ${maxLength} characters.`);
  }
  return normalized;
}

export function requireBoundedString(value: unknown, field: string, maxLength: number): string {
  const normalized = requireString(value, field);
  if (normalized.length > maxLength) {
    throw new HttpsError('invalid-argument', `${field} must stay under ${maxLength} characters.`);
  }
  return normalized;
}
