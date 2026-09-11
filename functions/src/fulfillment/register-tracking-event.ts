import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import {
  FieldValue,
  Timestamp,
  type DocumentData,
  type DocumentReference,
  type Transaction,
} from 'firebase-admin/firestore';
import { getFirestore } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { loadActiveMembership, requireNonEmptyString, resolveActorName } from '../invites/invite-shared';
import { appendPostSaleEvent, type PostSaleEventType } from '../after_sales/after-sales-shared';
import {
  ROLES_ALLOWED_TO_MANAGE_SHIPMENT,
  applyDeliveredItems,
  ensureRequesterMayActOnOrder,
  mapReturnRequestOrder,
  normalizeTeamIds,
  optionalString,
  requireDeliveredItems,
  requireOptionalBoundedString,
  requireTrackingEventType,
  resolveDeliveryStatus,
  resolveOrderStatusForTrackingEvent,
  shipmentStatusForMilestone,
  totalQuantityByOrderItem,
  type DeliveredItemInput,
  type ShipmentPackageRecord,
  type ShipmentStatus,
  type TrackingEventSource,
  type TrackingEventType,
} from './fulfillment-shared';

const MAX_DESCRIPTION_LENGTH = 1000;

export interface RegisterTrackingEventRequest extends RequestWithMeta {
  organizationId?: string;
  companyId?: string;
  shipmentId?: string;
  trackingEventId?: string;
  type?: TrackingEventType;
  occurredAt?: string;
  description?: string;
  deliveredItems?: DeliveredItemInput[];
  correctionOfEventId?: string;
}

export interface RegisterTrackingEventResponse {
  correlationId: string;
  shipmentId: string;
  trackingEventId: string;
  shipmentStatus: ShipmentStatus;
}

/** Maps a [TrackingEventType] milestone onto the pedido's own, pre-existing
 * pós-venda timeline (`postSaleEvents`, TASK-201) — so a formal expedição
 * milestone automatically shows up there too (and notifies the vendedor for
 * `delivered`), instead of a second, independently-drifting notification
 * pathway (`AGENTS.md`: não duplicar regra). Returns `null` for milestones
 * `after-sales-shared.ts`'s own timeline has no equivalent for
 * (`picking_started`/`packed`/`returned_to_carrier`/`adjustment`). */
function postSaleEventTypeFor(eventType: TrackingEventType): PostSaleEventType | null {
  switch (eventType) {
    case 'shipped':
      return 'dispatched';
    case 'in_transit':
    case 'out_for_delivery':
      return 'in_transit';
    case 'delivered':
    case 'partially_delivered':
      return 'delivered';
    default:
      return null;
  }
}

/**
 * Applies one `TrackingEvent` to [shipmentRef] inside [transaction] — the
 * single core write shared by the authenticated callable below (manual/admin
 * lançamento) and `handleShipmentTrackingWebhook` (integração externa), so
 * idempotency, the delivery-outcome ledger and the `Order.status` bridge are
 * never duplicated between the two entry points. Every read this function
 * needs must already be staged by the caller (Firestore transactions require
 * every read before any write) — see `registerTrackingEvent`/
 * `handleShipmentTrackingWebhook` themselves for that staging.
 */
export interface ApplyTrackingEventInput {
  shipmentRef: DocumentReference;
  shipmentSnapshotData: DocumentData;
  orderRef: DocumentReference;
  orderSnapshotData: DocumentData;
  trackingEventRef: DocumentReference;
  organizationRef: DocumentReference;
  organizationId: string;
  type: TrackingEventType;
  source: TrackingEventSource;
  occurredAt: Timestamp;
  description: string | null;
  deliveredItems: DeliveredItemInput[] | null;
  correctionOfEventId: string | null;
  externalEventId: string | null;
  carrierId: string | null;
  createdBy: string;
  createdByName: string;
  now: Timestamp;
}

