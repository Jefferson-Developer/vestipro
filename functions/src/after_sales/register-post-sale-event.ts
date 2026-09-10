import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { Timestamp, getFirestore, type DocumentData } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import {
  loadActiveMembership,
  requireNonEmptyString,
  resolveActorName,
} from '../invites/invite-shared';
import {
  ensureRequesterMayActOnOrder,
  mapReturnRequestOrder,
  normalizeTeamIds,
} from '../returns/return-shared';
import {
  appendPostSaleEvent,
  isPostSaleEventEligibleOrderStatus,
  requireManualPostSaleEventType,
  requirePostSaleDescription,
  type ManualPostSaleEventType,
} from './after-sales-shared';

/**
 * Only these roles may ever register a manual pós-venda milestone (TASK-201,
 * EPIC-30) — "vendedor/suporte" (`tasks.md`), never o próprio cliente pelo
 * portal (que ainda não tem um fluxo próprio de auto-registro de pós-venda
 * nesta task — ver "Pendências").
 */
const ROLES_ALLOWED_TO_REGISTER_POST_SALE_EVENT: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
  'SALES_MANAGER',
  'SALES_REP',
]);

export interface RegisterPostSaleEventRequest extends RequestWithMeta {
  organizationId?: string;
  companyId?: string;
  orderId?: string;
  eventId?: string;
  type?: ManualPostSaleEventType;
  description?: string;
}

export interface RegisterPostSaleEventResponse {
  correlationId: string;
  eventId: string;
  orderId: string;
  type: ManualPostSaleEventType;
  description: string | null;
  createdAt: string;
}

/**
 * Idempotent Cloud Function registering one manual pós-venda milestone
 * (TASK-201, EPIC-30) onto a pedido's own timeline — despachado, em trânsito,
 * entregue, problema reportado, em resolução ou resolvido, registrado por
 * vendedor/suporte (`tasks.md`: "permite registro manual por vendedor/
 * suporte"). Every event is immutable once written (`tasks.md`: "histórico
 * não é editado, apenas complementado com novos eventos") — this Function
 * only ever creates a new `postSaleEvents` document, never updates one.
 *
 * [RegisterPostSaleEventRequest.eventId] is the client-generated idempotency
 * key *and* the resulting document id, same precedent
 * `createReturnRequest`'s own `returnRequestId` already sets: a resubmission
 * (double tap, retry after a dropped response) always carries the very same
 * id, so it can never register the same evento twice.
 */
export const registerPostSaleEvent = onCall<
  RegisterPostSaleEventRequest,
  Promise<RegisterPostSaleEventResponse>
>(async (request) => {
  const startedAt = Date.now();
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'É necessário estar autenticado para registrar um evento de pós-venda.',
    );
  }
  const uid = request.auth.uid;

  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const companyId = requireNonEmptyString(request.data?.companyId, 'companyId');
  const orderId = requireNonEmptyString(request.data?.orderId, 'orderId');
  const eventId = requireNonEmptyString(request.data?.eventId, 'eventId');
  const type = requireManualPostSaleEventType(request.data?.type);

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  if (!ROLES_ALLOWED_TO_REGISTER_POST_SALE_EVENT.has(membership.roleName)) {
    throw new HttpsError(
      'permission-denied',
      'Seu perfil não pode registrar eventos de pós-venda.',
    );
  }

  const actorName = await resolveActorName(db, uid, request.auth.token);
  const organizationRef = db.collection('organizations').doc(organizationId);
  const orderRef = organizationRef.collection('orders').doc(orderId);
  const eventRef = organizationRef.collection('postSaleEvents').doc(eventId);

  let requesterTeamIds: string[] = [];
  if (membership.roleName === 'SALES_MANAGER') {
    const requesterMemberSnapshot = await organizationRef.collection('members').doc(uid).get();
    requesterTeamIds = normalizeTeamIds(requesterMemberSnapshot.data()?.teamIds);
  }

  const result = await db.runTransaction<RegisterPostSaleEventResponse>(async (transaction) => {
    const existingSnapshot = await transaction.get(eventRef);
    if (existingSnapshot.exists) {
      const existing = existingSnapshot.data();
      if (!existing) throw new HttpsError('internal', 'Invalid post-sale event record.');
      return serializeEvent(eventId, existing, correlationId);
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
    if (!isPostSaleEventEligibleOrderStatus(order.status)) {
      throw new HttpsError(
        'failed-precondition',
        'Este pedido não está em um status elegível para acompanhamento de pós-venda.',
      );
    }

    await ensureRequesterMayActOnOrder(transaction, organizationRef, {
      roleName: membership.roleName,
      uid,
      order,
      requesterTeamIds,
    });

    const description = requirePostSaleDescription(type, request.data?.description);
    const now = Timestamp.now();
    appendPostSaleEvent(transaction, organizationRef, {
      eventRef,
      organizationId,
      companyId,
      orderId,
      orderNumber: order.orderNumber,
      customerId: order.customerId,
      sellerId: order.sellerId,
      type,
      description,
      source: 'manual',
      sourceRequestId: null,
      createdBy: uid,
      createdByName: actorName,
      now,
    });

    return {
      correlationId,
      eventId,
      orderId,
      type,
      description,
      createdAt: now.toDate().toISOString(),
    };
  });

  logger.info('registerPostSaleEvent succeeded', {
    correlationId,
    organizationId,
    companyId,
    orderId,
    eventId,
    type,
    uid,
    durationMs: Date.now() - startedAt,
  });

  return result;
});

function serializeEvent(
  eventId: string,
  data: DocumentData,
  correlationId: string,
): RegisterPostSaleEventResponse {
  const createdAt = data.createdAt as Timestamp;
  return {
    correlationId,
    eventId,
    orderId: data.orderId as string,
    type: data.type as ManualPostSaleEventType,
    description: (data.description as string | null) ?? null,
    createdAt: createdAt.toDate().toISOString(),
  };
}
