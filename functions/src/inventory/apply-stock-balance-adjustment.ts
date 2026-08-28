import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';
import {
  FieldValue,
  getFirestore,
  Timestamp,
  type DocumentData,
  type DocumentReference,
} from 'firebase-admin/firestore';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import {
  loadActiveMembership,
  requireNonEmptyString,
  resolveActorName,
} from '../invites/invite-shared';

export interface ApplyStockBalanceAdjustmentRequest extends RequestWithMeta {
  organizationId?: string;
  companyId?: string;
  productId?: string;
  variantId?: string;
  warehouseId?: string;
  source?: string;
  idempotencyKey?: string;
  delta?: {
    physicalQuantity?: number;
    reservedQuantity?: number;
    blockedQuantity?: number;
  };
}

export interface ApplyStockBalanceAdjustmentResponse {
  balanceId: string;
  organizationId: string;
  companyId: string;
  productId: string;
  variantId: string;
  warehouseId: string;
  physicalQuantity: number;
  reservedQuantity: number;
  blockedQuantity: number;
  sellableQuantity: number;
  version: number;
  updatedAt: string;
  correlationId: string;
}

const ROLES_ALLOWED_TO_ADJUST_INVENTORY: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
]);

interface StockDelta {
  physicalQuantity: number;
  reservedQuantity: number;
  blockedQuantity: number;
}

function requireDelta(value: unknown): StockDelta {
  if (typeof value !== 'object' || value == null) {
    throw new HttpsError('invalid-argument', 'delta is required.');
  }

  const delta = value as Record<string, unknown>;
  const physicalQuantity = requireInteger(delta.physicalQuantity, 'delta.physicalQuantity');
  const reservedQuantity = requireInteger(delta.reservedQuantity, 'delta.reservedQuantity');
  const blockedQuantity = requireInteger(delta.blockedQuantity, 'delta.blockedQuantity');

  if (
    physicalQuantity === 0 &&
    reservedQuantity === 0 &&
    blockedQuantity === 0
  ) {
    throw new HttpsError(
      'invalid-argument',
      'Ao menos um delta deve ser diferente de zero.',
    );
  }

  return { physicalQuantity, reservedQuantity, blockedQuantity };
}

function requireInteger(value: unknown, field: string): number {
  if (typeof value !== 'number' || !Number.isInteger(value)) {
    throw new HttpsError('invalid-argument', `${field} must be an integer.`);
  }
  return value;
}

function balanceDocId(variantId: string, warehouseId: string): string {
  return `${variantId}_${warehouseId}`;
}

function adjustmentDocRef(
  organizationRef: DocumentReference,
  idempotencyKey: string,
): DocumentReference {
  return organizationRef.collection('inventoryAdjustments').doc(idempotencyKey);
}

function asInt(value: unknown): number {
  return typeof value === 'number' && Number.isInteger(value) ? value : 0;
}