export function applyTrackingEvent(transaction: Transaction, input: ApplyTrackingEventInput): ShipmentStatus {
  const shipment = input.shipmentSnapshotData;
  const packages = (shipment.packages ?? []) as ShipmentPackageRecord[];
  const currentStatus = shipment.status as ShipmentStatus;
  const previouslyDelivered = mapOfDelivered(shipment.deliveredQuantities);

  let nextStatus: ShipmentStatus = currentStatus;
  let nextDelivered = previouslyDelivered;
  const shipmentUpdates: DocumentData = {
    lastEventAt: input.now,
    lastEventType: input.type,
    updatedAt: input.now,
    updatedBy: input.createdBy,
    version: FieldValue.increment(1),
  };

  if (input.type === 'delivered' || input.type === 'partially_delivered') {
    const totalByItem = totalQuantityByOrderItem(packages);
    const deliveredThisEvent =
      input.deliveredItems ??
      Array.from(totalByItem.entries())
        .map(([orderItemId, total]) => ({
          orderItemId,
          quantity: total - (previouslyDelivered.get(orderItemId) ?? 0),
        }))
        .filter((entry) => entry.quantity > 0);
    nextDelivered = applyDeliveredItems(deliveredThisEvent, totalByItem, previouslyDelivered);
    nextStatus = resolveDeliveryStatus(totalByItem, nextDelivered);
    shipmentUpdates.deliveredQuantities = mapToPlainObject(nextDelivered);
    if (nextStatus === 'delivered') shipmentUpdates.deliveredAt = input.now;
  } else {
    const milestoneStatus = shipmentStatusForMilestone(input.type);
    if (milestoneStatus) {
      nextStatus = milestoneStatus;
      if (milestoneStatus === 'shipped') shipmentUpdates.shippedAt = input.now;
    }
  }
  shipmentUpdates.status = nextStatus;

  transaction.set(input.trackingEventRef, {
    organizationId: input.organizationId,
    companyId: shipment.companyId,
    shipmentId: input.shipmentRef.id,
    orderId: shipment.orderId,
    orderNumber: shipment.orderNumber ?? null,
    customerId: shipment.customerId,
    sellerId: shipment.sellerId,
    type: input.type,
    source: input.source,
    externalEventId: input.externalEventId,
    carrierId: input.carrierId,
    description: input.description,
    deliveredItems:
      input.type === 'delivered' || input.type === 'partially_delivered'
        ? (input.deliveredItems ?? null)
        : null,
    correctionOfEventId: input.correctionOfEventId,
    occurredAt: input.occurredAt,
    createdAt: input.now,
    createdBy: input.createdBy,
    createdByName: input.createdByName,
  });

  transaction.set(input.shipmentRef, shipmentUpdates, { merge: true });

  const orderStatus = input.orderSnapshotData.status as string;
  const nextOrderStatus = resolveOrderStatusForTrackingEvent(orderStatus, input.type);
  if (nextOrderStatus) {
    transaction.set(
      input.orderRef,
      {
        status: nextOrderStatus,
        statusHistory: FieldValue.arrayUnion({
          previousStatus: orderStatus,
          newStatus: nextOrderStatus,
          changedAt: input.now,
          actorId: input.createdBy,
          reason: `Expedição: evento "${input.type}" registrado.`,
        }),
        updatedAt: input.now,
        updatedBy: input.createdBy,
        version: FieldValue.increment(1),
      },
      { merge: true },
    );
  }

  const postSaleType = postSaleEventTypeFor(input.type);
  if (postSaleType) {
    appendPostSaleEvent(transaction, input.organizationRef, {
      eventRef: input.organizationRef.collection('postSaleEvents').doc(),
      organizationId: input.organizationId,
      companyId: shipment.companyId,
      orderId: shipment.orderId,
      orderNumber: shipment.orderNumber ?? null,
      customerId: shipment.customerId,
      sellerId: shipment.sellerId,
      type: postSaleType,
      description: input.description,
      source: 'system',
      sourceRequestId: input.trackingEventRef.id,
      createdBy: input.createdBy,
      createdByName: input.createdByName,
      now: input.now,
    });
  }

  return nextStatus;
}

/**
 * Authenticated callable behind a manual/administrative lançamento of a
 * `TrackingEvent` (TASK-214) — `handleShipmentTrackingWebhook` is the other,
 * unauthenticated entry point for the exact same underlying write
 * ([applyTrackingEvent]), used by an integração externa/carrier instead.
 * [RegisterTrackingEventRequest.trackingEventId] is the client-generated
 * idempotency key — a resubmission always carries the very same id, so it
 * can never register the same milestone twice.
 */
export const registerTrackingEvent = onCall<
  RegisterTrackingEventRequest,
  Promise<RegisterTrackingEventResponse>
