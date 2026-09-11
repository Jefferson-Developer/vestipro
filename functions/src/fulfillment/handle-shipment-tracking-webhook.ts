import { Timestamp, getFirestore } from 'firebase-admin/firestore';
import { onRequest } from 'firebase-functions/v2/https';

import { verifyWebhookSignature } from '../webhooks/webhook-shared';
import {
  computeTrackingEventId,
  mapReturnRequestOrder,
  optionalString,
  requireDeliveredItems,
  requireString,
  requireTrackingEventType,
  type DeliveredItemInput,
} from './fulfillment-shared';
import { applyTrackingEvent } from './register-tracking-event';

const SIGNATURE_HEADER = 'x-vestipro-shipment-signature';

/**
 * Inbound, unauthenticated (HMAC-signed) webhook a transportadora/integração
 * externa calls to advance a `Shipment`'s tracking (TASK-214, EPIC-32) —
 * `Query: organizationId, carrierId`. Every delivery is idempotent by
 * `body.externalEventId` (`computeTrackingEventId` derives the resulting
 * `TrackingEvent` document id deterministically from
 * `carrierId`/`shipmentId`/`externalEventId`, so a retried delivery is always
 * a safe no-op — [applyTrackingEvent]'s own `transaction.get` short-circuits
 * before writing anything twice). Reuses `webhooks/webhook-shared.ts`'s own
 * `verifyWebhookSignature` (TASK-170) instead of a third, independently-
 * drifting HMAC implementation (`payments/handle-payment-webhook.ts` already
 * has its own for the exact same "inbound, unauthenticated, per-organization
 * secret" shape).
 *
 * The per-`carrierId` HMAC secret lives at
 * `organizations/{organizationId}/shipmentWebhookSecrets/{carrierId}` — never
 * client-readable (`firestore.rules`), provisioned only by
 * `provisionShipmentWebhookSecret` (OWNER/ADMIN).
 */
export const handleShipmentTrackingWebhook = onRequest(async (request, response) => {
  if (request.method !== 'POST') {
    response.sendStatus(405);
    return;
  }
  const organizationId = requireQueryString(request.query.organizationId);
  const carrierId = requireQueryString(request.query.carrierId);
  if (!organizationId || !carrierId) {
    response.sendStatus(400);
    return;
  }

  const db = getFirestore();
  const organizationRef = db.collection('organizations').doc(organizationId);
  const secretSnapshot = await organizationRef.collection('shipmentWebhookSecrets').doc(carrierId).get();
  const secret = secretSnapshot.data()?.secret as string | undefined;
  if (!secret) {
    response.sendStatus(403);
    return;
  }

  const rawBody = (request.rawBody ?? Buffer.from('')).toString('utf8');
  const signature = request.header(SIGNATURE_HEADER);
  if (!signature || !verifyWebhookSignature(secret, rawBody, signature)) {
    response.sendStatus(403);
    return;
  }

  try {
    const payload = request.body as Record<string, unknown> | null;
    if (!payload || typeof payload !== 'object') {
      response.sendStatus(400);
      return;
    }
    const shipmentId = requireString(payload.shipmentId, 'shipmentId');
    const externalEventId = requireString(payload.externalEventId, 'externalEventId');
    const type = requireTrackingEventType(payload.type);
    const description = optionalString(payload.description) ?? null;
    const occurredAtRaw = optionalString(payload.occurredAt);
    const occurredAt = occurredAtRaw ? Timestamp.fromDate(new Date(occurredAtRaw)) : Timestamp.now();
    const deliveredItems: DeliveredItemInput[] | null =
      type === 'delivered' || type === 'partially_delivered'
        ? requireDeliveredItems(payload.deliveredItems)
        : null;

    const trackingEventRef = organizationRef
      .collection('trackingEvents')
      .doc(computeTrackingEventId(carrierId, shipmentId, externalEventId));
    const shipmentRef = organizationRef.collection('shipments').doc(shipmentId);

    await db.runTransaction(async (transaction) => {
      const existingEventSnapshot = await transaction.get(trackingEventRef);
      if (existingEventSnapshot.exists) return;

      const shipmentSnapshot = await transaction.get(shipmentRef);
      if (!shipmentSnapshot.exists) throw new Error('Shipment not found.');
      const shipmentData = shipmentSnapshot.data();
      if (!shipmentData || shipmentData.organizationId !== organizationId) {
        throw new Error('Shipment does not belong to this organization.');
      }

      const orderRef = organizationRef.collection('orders').doc(shipmentData.orderId as string);
      const orderSnapshot = await transaction.get(orderRef);
      if (!orderSnapshot.exists) throw new Error('Order not found.');
      // Validates the order document shape even though only `status` is used
      // below — same defensive read every other Function in this codebase
      // performs before trusting a denormalized field.
      mapReturnRequestOrder(orderRef.id, orderSnapshot.data());

      const now = Timestamp.now();
      applyTrackingEvent(transaction, {
        shipmentRef,
        shipmentSnapshotData: shipmentData,
        orderRef,
        orderSnapshotData: orderSnapshot.data()!,
        trackingEventRef,
        organizationRef,
        organizationId,
        type,
        source: 'webhook',
        occurredAt,
        description,
        deliveredItems,
        correctionOfEventId: null,
        externalEventId,
        carrierId,
        createdBy: `webhook:${carrierId}`,
        createdByName: `Integração ${carrierId}`,
        now,
      });
    });

    response.sendStatus(200);
  } catch {
    response.sendStatus(400);
  }
});

function requireQueryString(value: unknown): string | undefined {
  const raw = Array.isArray(value) ? value[0] : value;
  return typeof raw === 'string' && raw.trim().length > 0 ? raw.trim() : undefined;
}
