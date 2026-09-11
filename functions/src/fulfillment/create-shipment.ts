import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { Timestamp, getFirestore, type DocumentData } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { loadActiveMembership, requireNonEmptyString, resolveActorName } from '../invites/invite-shared';
import {
  ROLES_ALLOWED_TO_MANAGE_SHIPMENT,
  buildShipmentPackages,
  ensureRequesterMayActOnOrder,
  isShipmentEligibleOrderStatus,
  mapReturnRequestOrder,
  normalizeTeamIds,
  optionalString,
  requireOptionalBoundedString,
  sumShippedQuantities,
  type ShipmentPackageInput,
  type ShipmentPackageRecord,
} from './fulfillment-shared';

const MAX_CARRIER_FIELD_LENGTH = 200;

export interface CreateShipmentRequest extends RequestWithMeta {
  organizationId?: string;
  companyId?: string;
  orderId?: string;
  shipmentId?: string;
  carrierName?: string;
  carrierTrackingCode?: string;
  estimatedDeliveryDate?: string;
  packages?: ShipmentPackageInput[];
}

export interface CreateShipmentResponse {
  correlationId: string;
  shipmentId: string;
  orderId: string;
  status: 'pending';
  packages: ShipmentPackageRecord[];
}

/**
 * Idempotent Cloud Function opening a `Shipment`/romaneio (TASK-214,
 * EPIC-32) against an already-faturado pedido: revalidates every volume/item/
 * quantity against the order's own persisted `items` (never the client's own
 * recollection) and the pedido's current commercial/financial status
 * (`isShipmentEligibleOrderStatus`) — a `Shipment` never applies any status
 * change to the order by itself; that only happens once a `TrackingEvent`
 * actually lands (`registerTrackingEvent`/`handleShipmentTrackingWebhook`).
 *
 * [CreateShipmentRequest.shipmentId] is the client-generated idempotency key
 * *and* the resulting document id — same precedent `returnRequestId`
 * (`createReturnRequest`) already sets.
 */