>(async (request) => {
  const startedAt = Date.now();
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'É necessário estar autenticado para registrar um evento.');
  }
  const uid = request.auth.uid;

  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const shipmentId = requireNonEmptyString(request.data?.shipmentId, 'shipmentId');
  const trackingEventId = requireNonEmptyString(request.data?.trackingEventId, 'trackingEventId');
  const type = requireTrackingEventType(request.data?.type);
  const occurredAt = parseOccurredAt(request.data?.occurredAt);
  const description = requireOptionalBoundedString(
    request.data?.description,
    'description',
    MAX_DESCRIPTION_LENGTH,
  );
  const correctionOfEventId = optionalString(request.data?.correctionOfEventId) ?? null;
  if (type === 'adjustment' && !correctionOfEventId) {
    throw new HttpsError(
      'invalid-argument',
      'correctionOfEventId é obrigatório para um evento de ajuste.',
    );
  }
  const deliveredItems =
    type === 'delivered' || type === 'partially_delivered'
      ? requireDeliveredItems(request.data?.deliveredItems)
      : null;

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  if (!ROLES_ALLOWED_TO_MANAGE_SHIPMENT.has(membership.roleName)) {
    throw new HttpsError('permission-denied', 'Seu perfil não pode registrar eventos de tracking.');
  }
  const actorName = await resolveActorName(db, uid, request.auth.token);
  const source: TrackingEventSource = membership.roleName === 'OWNER' || membership.roleName === 'ADMIN'
    ? 'admin'
    : 'manual';

  const organizationRef = db.collection('organizations').doc(organizationId);
  const shipmentRef = organizationRef.collection('shipments').doc(shipmentId);
  const trackingEventRef = organizationRef.collection('trackingEvents').doc(trackingEventId);

  let requesterTeamIds: string[] = [];
  if (membership.roleName === 'SALES_MANAGER') {
    const requesterMemberSnapshot = await organizationRef.collection('members').doc(uid).get();
    requesterTeamIds = normalizeTeamIds(requesterMemberSnapshot.data()?.teamIds);
  }

  const result = await db.runTransaction<RegisterTrackingEventResponse>(async (transaction) => {
    const existingEventSnapshot = await transaction.get(trackingEventRef);
    if (existingEventSnapshot.exists) {
      const shipmentSnapshot = await transaction.get(shipmentRef);
      return {
        correlationId,
        shipmentId,
        trackingEventId,
        shipmentStatus: (shipmentSnapshot.data()?.status as ShipmentStatus) ?? 'pending',
      };
    }

    const shipmentSnapshot = await transaction.get(shipmentRef);
    if (!shipmentSnapshot.exists) {
      throw new HttpsError('failed-precondition', 'Expedição não encontrada.');
    }
    const shipmentData = shipmentSnapshot.data();
    if (!shipmentData) throw new HttpsError('internal', 'Invalid shipment record.');
    if (shipmentData.organizationId !== organizationId) {
      throw new HttpsError('failed-precondition', 'Expedição não pertence à organização informada.');
    }

    const orderRef = organizationRef.collection('orders').doc(shipmentData.orderId as string);
    const orderSnapshot = await transaction.get(orderRef);
    if (!orderSnapshot.exists) {
      throw new HttpsError('failed-precondition', 'Pedido vinculado à expedição não encontrado.');
    }
    const order = mapReturnRequestOrder(orderRef.id, orderSnapshot.data());

    await ensureRequesterMayActOnOrder(transaction, organizationRef, {
      roleName: membership.roleName,
      uid,
      order,
      requesterTeamIds,
    });

    const now = Timestamp.now();
    const shipmentStatus = applyTrackingEvent(transaction, {
      shipmentRef,
      shipmentSnapshotData: shipmentData,
      orderRef,
      orderSnapshotData: orderSnapshot.data()!,
      trackingEventRef,
      organizationRef,
      organizationId,
      type,
      source,
      occurredAt,
      description: description ?? null,
      deliveredItems,
      correctionOfEventId,
      externalEventId: null,
      carrierId: null,
      createdBy: uid,
      createdByName: actorName,
      now,
    });

    return { correlationId, shipmentId, trackingEventId, shipmentStatus };
  });

  logger.info('registerTrackingEvent succeeded', {
    correlationId,
    organizationId,
    shipmentId,
    trackingEventId,
    type,
    uid,
    durationMs: Date.now() - startedAt,
  });

  return result;
});

function parseOccurredAt(value: string | undefined): Timestamp {
  const normalized = optionalString(value);
  if (!normalized) return Timestamp.now();
  const parsed = new Date(normalized);
  if (Number.isNaN(parsed.getTime())) {
    throw new HttpsError('invalid-argument', 'occurredAt must be a valid ISO date.');
  }
  return Timestamp.fromDate(parsed);
}

function mapOfDelivered(value: unknown): Map<string, number> {
  const map = new Map<string, number>();
  if (!value || typeof value !== 'object') return map;
  for (const [key, quantity] of Object.entries(value as Record<string, unknown>)) {
    if (typeof quantity === 'number') map.set(key, quantity);
  }
  return map;
}

function mapToPlainObject(map: Map<string, number>): Record<string, number> {
  const result: Record<string, number> = {};
  for (const [key, value] of map) result[key] = value;
  return result;
}
