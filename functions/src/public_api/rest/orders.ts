import { randomUUID } from 'node:crypto';

import type { Request, Response } from 'express';
import {
  Timestamp,
  getFirestore,
  type DocumentData,
  type DocumentSnapshot,
  type Query,
  type QueryDocumentSnapshot,
} from 'firebase-admin/firestore';
import type { CallableRequest } from 'firebase-functions/v2/https';

import { decodeCursor, encodeCursor, parsePageSize } from '../api-key-shared';
import { sendApiError } from './middleware';
import { loadActiveMembership } from '../../invites/invite-shared';
import {
  submitOrder,
  type SubmitOrderRequest,
  type SubmitOrderResponse,
} from '../../orders/submit-order';

/** `GET /v1/orders` (TASK-171, `orders:read` scope) — cursor-paginated
 * listing of every non-deleted `Order` in the resolved API key's own
 * organization. */
export async function listOrders(req: Request, res: Response): Promise<void> {
  const { organizationId } = req.apiKey!;
  const db = getFirestore();
  const pageSize = parsePageSize(req.query.limit);
  const cursor = decodeCursor(
    typeof req.query.cursor === 'string' ? req.query.cursor : undefined,
  );

  let query: Query = db
    .collection('organizations')
    .doc(organizationId)
    .collection('orders')
    .where('deletedAt', '==', null)
    .orderBy('createdAt', 'asc')
    .orderBy('__name__', 'asc')
    .limit(pageSize + 1);

  if (cursor) {
    query = query.startAfter(Timestamp.fromMillis(cursor.createdAtMs), cursor.id);
  }

  const snapshot = await query.get();
  const docs = snapshot.docs.slice(0, pageSize);
  const hasMore = snapshot.docs.length > pageSize;
  const last = docs[docs.length - 1];

  res.json({
    data: docs.map(serializeOrderSummary),
    nextCursor:
      hasMore && last
        ? encodeCursor({
            createdAtMs: toMillis(last.data().createdAt),
            id: last.id,
          })
        : null,
  });
}

/** `GET /v1/orders/:id` (TASK-171, `orders:read` scope). */
export async function getOrderById(req: Request, res: Response): Promise<void> {
  const { organizationId } = req.apiKey!;
  const db = getFirestore();
  const snapshot = await db
    .collection('organizations')
    .doc(organizationId)
    .collection('orders')
    .doc(req.params.id)
    .get();

  const data = snapshot.data();
  if (
    !snapshot.exists ||
    !data ||
    data.deletedAt !== null ||
    data.organizationId !== organizationId
  ) {
    sendApiError(res, 404, 'not_found', 'Pedido não encontrado.');
    return;
  }

  res.json({ data: serializeOrderSummary(snapshot) });
}

/**
 * `POST /v1/orders` (TASK-171, `orders:write` scope) — creates a pedido on
 * behalf of an active seller of the resolved API key's own organization.
 *
 * Deliberately does **not** re-implement pricing/stock/order-number/approval
 * logic: it builds a synthetic `CallableRequest<SubmitOrderRequest>` and
 * invokes `submitOrder.run(...)` (the exact same Cloud Function
 * `lib/features/orders` calls, TASK-101) directly, in-process — a supported,
 * documented way to call one Cloud Function's handler from another
 * (`CallableFunction.run`, `firebase-functions` v2). This is the load-
 * bearing reason the public API can never become "an atalho que ignora
 * regra de domínio" (TASK-171): every rule `submitOrder` itself enforces
 * (tabela de preço vigente, condição de pagamento válida, desconto dentro da
 * política, disponibilidade de estoque, numeração sequencial, idempotência
 * por `orderId`, roteamento para aprovação) runs unmodified, from the exact
 * same source file, for a REST-originated pedido as for one submitted from
 * the app.
 *
 * `organizationId` is always the one resolved from the API key
 * (`req.apiKey!.organizationId`) — never whatever the request body claims,
 * even if present. `sellerId` (required in the body) must resolve to a real,
 * active Membership of that same organization before this even attempts
 * `submitOrder.run`; that resolved `sellerId` is also the `uid` this
 * synthetic request's `auth` context carries, so `submitOrder`'s own
 * `sellerId !== uid` anti-impersonation check trivially holds. Known
 * limitation (documented in
 * `docs/tasks/TASK-171-implementar-api-publica-CONCLUIDA.md`): unlike the
 * mobile app (where `uid` comes from a verified Firebase Auth ID token, so
 * that check really does prove "this exact signed-in user"), a
 * server-to-server API key request has no per-user credential of its own —
 * `orders:write` plus a valid `sellerId` is the full extent of what this
 * task authenticates the caller *as*. A future OAuth 2.0
 * client-credentials-per-user flow (explicitly marked "opcional" in this
 * task's own backlog) would be the way to close that gap.
 */
