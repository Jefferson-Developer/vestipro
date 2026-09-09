import { HttpsError, onCall } from 'firebase-functions/v2/https';
import {
  FieldValue,
  Timestamp,
  getFirestore,
  type DocumentData,
} from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';

import { loadActiveMembership, resolveActorName } from '../invites/invite-shared';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { createGatewayCharge } from './gateway-adapter';
import {
  computePaymentIdempotencyKey,
  computePaymentTransactionId,
  mapPaymentProvider,
  normalizeCurrencyCode,
  normalizeMoney,
  optionalString,
  requireNonEmptyString,
  selectPaymentProvider,
  serializeTimestamp,
  type PaymentProvider,
  type PaymentTransactionStatus,
} from './payment-shared';

export interface CreatePaymentChargeRequest extends RequestWithMeta {
  organizationId?: string;
  companyId?: string;
  orderId?: string;
  attempt?: number;
  idempotencyKey?: string;
  country?: string;
  currency?: string;
  clientOrderTotal?: number;
}

export interface PaymentTransactionResponse {
  correlationId: string;
  transactionId: string;
  orderId: string;
  providerId: string;
  gateway: string;
  gatewayTransactionId?: string;
  status: PaymentTransactionStatus;
  amount: number;
  currency: string;
  idempotencyKey: string;
  attempts: number;
  reason?: string;
  createdAt?: string;
  updatedAt?: string;
}

const ROLES_ALLOWED_TO_CREATE_CHARGE: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
  'SALES_MANAGER',
  'SALES_REP',
  'FINANCE',
]);

type PreparedCharge =
  | { existing: PaymentTransactionResponse }
  | { provider: PaymentProvider; amount: number; currency: string };

export const createPaymentCharge = onCall<
  CreatePaymentChargeRequest,
  Promise<PaymentTransactionResponse>
