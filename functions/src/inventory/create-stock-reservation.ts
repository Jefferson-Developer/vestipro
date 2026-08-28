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
  inventoryBalanceRef,
  requirePositiveInteger,
  ROLES_ALLOWED_TO_RESERVE_STOCK,
  serializeStockReservation,
  stockReservationRef,
  resolveStockReservationTtlMinutes,
  asInt,
  type StockReservationResponse,
} from './stock-reservation-shared';

export interface CreateStockReservationRequest extends RequestWithMeta {
  organizationId?: string;
  companyId?: string;
  productId?: string;
  variantId?: string;
  warehouseId?: string;
  orderDraftId?: string;
  quantity?: number;
  idempotencyKey?: string;
}

export const createStockReservation = onCall<
  CreateStockReservationRequest,
  Promise<StockReservationResponse>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);
  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'É necessário estar autenticado para reservar estoque.',
    );
  }

  const organizationId = requireNonEmptyString(
    request.data?.organizationId,
    'organizationId',
  );
  const companyId = requireNonEmptyString(request.data?.companyId, 'companyId');
  const productId = requireNonEmptyString(request.data?.productId, 'productId');
  const variantId = requireNonEmptyString(request.data?.variantId, 'variantId');
  const warehouseId = requireNonEmptyString(
    request.data?.warehouseId,
    'warehouseId',
  );
  const orderDraftId = requireNonEmptyString(
    request.data?.orderDraftId,
    'orderDraftId',
  );
  const reservationId = requireNonEmptyString(
    request.data?.idempotencyKey,
    'idempotencyKey',
  );
  const quantity = requirePositiveInteger(request.data?.quantity, 'quantity');

  const db = getFirestore();
  const uid = request.auth.uid;
  const membership = await loadActiveMembership(db, organizationId, uid);
  if (!ROLES_ALLOWED_TO_RESERVE_STOCK.has(membership.roleName)) {
    throw new HttpsError(
      'permission-denied',
      'Seu perfil nao pode criar reservas comerciais de estoque.',
    );
  }

  const actorName = await resolveActorName(db, uid, request.auth.token);
  const organizationRef = db.collection('organizations').doc(organizationId);
  const reservationRef = stockReservationRef(organizationRef, reservationId);
  const balanceRef = inventoryBalanceRef(organizationRef, variantId, warehouseId);

  const result = await db.runTransaction<StockReservationResponse>(
    async (transaction) => {
      const [organizationSnapshot, reservationSnapshot, balanceSnapshot] =
        await Promise.all([
          transaction.get(organizationRef),
          transaction.get(reservationRef),
          transaction.get(balanceRef),
        ]);

      if (!organizationSnapshot.exists) {
        throw new HttpsError('not-found', 'Organization not found.');
      }

      if (reservationSnapshot.exists) {
        const existing = reservationSnapshot.data();
        if (!existing) {
          throw new HttpsError('internal', 'Invalid stock reservation record.');
        }
        return serializeStockReservation(reservationId, existing, correlationId);
      }

      const balance = balanceSnapshot.data();
      const physicalQuantity = asInt(balance?.physicalQuantity);
      const reservedQuantity = asInt(balance?.reservedQuantity);
      const blockedQuantity = asInt(balance?.blockedQuantity);
      const sellableQuantity =
        physicalQuantity - reservedQuantity - blockedQuantity;
      if (sellableQuantity < quantity) {
        throw new HttpsError(
          'failed-precondition',
          'Nao ha saldo vendavel suficiente para reservar esta quantidade.',
        );
      }

      const now = Timestamp.now();
      const ttlMinutes = resolveStockReservationTtlMinutes(
        organizationSnapshot.data(),
      );
      const expiresAt = Timestamp.fromDate(
        new Date(now.toMillis() + ttlMinutes * 60 * 1000),
      );

      transaction.set(
        balanceRef,
        {
          organizationId,
          companyId,
          productId,
          variantId,
          warehouseId,
          physicalQuantity,
          reservedQuantity: FieldValue.increment(quantity),
          blockedQuantity,
          updatedAt: now,
          updatedBy: uid,
          lastSource: 'stock_reservation',
          version: FieldValue.increment(1),
        },
        { merge: true },
      );

      transaction.set(reservationRef, {
        organizationId,
        companyId,
        productId,
        variantId,
        warehouseId,
        orderDraftId,
        quantity,
        reservedBy: uid,
        reservedAt: now,
        expiresAt,
        status: 'active',
        version: 1,
        createdAt: now,
        createdBy: uid,
        updatedAt: now,
        updatedBy: uid,
      });

      transaction.set(organizationRef.collection('auditLogs').doc(), {
        organizationId,
        actorUserId: uid,
        actorName,
        action: 'inventory.stockReserved',
        entityType: 'stockReservation',
        entityId: reservationId,
        previousValue: null,
        newValue: {
          companyId,
          productId,
          variantId,
          warehouseId,
          orderDraftId,
          quantity,
          expiresAt,
        },
        timestamp: now,
      });

      return serializeStockReservation(
        reservationId,
        {
          organizationId,
          companyId,
          productId,
          variantId,
          warehouseId,
          orderDraftId,
          quantity,
          reservedBy: uid,
          reservedAt: now,
          expiresAt,
          status: 'active',
        },
        correlationId,
      );
    },
  );

  logger.info('createStockReservation succeeded', {
    correlationId,
    organizationId,
    companyId,
    productId,
    variantId,
    warehouseId,
    orderDraftId,
    reservationId,
    quantity,
    uid,
  });

  return result;
});
