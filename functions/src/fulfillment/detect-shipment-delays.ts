import { logger } from 'firebase-functions/v2';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { FieldValue, Timestamp, getFirestore, type Firestore } from 'firebase-admin/firestore';

import { appendPostSaleEvent } from '../after_sales/after-sales-shared';
import { OPEN_SHIPMENT_STATUSES } from './fulfillment-shared';

/**
 * Daily scan flagging every `Shipment` still open (not `delivered`/
 * `returned`/`cancelled`) whose own `estimatedDeliveryDate` has already
 * passed (TASK-214, EPIC-32: "Gerar eventos/notificações comerciais quando
 * entrega atrasar"). Auto-opens exactly one `delay` `LogisticsIssue` per
 * shipment, at the deterministic id `delay_${shipmentId}` — a shipment
 * already carrying that document (open, in progress *or* resolved) is never
 * flagged a second time by this scan (documented known limitation, see this
 * task's "Riscos conhecidos": a shipment resolved once and still overdue
 * later does not get a second automatic alert; a human still can register a
 * fresh manual ocorrência at any time via `registerLogisticsIssue`). A
 * shipment with no `estimatedDeliveryDate` at all is skipped — there is no
 * SLA to compare against.
 */
export const detectShipmentDelays = onSchedule(
  {
    schedule: 'every day 07:00',
    timeZone: 'America/Sao_Paulo',
    region: 'southamerica-east1',
  },
  async () => {
    await detectShipmentDelaysScheduledHandler();
  },
);

export async function detectShipmentDelaysScheduledHandler(now = new Date()): Promise<void> {
  const db = getFirestore();
  const nowTimestamp = Timestamp.fromDate(now);
  const organizationsSnapshot = await db.collection('organizations').get();

  for (const organization of organizationsSnapshot.docs) {
    const data = organization.data();
    if (data.status !== 'active' || data.deletedAt != null) continue;

    const shipmentsSnapshot = await organization.ref
      .collection('shipments')
      .where('status', 'in', Array.from(OPEN_SHIPMENT_STATUSES))
      .where('estimatedDeliveryDate', '<', nowTimestamp)
      .get();

    for (const shipmentDoc of shipmentsSnapshot.docs) {
      await flagShipmentDelay(db, organization.id, shipmentDoc.id, nowTimestamp);
    }
  }
}

async function flagShipmentDelay(
  db: Firestore,
  organizationId: string,
  shipmentId: string,
  now: Timestamp,
): Promise<void> {
  const organizationRef = db.collection('organizations').doc(organizationId);
  const shipmentRef = organizationRef.collection('shipments').doc(shipmentId);
  const issueRef = organizationRef.collection('logisticsIssues').doc(`delay_${shipmentId}`);

  try {
    await db.runTransaction(async (transaction) => {
      const existingIssueSnapshot = await transaction.get(issueRef);
      if (existingIssueSnapshot.exists) return;

      const shipmentSnapshot = await transaction.get(shipmentRef);
      const shipment = shipmentSnapshot.data();
      if (!shipment) return;

      transaction.set(issueRef, {
        organizationId,
        companyId: shipment.companyId,
        shipmentId,
        orderId: shipment.orderId,
        orderNumber: shipment.orderNumber ?? null,
        customerId: shipment.customerId,
        sellerId: shipment.sellerId,
        type: 'delay',
        description: 'Prazo estimado de entrega ultrapassado sem confirmação de entrega.',
        responsibleUserId: shipment.sellerId,
        nextAction: 'Contatar a transportadora e informar o cliente sobre o novo prazo.',
        status: 'open',
        source: 'auto',
        createdAt: now,
        createdBy: 'system',
        createdByName: 'Detecção automática de atraso',
        resolvedAt: null,
        resolvedBy: null,
        resolutionNote: null,
      });

      transaction.set(
        shipmentRef,
        { hasOpenIssue: true, updatedAt: now, updatedBy: 'system', version: FieldValue.increment(1) },
        { merge: true },
      );

      appendPostSaleEvent(transaction, organizationRef, {
        eventRef: organizationRef.collection('postSaleEvents').doc(),
        organizationId,
        companyId: shipment.companyId as string,
        orderId: shipment.orderId as string,
        orderNumber: (shipment.orderNumber as string | null) ?? null,
        customerId: shipment.customerId as string,
        sellerId: shipment.sellerId as string,
        type: 'problem_reported',
        description: 'Entrega em atraso: prazo estimado ultrapassado.',
        source: 'system',
        sourceRequestId: shipmentId,
        createdBy: 'system',
        createdByName: 'Detecção automática de atraso',
        now,
      });
    });

    logger.info('detectShipmentDelays flagged shipment', { organizationId, shipmentId });
  } catch (error) {
    logger.warn('detectShipmentDelays failed to flag shipment', {
      organizationId,
      shipmentId,
      error: error instanceof Error ? error.message : String(error),
    });
  }
}