export const applyStockBalanceAdjustment = onCall<
  ApplyStockBalanceAdjustmentRequest,
  Promise<ApplyStockBalanceAdjustmentResponse>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'É necessário estar autenticado para ajustar o saldo de estoque.',
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
  const source = requireNonEmptyString(request.data?.source, 'source');
  const idempotencyKey = requireNonEmptyString(
    request.data?.idempotencyKey,
    'idempotencyKey',
  );
  const delta = requireDelta(request.data?.delta);

  const db = getFirestore();
  const uid = request.auth.uid;
  const membership = await loadActiveMembership(db, organizationId, uid);
  if (!ROLES_ALLOWED_TO_ADJUST_INVENTORY.has(membership.roleName)) {
    throw new HttpsError(
      'permission-denied',
      'Apenas OWNER/ADMIN podem ajustar saldos de estoque.',
    );
  }

  const actorName = await resolveActorName(db, uid, request.auth.token);
  const organizationRef = db.collection('organizations').doc(organizationId);
  const balanceId = balanceDocId(variantId, warehouseId);
  const balanceRef = organizationRef.collection('inventory').doc(balanceId);
  const adjustmentRef = adjustmentDocRef(organizationRef, idempotencyKey);

  const result = await db.runTransaction<ApplyStockBalanceAdjustmentResponse>(
    async (transaction) => {
      const [organizationSnapshot, adjustmentSnapshot, balanceSnapshot] =
        await Promise.all([
          transaction.get(organizationRef),
          transaction.get(adjustmentRef),
          transaction.get(balanceRef),
        ]);

      if (!organizationSnapshot.exists) {
        throw new HttpsError('not-found', 'Organization not found.');
      }

      if (adjustmentSnapshot.exists) {
        const data = adjustmentSnapshot.data();
        if (!data) {
          throw new HttpsError('internal', 'Invalid stock adjustment record.');
        }
        return serializeBalance(balanceId, data, correlationId);
      }

      const now = Timestamp.now();
      const previous = balanceSnapshot.data();
      const nextPhysical =
        asInt(previous?.physicalQuantity) + delta.physicalQuantity;
      const nextReserved =
        asInt(previous?.reservedQuantity) + delta.reservedQuantity;
      const nextBlocked =
        asInt(previous?.blockedQuantity) + delta.blockedQuantity;

      if (nextPhysical < 0 || nextReserved < 0 || nextBlocked < 0) {
        throw new HttpsError(
          'failed-precondition',
          'O ajuste deixaria um saldo de estoque negativo em um dos campos agregados.',
        );
      }
      const nextSellable = nextPhysical - nextReserved - nextBlocked;
      if (nextSellable < 0) {
        throw new HttpsError(
          'failed-precondition',
          'O ajuste deixaria o saldo vendável negativo.',
        );
      }

      transaction.set(
        balanceRef,
        {
          organizationId,
          companyId,
          productId,
          variantId,
          warehouseId,
          physicalQuantity: FieldValue.increment(delta.physicalQuantity),
          reservedQuantity: FieldValue.increment(delta.reservedQuantity),
          blockedQuantity: FieldValue.increment(delta.blockedQuantity),
          updatedAt: now,
          updatedBy: uid,
          lastSource: source,
          version: FieldValue.increment(1),
        },
        { merge: true },
      );

      transaction.set(adjustmentRef, {
        balanceId,
        organizationId,
        companyId,
        productId,
        variantId,
        warehouseId,
        source,
        idempotencyKey,
        delta,
        physicalQuantity: nextPhysical,
        reservedQuantity: nextReserved,
        blockedQuantity: nextBlocked,
        sellableQuantity: nextSellable,
        version: asInt(previous?.version) + 1,
        updatedAt: now,
        updatedBy: uid,
        createdAt: now,
        createdBy: uid,
      });

      transaction.set(organizationRef.collection('auditLogs').doc(), {
        organizationId,
        actorUserId: uid,
        actorName,
        action: 'inventory.balanceAdjusted',
        entityType: 'inventoryBalance',
        entityId: balanceId,
        previousValue: {
          physicalQuantity: asInt(previous?.physicalQuantity),
          reservedQuantity: asInt(previous?.reservedQuantity),
          blockedQuantity: asInt(previous?.blockedQuantity),
          sellableQuantity:
            asInt(previous?.physicalQuantity) -
            asInt(previous?.reservedQuantity) -
            asInt(previous?.blockedQuantity),
          source: previous?.lastSource ?? null,
        },
        newValue: {
          physicalQuantity: nextPhysical,
          reservedQuantity: nextReserved,
          blockedQuantity: nextBlocked,
          sellableQuantity: nextSellable,
          source,
          deltaPhysicalQuantity: delta.physicalQuantity,
          deltaReservedQuantity: delta.reservedQuantity,
          deltaBlockedQuantity: delta.blockedQuantity,
          warehouseId,
          variantId,
          productId,
          companyId,
          idempotencyKey,
        },
        timestamp: now,
      });

      return {
        balanceId,
        organizationId,
        companyId,
        productId,
        variantId,
        warehouseId,
        physicalQuantity: nextPhysical,
        reservedQuantity: nextReserved,
        blockedQuantity: nextBlocked,
        sellableQuantity: nextSellable,
        version: asInt(previous?.version) + 1,
        updatedAt: now.toDate().toISOString(),
        correlationId,
      };
    },
  );

  logger.info('applyStockBalanceAdjustment succeeded', {
    correlationId,
    organizationId,
    companyId,
    productId,
    variantId,
    warehouseId,
    uid,
    source,
    idempotencyKey,
  });

  return result;
});

function serializeBalance(
  balanceId: string,
  data: DocumentData,
  correlationId: string,
): ApplyStockBalanceAdjustmentResponse {
  const updatedAt = data.updatedAt as Timestamp | undefined;
  return {
    balanceId,
    organizationId: data.organizationId as string,
    companyId: data.companyId as string,
    productId: data.productId as string,
    variantId: data.variantId as string,
    warehouseId: data.warehouseId as string,
    physicalQuantity: asInt(data.physicalQuantity),
    reservedQuantity: asInt(data.reservedQuantity),
    blockedQuantity: asInt(data.blockedQuantity),
    sellableQuantity: asInt(data.sellableQuantity),
    version: asInt(data.version),
    updatedAt: updatedAt?.toDate().toISOString() ?? new Date(0).toISOString(),
    correlationId,
  };
}