export async function createOrder(req: Request, res: Response): Promise<void> {
  const { organizationId } = req.apiKey!;
  const body: Record<string, unknown> =
    typeof req.body === 'object' && req.body !== null ? req.body : {};

  const sellerId = typeof body.sellerId === 'string' ? body.sellerId.trim() : '';
  if (!sellerId) {
    sendApiError(res, 400, 'invalid_argument', 'sellerId é obrigatório.');
    return;
  }

  const db = getFirestore();
  try {
    await loadActiveMembership(db, organizationId, sellerId);
  } catch {
    sendApiError(
      res,
      400,
      'invalid_argument',
      'sellerId não corresponde a um membro ativo desta organização.',
    );
    return;
  }

  const orderId =
    typeof body.orderId === 'string' && body.orderId.trim().length > 0
      ? body.orderId.trim()
      : randomUUID();

  const callableRequest = {
    data: { ...body, organizationId, sellerId, orderId } as SubmitOrderRequest,
    auth: { uid: sellerId, token: {}, rawToken: '' },
    rawRequest: req,
    acceptsStreaming: false,
  } as unknown as CallableRequest<SubmitOrderRequest>;

  try {
    const result: SubmitOrderResponse = await submitOrder.run(callableRequest);
    res.status(201).json({ data: result });
  } catch (error) {
    mapAndSendSubmitOrderError(res, error);
  }
}

function mapAndSendSubmitOrderError(res: Response, error: unknown): void {
  const httpsError = error as { code?: string; message?: string };
  const statusByCode: Record<string, number> = {
    'invalid-argument': 400,
    unauthenticated: 401,
    'permission-denied': 403,
    'not-found': 404,
    'already-exists': 409,
    'failed-precondition': 409,
    'resource-exhausted': 429,
    internal: 500,
  };
  const code = httpsError.code ?? 'internal';
  const status = statusByCode[code] ?? 500;
  sendApiError(
    res,
    status,
    code,
    httpsError.message ?? 'Erro inesperado ao processar o pedido.',
  );
}

function serializeOrderSummary(
  doc: QueryDocumentSnapshot | DocumentSnapshot,
): DocumentData {
  const data = doc.data() ?? {};
  const items = Array.isArray(data.items) ? (data.items as DocumentData[]) : [];
  const itemsSubtotal = items.reduce((sum, item) => sum + asNumber(item.subtotal), 0);
  return {
    id: doc.id,
    companyId: data.companyId ?? null,
    orderNumber: data.orderNumber ?? null,
    status: data.status ?? null,
    customerId: data.customerId ?? null,
    sellerId: data.sellerId ?? null,
    // ISO 4217 code (TASK-175) — every monetary field below is expressed in
    // this currency (the order's own Price List), so an integration
    // consuming this API never has to guess/assume BRL. Falls back to
    // VestiPro's original single-market currency only for an order
    // submitted before `submitOrder` started persisting this field.
    currency: typeof data.currency === 'string' ? data.currency : 'BRL',
    discountAmount: asNumber(data.discountAmount),
    surchargeAmount: asNumber(data.surchargeAmount),
    shippingAmount: asNumber(data.shippingAmount),
    total: roundCurrency(
      itemsSubtotal + asNumber(data.surchargeAmount) + asNumber(data.shippingAmount),
    ),
    createdAt: isoOrNull(data.createdAt),
    updatedAt: isoOrNull(data.updatedAt),
  };
}

function asNumber(value: unknown): number {
  return typeof value === 'number' && !Number.isNaN(value) ? value : 0;
}

function roundCurrency(value: number): number {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

function toMillis(value: unknown): number {
  return value instanceof Timestamp ? value.toMillis() : 0;
}

function isoOrNull(value: unknown): string | null {
  return value instanceof Timestamp ? value.toDate().toISOString() : null;
}