>(async (request) => {
  const startedAt = Date.now();
  const correlationId = resolveCorrelationId(request.data?._meta);
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Autenticacao obrigatoria.');
  }

  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const companyId = requireNonEmptyString(request.data?.companyId, 'companyId');
  const orderId = requireNonEmptyString(request.data?.orderId, 'orderId');
  const attempt = normalizeAttempt(request.data?.attempt);
  const expectedKey = computePaymentIdempotencyKey(orderId, attempt);
  const idempotencyKey = requireNonEmptyString(request.data?.idempotencyKey, 'idempotencyKey');
  if (idempotencyKey !== expectedKey) {
    throw new HttpsError(
      'invalid-argument',
      'idempotencyKey deve ser derivada de orderId + tentativa.',
    );
  }
  const country = requireNonEmptyString(request.data?.country, 'country').toUpperCase();
  const requestedCurrency = request.data?.currency === undefined
    ? undefined
    : normalizeCurrencyCode(request.data.currency);
  const clientOrderTotal = request.data?.clientOrderTotal === undefined
    ? undefined
    : normalizeMoney(request.data.clientOrderTotal, 'clientOrderTotal');

  const db = getFirestore();
  const uid = request.auth.uid;
  const membership = await loadActiveMembership(db, organizationId, uid);
  if (!ROLES_ALLOWED_TO_CREATE_CHARGE.has(membership.roleName)) {
    throw new HttpsError('permission-denied', 'Seu perfil nao pode iniciar cobrancas.');
  }

  const actorName = await resolveActorName(db, uid, request.auth.token);
  const orgRef = db.collection('organizations').doc(organizationId);
  const transactionId = computePaymentTransactionId(idempotencyKey);
  const transactionRef = orgRef.collection('paymentTransactions').doc(transactionId);
  const orderRef = orgRef.collection('orders').doc(orderId);

  const prepared = await db.runTransaction<PreparedCharge>(async (transaction) => {
    const existingSnapshot = await transaction.get(transactionRef);
    if (existingSnapshot.exists) {
      return { existing: serializePaymentTransaction(transactionId, existingSnapshot.data(), correlationId) };
    }

    const orderSnapshot = await transaction.get(orderRef);
    const orderData = orderSnapshot.data();
    if (!orderSnapshot.exists || !orderData) {
      throw new HttpsError('failed-precondition', 'Pedido nao encontrado.');
    }
    if (orderData.companyId !== companyId) {
      throw new HttpsError('failed-precondition', 'Pedido pertence a outra empresa.');
    }
    if (membership.roleName === 'SALES_REP' && orderData.sellerId !== uid) {
      throw new HttpsError('permission-denied', 'Representante so pode cobrar seus pedidos.');
    }

    const currency = requestedCurrency ?? requireNonEmptyString(orderData.currency, 'order.currency');
    const amount = resolveOrderTotal(orderData);
    if (clientOrderTotal !== undefined && Math.abs(clientOrderTotal - amount) > 0.01) {
      throw new HttpsError('failed-precondition', 'Valor informado diverge do total server-side do pedido.');
    }

    const providerSnapshots = await transaction.get(orgRef.collection('paymentProviders'));
    const providers = providerSnapshots.docs.map((doc) => mapPaymentProvider(doc.id, doc.data()));
    const provider = selectPaymentProvider(providers, { companyId, country, currency });
    const now = Timestamp.now();
    const baseData: DocumentData = {
      organizationId,
      companyId,
      orderId,
      providerId: provider.id,
      gateway: provider.gateway,
      status: 'pending',
      amount,
      currency,
      idempotencyKey,
      attempts: attempt,
      history: [{
        type: 'charge_requested',
        status: 'pending',
        actorId: uid,
        at: now,
      }],
      createdAt: now,
      createdBy: uid,
      updatedAt: now,
      updatedBy: uid,
      version: 1,
    };
    transaction.set(transactionRef, baseData);
    transaction.set(orgRef.collection('auditLogs').doc(), {
      organizationId,
      actorUserId: uid,
      actorName,
      action: 'payment.charge_requested',
      entityType: 'paymentTransaction',
      entityId: transactionId,
      previousValue: null,
      newValue: { orderId, providerId: provider.id, amount, currency, idempotencyKey },
      timestamp: now,
    });
    return { provider, amount, currency };
  });

  if ('existing' in prepared) return prepared.existing;

  try {
    const gatewayResult = await createGatewayCharge({
      provider: prepared.provider as PaymentProvider,
      transactionId,
      idempotencyKey,
      orderId,
      amount: prepared.amount as number,
      currency: prepared.currency as string,
    });
    await transactionRef.set({
      gatewayTransactionId: gatewayResult.gatewayTransactionId,
      status: gatewayResult.status,
      reason: gatewayResult.reason ?? null,
      history: FieldValue.arrayUnion({
        type: 'gateway_charge_created',
        status: gatewayResult.status,
        gatewayTransactionId: gatewayResult.gatewayTransactionId,
        reason: gatewayResult.reason ?? null,
        at: Timestamp.now(),
      }),
      updatedAt: Timestamp.now(),
      updatedBy: 'payment_gateway',
      version: FieldValue.increment(1),
    }, { merge: true });
  } catch (error) {
    await transactionRef.set({
      status: 'failed',
      reason: error instanceof Error ? error.message : 'Gateway indisponivel.',
      history: FieldValue.arrayUnion({
        type: 'gateway_charge_failed',
        status: 'failed',
        reason: error instanceof Error ? error.message : 'Gateway indisponivel.',
        at: Timestamp.now(),
      }),
      updatedAt: Timestamp.now(),
      updatedBy: 'payment_gateway',
      version: FieldValue.increment(1),
    }, { merge: true });
  }

  const finalSnapshot = await transactionRef.get();
  const response = serializePaymentTransaction(transactionId, finalSnapshot.data(), correlationId);
  logger.info('createPaymentCharge finished', {
    correlationId,
    organizationId,
    companyId,
    orderId,
    transactionId,
    status: response.status,
    durationMs: Date.now() - startedAt,
  });
  return response;
});

function normalizeAttempt(value: unknown): number {
  if (typeof value !== 'number' || !Number.isInteger(value) || value <= 0) {
    throw new HttpsError('invalid-argument', 'attempt must be a positive integer.');
  }
  return value;
}

function resolveOrderTotal(order: DocumentData): number {
  const items = Array.isArray(order.items) ? order.items as DocumentData[] : [];
  return normalizeMoney(
    items.reduce((sum, item) => sum + Number(item.subtotal ?? 0), 0) +
      Number(order.surchargeAmount ?? 0) +
      Number(order.shippingAmount ?? 0) +
      Number(order.taxAmount ?? 0),
    'order.total',
  );
}

export function serializePaymentTransaction(
  transactionId: string,
  data: DocumentData | undefined,
  correlationId: string,
): PaymentTransactionResponse {
  if (!data) throw new HttpsError('internal', 'Payment transaction missing.');
  return {
    correlationId,
    transactionId,
    orderId: data.orderId as string,
    providerId: data.providerId as string,
    gateway: data.gateway as string,
    gatewayTransactionId: optionalString(data.gatewayTransactionId),
    status: data.status as PaymentTransactionStatus,
    amount: Number(data.amount ?? 0),
    currency: data.currency as string,
    idempotencyKey: data.idempotencyKey as string,
    attempts: Number(data.attempts ?? 0),
    reason: optionalString(data.reason),
    createdAt: serializeTimestamp(data.createdAt),
    updatedAt: serializeTimestamp(data.updatedAt),
  };
}