export const createShipment = onCall<CreateShipmentRequest, Promise<CreateShipmentResponse>>(
  async (request) => {
    const startedAt = Date.now();
    const correlationId = resolveCorrelationId(request.data?._meta);

    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'É necessário estar autenticado para criar uma expedição.');
    }
    const uid = request.auth.uid;

    const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
    const companyId = requireNonEmptyString(request.data?.companyId, 'companyId');
    const orderId = requireNonEmptyString(request.data?.orderId, 'orderId');
    const shipmentId = requireNonEmptyString(request.data?.shipmentId, 'shipmentId');
    const carrierName = requireOptionalBoundedString(
      request.data?.carrierName,
      'carrierName',
      MAX_CARRIER_FIELD_LENGTH,
    );
    const carrierTrackingCode = requireOptionalBoundedString(
      request.data?.carrierTrackingCode,
      'carrierTrackingCode',
      MAX_CARRIER_FIELD_LENGTH,
    );
    const estimatedDeliveryDate = parseOptionalDate(request.data?.estimatedDeliveryDate);
    const packagesInput = request.data?.packages;
    if (!Array.isArray(packagesInput)) {
      throw new HttpsError('invalid-argument', 'packages is required.');
    }

    const db = getFirestore();
    const membership = await loadActiveMembership(db, organizationId, uid);
    if (!ROLES_ALLOWED_TO_MANAGE_SHIPMENT.has(membership.roleName)) {
      throw new HttpsError('permission-denied', 'Seu perfil não pode criar expedições.');
    }

    const actorName = await resolveActorName(db, uid, request.auth.token);
    const organizationRef = db.collection('organizations').doc(organizationId);
    const orderRef = organizationRef.collection('orders').doc(orderId);
    const shipmentRef = organizationRef.collection('shipments').doc(shipmentId);

    let requesterTeamIds: string[] = [];
    if (membership.roleName === 'SALES_MANAGER') {
      const requesterMemberSnapshot = await organizationRef.collection('members').doc(uid).get();
      requesterTeamIds = normalizeTeamIds(requesterMemberSnapshot.data()?.teamIds);
    }

    const result = await db.runTransaction<CreateShipmentResponse>(async (transaction) => {
      const existingSnapshot = await transaction.get(shipmentRef);
      if (existingSnapshot.exists) {
        const existing = existingSnapshot.data();
        if (!existing) throw new HttpsError('internal', 'Invalid shipment record.');
        return serializeShipment(shipmentId, existing, correlationId);
      }

      const orderSnapshot = await transaction.get(orderRef);
      if (!orderSnapshot.exists) {
        throw new HttpsError('failed-precondition', 'Pedido não encontrado.');
      }
      const order = mapReturnRequestOrder(orderId, orderSnapshot.data());
      if (order.organizationId !== organizationId || order.companyId !== companyId) {
        throw new HttpsError(
          'failed-precondition',
          'Pedido não pertence à organização/empresa informada.',
        );
      }
      if (!isShipmentEligibleOrderStatus(order.status)) {
        throw new HttpsError(
          'failed-precondition',
          'Este pedido não está em um status comercial/financeiro elegível para expedição.',
        );
      }

      await ensureRequesterMayActOnOrder(transaction, organizationRef, {
        roleName: membership.roleName,
        uid,
        order,
        requesterTeamIds,
      });

      const previousShipmentsSnapshot = await transaction.get(
        organizationRef.collection('shipments').where('orderId', '==', orderId),
      );
      const alreadyShipped = sumShippedQuantities(previousShipmentsSnapshot.docs.map((doc) => doc.data()));
      const packages = buildShipmentPackages(packagesInput, order, alreadyShipped);

      const now = Timestamp.now();
      const shipmentData: DocumentData = {
        organizationId,
        companyId,
        orderId,
        orderNumber: order.orderNumber,
        customerId: order.customerId,
        sellerId: order.sellerId,
        carrierName: carrierName ?? null,
        carrierTrackingCode: carrierTrackingCode ?? null,
        status: 'pending',
        hasOpenIssue: false,
        packages,
        deliveredQuantities: {},
        estimatedDeliveryDate: estimatedDeliveryDate ?? null,
        shippedAt: null,
        deliveredAt: null,
        lastEventAt: null,
        lastEventType: null,
        createdAt: now,
        createdBy: uid,
        updatedAt: now,
        updatedBy: uid,
        version: 1,
      };
      transaction.set(shipmentRef, shipmentData);

      transaction.set(organizationRef.collection('auditLogs').doc(), {
        organizationId,
        actorUserId: uid,
        actorName,
        action: 'shipment.created',
        entityType: 'order',
        entityId: orderId,
        previousValue: null,
        newValue: { shipmentId, carrierName: carrierName ?? null, packageCount: packages.length },
        timestamp: now,
      });

      return serializeShipment(shipmentId, shipmentData, correlationId);
    });

    logger.info('createShipment succeeded', {
      correlationId,
      organizationId,
      companyId,
      orderId,
      shipmentId,
      uid,
      durationMs: Date.now() - startedAt,
    });

    return result;
  },
);

function parseOptionalDate(value: string | undefined): Timestamp | undefined {
  const normalized = optionalString(value);
  if (!normalized) return undefined;
  const parsed = new Date(normalized);
  if (Number.isNaN(parsed.getTime())) {
    throw new HttpsError('invalid-argument', 'estimatedDeliveryDate must be a valid ISO date.');
  }
  return Timestamp.fromDate(parsed);
}

function serializeShipment(
  shipmentId: string,
  data: DocumentData,
  correlationId: string,
): CreateShipmentResponse {
  return {
    correlationId,
    shipmentId,
    orderId: data.orderId as string,
    status: 'pending',
    packages: (data.packages ?? []) as ShipmentPackageRecord[],
  };
}
