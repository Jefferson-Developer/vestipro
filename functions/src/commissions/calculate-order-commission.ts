import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { Timestamp, getFirestore, type DocumentData } from 'firebase-admin/firestore';

import { loadActiveMembership, requireNonEmptyString, resolveActorName } from '../invites/invite-shared';
import {
  buildReversalEntryId,
  calculateCommissionForOrder,
  isCommissionableOrderStatus,
  isReversalOrderStatus,
  mapCommissionOrder,
  mapCommissionRule,
} from './commission-shared';

const COMMISSION_MANAGER_ROLES = new Set(['OWNER', 'ADMIN', 'SALES_MANAGER', 'FINANCE']);

interface CalculateOrderCommissionRequest {
  organizationId?: string;
  orderId?: string;
  sourceEventId?: string;
  reversalBaseAmount?: number;
}

interface CalculateOrderCommissionResponse {
  orderId: string;
  entryId: string | null;
  status: 'provisioned' | 'reversed' | 'skipped';
  amount: number;
}

export const calculateOrderCommission = onCall<
  CalculateOrderCommissionRequest,
  Promise<CalculateOrderCommissionResponse>
>(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Autenticacao obrigatoria.');
  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const orderId = requireNonEmptyString(request.data?.orderId, 'orderId');
  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, request.auth.uid);
  if (!COMMISSION_MANAGER_ROLES.has(membership.roleName)) {
    throw new HttpsError('permission-denied', 'Seu perfil nao pode recalcular comissoes.');
  }
  const actorName = await resolveActorName(db, request.auth.uid, request.auth.token);
  return calculateOrderCommissionTransaction(db, {
    organizationId,
    orderId,
    actorId: request.auth.uid,
    actorName,
    sourceEventId: request.data?.sourceEventId,
    reversalBaseAmount: request.data?.reversalBaseAmount,
  });
});

