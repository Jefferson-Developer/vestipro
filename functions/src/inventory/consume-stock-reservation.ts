import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import {
  loadActiveMembership,
  requireNonEmptyString,
  resolveActorName,
} from '../invites/invite-shared';
import {
  asInt,
  inventoryBalanceRef,
  ROLES_ALLOWED_TO_RESERVE_STOCK,
  serializeStockReservation,
  stockReservationRef,
  type StockReservationResponse,
} from './stock-reservation-shared';

export interface ConsumeStockReservationRequest extends RequestWithMeta {
  organizationId?: string;
  reservationId?: string;
}

export const consumeStockReservation = onCall<
  ConsumeStockReservationRequest,
  Promise<StockReservationResponse>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);
  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'É necessário estar autenticado para consumir uma reserva.',
    );
  }

  const organizationId = requireNonEmptyString(
    request.data?.organizationId,
    'organizationId',
  );
  const reservationId = requireNonEmptyString(
    request.data?.reservationId,
    'reservationId',
  );

  const db = getFirestore();
  const uid = request.auth.uid;
  const membership = await loadActiveMembership(db, organizationId, uid);
  if (!ROLES_ALLOWED_TO_RESERVE_STOCK.has(membership.roleName)) {
    throw new HttpsError(
      'permission-denied',
      'Seu perfil nao pode consumir reservas comerciais de estoque.',
    );
  }

  const actorName = await resolveActorName(db, uid, request.auth.token);
  const organizationRef = db.collection('organizations').doc(organizationId);
  const reservationRef = stockReservationRef(organizationRef, reservationId);

  const result = await db.runTransaction<StockReservationResponse>(
    async (transaction) => {
      const reservationSnapshot = await transaction.get(reservationRef);
      if (!reservationSnapshot.exists) {
        throw new HttpsError('not-found', 'Stock reservation not found.');
      }
      const reservation = reservationSnapshot.data();
      if (!reservation) {
        throw new HttpsError('internal', 'Invalid stock reservation record.');
      }

      if (reservation.status !== 'active') {
        return serializeStockReservation(reservationId, reservation, correlationId);
      }

      const quantity = asInt(reservation.quantity);
      const balanceRef = inventoryBalanceRef(
        organizationRef,
        reservation.variantId as string,
        reservation.warehouseId as string,
      );
      const balanceSnapshot = await transaction.get(balanceRef);
      const balance = balanceSnapshot.data();
      const nextPhysical = asInt(balance?.physicalQuantity) - quantity;
      const nextReserved = asInt(balance?.reservedQuantity) - quantity;
      const nextBlocked = asInt(balance?.blockedQuantity);
      if (nextPhysical < 0 || nextReserved < 0) {
        throw new HttpsError(
          'failed-precondition',
          'O consumo da reserva deixaria o saldo fisico ou reservado negativo.',
        );
      }
      if (nextPhysical - nextReserved - nextBlocked < 0) {
        throw new HttpsError(
          'failed-precondition',
          'O consumo da reserva deixaria o saldo vendavel negativo.',
        );
      }

      const now = Timestamp.now();
      transaction.set(
        balanceRef,
        {
          physicalQuantity: FieldValue.increment(-quantity),
          reservedQuantity: FieldValue.increment(-quantity),
          updatedAt: now,
          updatedBy: uid,
          lastSource: 'stock_reservation_consumption',
          version: FieldValue.increment(1),
        },
        { merge: true },
      );
      transaction.update(reservationRef, {
        status: 'consumed',
        consumedAt: now,
        consumedBy: uid,
        updatedAt: now,
        updatedBy: uid,
        version: FieldValue.increment(1),
      });
      transaction.set(organizationRef.collection('auditLogs').doc(), {
        organizationId,
        actorUserId: uid,
        actorName,
        action: 'inventory.stockReservationConsumed',
        entityType: 'stockReservation',
        entityId: reservationId,
        previousValue: {
          status: reservation.status,
          quantity,
        },
        newValue: {
          status: 'consumed',
          quantity,
        },
        timestamp: now,
      });

      return serializeStockReservation(
        reservationId,
        {
          ...reservation,
          status: 'consumed',
          consumedAt: now,
          consumedBy: uid,
        },
        correlationId,
      );
    },
  );

  logger.info('consumeStockReservation succeeded', {
    correlationId,
    organizationId,
    reservationId,
    uid,
  });

  return result;
});
