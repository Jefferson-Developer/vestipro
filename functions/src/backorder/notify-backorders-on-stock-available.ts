import { logger } from 'firebase-functions/v2';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { FieldValue, Timestamp, getFirestore, type DocumentData, type Firestore } from 'firebase-admin/firestore';

import { asBalanceSnapshot, sellableQuantity } from '../inventory/stock-alert-shared';
import { findPortalRecipientUids } from '../buyer_collaboration/buyer-collaboration-shared';

/**
 * Firestore trigger watching every `organizations/{organizationId}/
 * inventory/{inventoryId}` write (same collection `syncStockAlerts`,
 * TASK-093, already watches) — whenever a variant's total saldo across every
 * warehouse increases, flags every still-`queued` `BackorderRequest` for
 * that variant whose own remaining quantity now fits the newly available
 * total as `ready_to_fulfill` and notifies the vendedor responsável (and, for
 * a portal cliente, the customer itself) — TASK-215, EPIC-32: "Quando
 * estoque futuro/pronta entrega ficar disponível, notificar vendedor/
 * comprador e permitir converter backorder em pedido".
 *
 * Deliberately never reserves/decrements a single unit here — `queued` →
 * `ready_to_fulfill` is only ever a heads-up ("previsão"/disponibilidade
 * aparente), never a "reserva aprovada"; `convertBackorderToOrder` is the one
 * and only place a real commitment gets made, re-validating the actual
 * sellable quantity again at that moment (`tasks.md`: "Toda promessa exibida
 * deve diferenciar previsão, reserva aprovada e disponibilidade confirmada").
 * Multiple competing `queued` requests for the same variant may all be
 * flagged `ready_to_fulfill` off the same available quantity — a known,
 * documented simplification (see this task's "Riscos conhecidos"): there is
 * no FIFO stock lock across concurrent flags, only the conversion step's own
 * final revalidation actually decides who gets it first.
 */
export const notifyBackordersOnStockAvailable = onDocumentWritten(
  'organizations/{organizationId}/inventory/{inventoryId}',
  async (event) => {
    const before = asBalanceSnapshot(event.data?.before.data());
    const after = asBalanceSnapshot(event.data?.after.data());
    if (!after) return;

    const previousQuantity = sellableQuantity(before) ?? 0;
    const currentQuantity = sellableQuantity(after) ?? 0;
    if (currentQuantity <= previousQuantity || currentQuantity <= 0) return;

    await flagReadyBackordersForVariant(
      getFirestore(),
      after.organizationId,
      after.variantId,
      currentQuantity,
    );
  },
);

export async function flagReadyBackordersForVariant(
  db: Firestore,
  organizationId: string,
  variantId: string,
  totalSellableQuantity: number,
): Promise<string[]> {
  const organizationRef = db.collection('organizations').doc(organizationId);
  const queuedSnapshot = await organizationRef
    .collection('backorders')
    .where('variantId', '==', variantId)
    .where('status', '==', 'queued')
    .get();
  if (queuedSnapshot.empty) return [];

  const now = Timestamp.now();
  const flaggedIds: string[] = [];

  for (const doc of queuedSnapshot.docs.sort(byPriorityThenAge)) {
    const backorder = doc.data();
    const remainingQuantity =
      (backorder.quantity as number) - (typeof backorder.fulfilledQuantity === 'number' ? backorder.fulfilledQuantity : 0);
    if (remainingQuantity > totalSellableQuantity) continue;

    try {
      await db.runTransaction(async (transaction) => {
        const freshSnapshot = await transaction.get(doc.ref);
        const fresh = freshSnapshot.data();
        if (!fresh || fresh.status !== 'queued') return;

        transaction.set(
          doc.ref,
          {
            status: 'ready_to_fulfill',
            expectedAvailabilityDate: now,
            readyToFulfillAt: now,
            updatedAt: now,
            updatedBy: 'system',
            version: FieldValue.increment(1),
          },
          { merge: true },
        );

        transaction.set(organizationRef.collection('notifications').doc(), {
          organizationId,
          userId: fresh.sellerId,
          category: 'commercial',
          title: 'Estoque disponível para backorder',
          body: 'Um produto pendente de estoque futuro já está disponível. Confira e converta em pedido.',
          deepLink: `/org/${organizationId}/backorders/${doc.id}`,
          metadata: { backorderId: doc.id, variantId, totalSellableQuantity },
          readAt: null,
          deliverAt: now,
          createdAt: now,
          createdBy: 'system',
        });
      });

      const recipientUids = await findPortalRecipientUids(db, organizationId, backorder.customerId as string);
      await Promise.all(
        recipientUids.map((recipientUid) =>
          organizationRef.collection('notifications').add(
            portalNotificationPayload({
              organizationId,
              userId: recipientUid,
              backorderId: doc.id,
              now,
            }),
          ),
        ),
      );

      flaggedIds.push(doc.id);
    } catch (error) {
      logger.warn('notifyBackordersOnStockAvailable failed to flag backorder', {
        organizationId,
        backorderId: doc.id,
        variantId,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  }

  if (flaggedIds.length > 0) {
    logger.info('notifyBackordersOnStockAvailable flagged backorders ready_to_fulfill', {
      organizationId,
      variantId,
      flaggedIds,
    });
  }

  return flaggedIds;
}

function byPriorityThenAge(
  left: FirebaseFirestore.QueryDocumentSnapshot,
  right: FirebaseFirestore.QueryDocumentSnapshot,
): number {
  const leftData = left.data();
  const rightData = right.data();
  const leftWeight = typeof leftData.priorityWeight === 'number' ? leftData.priorityWeight : 0;
  const rightWeight = typeof rightData.priorityWeight === 'number' ? rightData.priorityWeight : 0;
  if (leftWeight !== rightWeight) return rightWeight - leftWeight;
  const leftCreatedAt = leftData.createdAt instanceof Timestamp ? leftData.createdAt.toMillis() : 0;
  const rightCreatedAt = rightData.createdAt instanceof Timestamp ? rightData.createdAt.toMillis() : 0;
  return leftCreatedAt - rightCreatedAt;
}

function portalNotificationPayload(input: {
  organizationId: string;
  userId: string;
  backorderId: string;
  now: Timestamp;
}): DocumentData {
  return {
    organizationId: input.organizationId,
    userId: input.userId,
    category: 'commercial',
    priority: 'informative',
    title: 'Estoque disponível',
    body: 'Um produto que você aguardava já está disponível. Fale com seu vendedor para confirmar o pedido.',
    deepLink: `/customer-portal/${input.organizationId}/backorders/${input.backorderId}`,
    entityId: input.backorderId,
    createdAt: input.now,
    readAt: null,
    deliverAt: null,
  };
}
