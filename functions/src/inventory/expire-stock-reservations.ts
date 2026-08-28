import { logger } from 'firebase-functions/v2';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { FieldValue, Timestamp, getFirestore, type Firestore } from 'firebase-admin/firestore';
import { asInt, inventoryBalanceRef } from './stock-reservation-shared';

export interface ExpireStockReservationsSummary {
  organizationsProcessed: number;
  reservationsExpired: number;
  reservationsSkipped: number;
}

export const expireStockReservations = onSchedule(
  {
    schedule: '*/5 * * * *',
    timeZone: 'America/Sao_Paulo',
    region: 'southamerica-east1',
  },
  async () => {
    const summary = await expireStockReservationsForAllOrganizations(
      getFirestore(),
      new Date(),
    );
    logger.info('Stock reservation expiration finished', summary);
  },
);

export async function expireStockReservationsForAllOrganizations(
  db: Firestore,
  now: Date,
): Promise<ExpireStockReservationsSummary> {
  const organizationsSnapshot = await db.collection('organizations').get();
  let organizationsProcessed = 0;
  let reservationsExpired = 0;
  let reservationsSkipped = 0;

  for (const organizationDoc of organizationsSnapshot.docs) {
    const data = organizationDoc.data();
    if (data.deletedAt != null || data.status === 'inactive') {
      continue;
    }

    const summary = await expireStockReservationsForOrganization(
      db,
      organizationDoc.id,
      now,
    );
    organizationsProcessed += 1;
    reservationsExpired += summary.reservationsExpired;
    reservationsSkipped += summary.reservationsSkipped;
  }

  return { organizationsProcessed, reservationsExpired, reservationsSkipped };
}

export async function expireStockReservationsForOrganization(
  db: Firestore,
  organizationId: string,
  now: Date,
): Promise<Omit<ExpireStockReservationsSummary, 'organizationsProcessed'>> {
  const organizationRef = db.collection('organizations').doc(organizationId);
  const expiredReservationsSnapshot = await organizationRef
    .collection('stockReservations')
    .where('status', '==', 'active')
    .where('expiresAt', '<=', Timestamp.fromDate(now))
    .get();

  let reservationsExpired = 0;
  let reservationsSkipped = 0;

  for (const reservationSnapshot of expiredReservationsSnapshot.docs) {
    try {
      await db.runTransaction(async (transaction) => {
        const freshReservationSnapshot = await transaction.get(
          reservationSnapshot.ref,
        );
        const reservation = freshReservationSnapshot.data();
        if (!freshReservationSnapshot.exists || !reservation) {
          reservationsSkipped += 1;
          return;
        }
        if (reservation.status !== 'active') {
          reservationsSkipped += 1;
          return;
        }
        const expiresAt = reservation.expiresAt as Timestamp | undefined;
        if (!expiresAt || expiresAt.toDate().getTime() > now.getTime()) {
          reservationsSkipped += 1;
          return;
        }

        const balanceRef = inventoryBalanceRef(
          organizationRef,
          reservation.variantId as string,
          reservation.warehouseId as string,
        );
        const balanceSnapshot = await transaction.get(balanceRef);
        const balance = balanceSnapshot.data();
        const quantity = asInt(reservation.quantity);
        const nextReserved = asInt(balance?.reservedQuantity) - quantity;
        if (nextReserved < 0) {
          reservationsSkipped += 1;
          return;
        }

        const timestamp = Timestamp.fromDate(now);
        transaction.set(
          balanceRef,
          {
            reservedQuantity: FieldValue.increment(-quantity),
            updatedAt: timestamp,
            updatedBy: 'stock-reservation-expirer',
            lastSource: 'stock_reservation_expiration',
            version: FieldValue.increment(1),
          },
          { merge: true },
        );
        transaction.update(reservationSnapshot.ref, {
          status: 'expired',
          updatedAt: timestamp,
          updatedBy: 'stock-reservation-expirer',
          expiredAtProcessedAt: timestamp,
          version: FieldValue.increment(1),
        });
        transaction.set(organizationRef.collection('auditLogs').doc(), {
          organizationId,
          actorUserId: 'system',
          actorName: 'Stock Reservation Expirer',
          action: 'inventory.stockReservationExpired',
          entityType: 'stockReservation',
          entityId: reservationSnapshot.id,
          previousValue: {
            status: reservation.status,
            quantity,
          },
          newValue: {
            status: 'expired',
            quantity,
          },
          timestamp,
        });
        reservationsExpired += 1;
      });
    } catch (error) {
      logger.error('expireStockReservations skipped a reservation', {
        organizationId,
        reservationId: reservationSnapshot.id,
        error,
      });
      reservationsSkipped += 1;
    }
  }

  return { reservationsExpired, reservationsSkipped };
}