export async function calculateOrderCommissionTransaction(
  db: FirebaseFirestore.Firestore,
  input: {
    organizationId: string;
    orderId: string;
    actorId: string;
    actorName?: string | null;
    sourceEventId?: string;
    reversalBaseAmount?: number;
  },
): Promise<CalculateOrderCommissionResponse> {
  const organizationRef = db.collection('organizations').doc(input.organizationId);
  const orderRef = organizationRef.collection('orders').doc(input.orderId);
  return db.runTransaction(async (transaction) => {
    const orderSnapshot = await transaction.get(orderRef);
    if (!orderSnapshot.exists) {
      throw new HttpsError('not-found', 'Pedido nao encontrado.');
    }
    const order = mapCommissionOrder(orderSnapshot.id, orderSnapshot.data());
    if (order.organizationId !== input.organizationId) {
      throw new HttpsError('failed-precondition', 'Pedido fora da organizacao informada.');
    }

    if (isReversalOrderStatus(order.status)) {
      const sourceEventId = input.sourceEventId ?? `${order.status}:${input.orderId}`;
      const entryId = buildReversalEntryId(order.id, sourceEventId);
      const entryRef = organizationRef.collection('commissionEntries').doc(entryId);
      const existing = await transaction.get(entryRef);
      if (existing.exists) {
        return serializeExisting(order.id, entryId, existing.data(), 'reversed');
      }
      const provisionedSnapshot = await transaction.get(
        organizationRef.collection('commissionEntries')
          .where('orderId', '==', order.id)
          .where('status', 'in', ['provisioned', 'approved', 'paid']),
      );
      const baseAmount = typeof input.reversalBaseAmount === 'number'
        ? input.reversalBaseAmount
        : provisionedSnapshot.docs.reduce((sum, doc) => sum + amount(doc.data().commissionAmount), 0);
      const reversalAmount = -roundMoney(baseAmount);
      const now = Timestamp.now();
      transaction.set(entryRef, {
        organizationId: input.organizationId,
        companyId: order.companyId,
        orderId: order.id,
        orderNumber: order.orderNumber ?? null,
        sellerId: order.sellerId,
        sellerName: order.sellerName ?? null,
        teamIds: order.teamIds,
        ruleId: null,
        ruleSnapshot: null,
        baseAmount: roundMoney(Math.abs(baseAmount)),
        commissionType: 'reversal',
        percentage: null,
        fixedAmount: null,
        commissionAmount: reversalAmount,
        currency: order.currency,
        status: 'reversed',
        periodKey: periodKey(order.occurredAt),
        sourceEventId,
        sourceEventType: order.status,
        calculationTrace: {
          source: 'post_sale_reversal',
          orderId: order.id,
          sourceEventId,
          originalCommissionAmount: roundMoney(Math.abs(baseAmount)),
        },
        occurredAt: order.occurredAt,
        createdAt: now,
        createdBy: input.actorId,
        updatedAt: now,
        updatedBy: input.actorId,
        version: 1,
      });
      writeAudit(transaction, organizationRef, {
        actorId: input.actorId,
        actorName: input.actorName,
        orderId: order.id,
        entryId,
        amount: reversalAmount,
        action: 'commission.reversed',
        now,
      });
      return { orderId: order.id, entryId, status: 'reversed', amount: reversalAmount };
    }

    if (!isCommissionableOrderStatus(order.status)) {
      return { orderId: order.id, entryId: null, status: 'skipped', amount: 0 };
    }

    const rulesSnapshot = await transaction.get(organizationRef.collection('commissionRules'));
    const rules = rulesSnapshot.docs.map((doc) => mapCommissionRule(doc.id, doc.data()));
    const calculation = calculateCommissionForOrder(order, rules);
    const entryRef = organizationRef.collection('commissionEntries').doc(calculation.entryId);
    const existing = await transaction.get(entryRef);
    if (existing.exists) {
      return serializeExisting(order.id, calculation.entryId, existing.data(), 'provisioned');
    }
    const now = Timestamp.now();
    transaction.set(entryRef, {
      organizationId: input.organizationId,
      companyId: order.companyId,
      orderId: order.id,
      orderNumber: order.orderNumber ?? null,
      sellerId: order.sellerId,
      sellerName: order.sellerName ?? null,
      teamIds: order.teamIds,
      ruleId: calculation.rule.id,
      ruleSnapshot: {
        id: calculation.rule.id,
        type: calculation.rule.type,
        percentage: calculation.rule.percentage ?? null,
        fixedAmount: calculation.rule.fixedAmount ?? null,
        priority: calculation.rule.priority,
        companyId: calculation.rule.companyId ?? null,
        teamId: calculation.rule.teamId ?? null,
        sellerId: calculation.rule.sellerId ?? null,
        productId: calculation.rule.productId ?? null,
        campaignId: calculation.rule.campaignId ?? null,
      },
      baseAmount: calculation.baseAmount,
      commissionType: calculation.rule.type,
      percentage: calculation.rule.percentage ?? null,
      fixedAmount: calculation.rule.fixedAmount ?? null,
      commissionAmount: calculation.commissionAmount,
      currency: order.currency,
      status: 'provisioned',
      periodKey: periodKey(order.occurredAt),
      sourceEventId: input.sourceEventId ?? `order:${order.id}:${order.status}`,
      sourceEventType: order.status,
      calculationTrace: calculation.calculationTrace,
      occurredAt: order.occurredAt,
      createdAt: now,
      createdBy: input.actorId,
      updatedAt: now,
      updatedBy: input.actorId,
      version: 1,
    });
    writeAudit(transaction, organizationRef, {
      actorId: input.actorId,
      actorName: input.actorName,
      orderId: order.id,
      entryId: calculation.entryId,
      amount: calculation.commissionAmount,
      action: 'commission.provisioned',
      now,
    });
    logger.info('Commission provisioned', {
      organizationId: input.organizationId,
      orderId: order.id,
      entryId: calculation.entryId,
      amount: calculation.commissionAmount,
    });
    return {
      orderId: order.id,
      entryId: calculation.entryId,
      status: 'provisioned',
      amount: calculation.commissionAmount,
    };
  });
}

function serializeExisting(
  orderId: string,
  entryId: string,
  data: DocumentData | undefined,
  status: 'provisioned' | 'reversed',
): CalculateOrderCommissionResponse {
  return {
    orderId,
    entryId,
    status,
    amount: amount(data?.commissionAmount),
  };
}

function writeAudit(
  transaction: FirebaseFirestore.Transaction,
  organizationRef: FirebaseFirestore.DocumentReference,
  input: {
    actorId: string;
    actorName?: string | null;
    orderId: string;
    entryId: string;
    amount: number;
    action: string;
    now: Timestamp;
  },
): void {
  transaction.set(organizationRef.collection('auditLogs').doc(), {
    organizationId: organizationRef.id,
    actorUserId: input.actorId,
    actorName: input.actorName ?? input.actorId,
    action: input.action,
    entityType: 'commissionEntry',
    entityId: input.entryId,
    previousValue: null,
    newValue: { orderId: input.orderId, commissionAmount: input.amount },
    timestamp: input.now,
  });
}

function amount(value: unknown): number {
  return typeof value === 'number' && Number.isFinite(value) ? value : 0;
}

function roundMoney(value: number): number {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

function periodKey(date: Date): string {
  return `${date.getUTCFullYear()}-${String(date.getUTCMonth() + 1).padStart(2, '0')}`;
}
