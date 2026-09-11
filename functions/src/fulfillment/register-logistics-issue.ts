import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { FieldValue, Timestamp, getFirestore, type DocumentData } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { loadActiveMembership, requireNonEmptyString, resolveActorName } from '../invites/invite-shared';
import { appendPostSaleEvent } from '../after_sales/after-sales-shared';
import {
  ROLES_ALLOWED_TO_MANAGE_SHIPMENT,
  ensureRequesterMayActOnOrder,
  mapReturnRequestOrder,
  normalizeTeamIds,
  requireBoundedString,
  requireLogisticsIssueType,
  type LogisticsIssueType,
} from './fulfillment-shared';

const MAX_DESCRIPTION_LENGTH = 1000;
const MAX_NEXT_ACTION_LENGTH = 500;

export interface RegisterLogisticsIssueRequest extends RequestWithMeta {
  organizationId?: string;
  companyId?: string;
  shipmentId?: string;
  logisticsIssueId?: string;
  type?: LogisticsIssueType;
  description?: string;
  responsibleUserId?: string;
  nextAction?: string;
}

export interface RegisterLogisticsIssueResponse {
  correlationId: string;
  logisticsIssueId: string;
  shipmentId: string;
  status: 'open';
}

/**
 * Idempotent callable opening a `LogisticsIssue`/ocorrência against an
 * existing `Shipment` (TASK-214, EPIC-32): atraso, avaria, divergência de
 * volume, endereço inválido ou devolução de transporte — always carrying a
 * [RegisterLogisticsIssueRequest.responsibleUserId] and
 * [RegisterLogisticsIssueRequest.nextAction] (`tasks.md`: "com responsável e
 * próxima ação"), never an empty occurrence record. Bridges into the
 * pedido's own pós-venda timeline via `appendPostSaleEvent` (`problem_reported`,
 * which already notifies the vendedor responsável) instead of a second,
 * independently-drifting notification pathway, and additionally notifies
 * [RegisterLogisticsIssueRequest.responsibleUserId] directly whenever that
 * differs from the pedido's own seller (e.g. a gestor/coordenador logístico
 * assigned as the ocorrência's responsável).
 */
export const registerLogisticsIssue = onCall<
  RegisterLogisticsIssueRequest,
  Promise<RegisterLogisticsIssueResponse>
>(async (request) => {
  const startedAt = Date.now();
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'É necessário estar autenticado para registrar uma ocorrência.');
  }
  const uid = request.auth.uid;

  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const shipmentId = requireNonEmptyString(request.data?.shipmentId, 'shipmentId');
  const logisticsIssueId = requireNonEmptyString(request.data?.logisticsIssueId, 'logisticsIssueId');
  const type = requireLogisticsIssueType(request.data?.type);
  const description = requireBoundedString(request.data?.description, 'description', MAX_DESCRIPTION_LENGTH);
  const responsibleUserId = requireNonEmptyString(request.data?.responsibleUserId, 'responsibleUserId');
  const nextAction = requireBoundedString(request.data?.nextAction, 'nextAction', MAX_NEXT_ACTION_LENGTH);

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  if (!ROLES_ALLOWED_TO_MANAGE_SHIPMENT.has(membership.roleName)) {
    throw new HttpsError('permission-denied', 'Seu perfil não pode registrar ocorrências logísticas.');
  }
  const actorName = await resolveActorName(db, uid, request.auth.token);

  const organizationRef = db.collection('organizations').doc(organizationId);
  const shipmentRef = organizationRef.collection('shipments').doc(shipmentId);
  const issueRef = organizationRef.collection('logisticsIssues').doc(logisticsIssueId);

  let requesterTeamIds: string[] = [];
  if (membership.roleName === 'SALES_MANAGER') {
    const requesterMemberSnapshot = await organizationRef.collection('members').doc(uid).get();
    requesterTeamIds = normalizeTeamIds(requesterMemberSnapshot.data()?.teamIds);
  }

  const result = await db.runTransaction<RegisterLogisticsIssueResponse>(async (transaction) => {
    const existingIssueSnapshot = await transaction.get(issueRef);
    if (existingIssueSnapshot.exists) {
      return { correlationId, logisticsIssueId, shipmentId, status: 'open' };
    }

    const shipmentSnapshot = await transaction.get(shipmentRef);
    if (!shipmentSnapshot.exists) {
      throw new HttpsError('failed-precondition', 'Expedição não encontrada.');
    }
    const shipment = shipmentSnapshot.data();
    if (!shipment || shipment.organizationId !== organizationId) {
      throw new HttpsError('failed-precondition', 'Expedição não pertence à organização informada.');
    }

    const orderRef = organizationRef.collection('orders').doc(shipment.orderId as string);
    const orderSnapshot = await transaction.get(orderRef);
    if (!orderSnapshot.exists) {
      throw new HttpsError('failed-precondition', 'Pedido vinculado à expedição não encontrado.');
    }
    const order = mapReturnRequestOrder(orderRef.id, orderSnapshot.data());

    await ensureRequesterMayActOnOrder(transaction, organizationRef, {
      roleName: membership.roleName,
      uid,
      order,
      requesterTeamIds,
    });

    const now = Timestamp.now();
    const issueData: DocumentData = {
      organizationId,
      companyId: shipment.companyId,
      shipmentId,
      orderId: shipment.orderId,
      orderNumber: shipment.orderNumber ?? null,
      customerId: shipment.customerId,
      sellerId: shipment.sellerId,
      type,
      description,
      responsibleUserId,
      nextAction,
      status: 'open',
      source: 'manual',
      createdAt: now,
      createdBy: uid,
      createdByName: actorName,
      resolvedAt: null,
      resolvedBy: null,
      resolutionNote: null,
    };
    transaction.set(issueRef, issueData);
    transaction.set(shipmentRef, { hasOpenIssue: true, updatedAt: now, updatedBy: uid, version: FieldValue.increment(1) }, { merge: true });

    appendPostSaleEvent(transaction, organizationRef, {
      eventRef: organizationRef.collection('postSaleEvents').doc(),
      organizationId,
      companyId: shipment.companyId as string,
      orderId: shipment.orderId as string,
      orderNumber: (shipment.orderNumber as string | null) ?? null,
      customerId: shipment.customerId as string,
      sellerId: shipment.sellerId as string,
      type: 'problem_reported',
      description: `Ocorrência de expedição (${type}): ${description}`,
      source: 'system',
      sourceRequestId: logisticsIssueId,
      createdBy: uid,
      createdByName: actorName,
      now,
    });

    if (responsibleUserId !== shipment.sellerId) {
      transaction.set(organizationRef.collection('notifications').doc(), {
        organizationId,
        userId: responsibleUserId,
        category: 'commercial',
        title: 'Ocorrência logística atribuída a você',
        body: `Uma ocorrência (${type}) foi registrada para o pedido ${
          shipment.orderNumber ?? shipment.orderId
        }. Próxima ação: ${nextAction}`,
        deepLink: `/org/${organizationId}/companies/${shipment.companyId}/orders/${shipment.orderId}/history`,
        metadata: { shipmentId, logisticsIssueId, orderId: shipment.orderId, type },
        readAt: null,
        deliverAt: now,
        createdAt: now,
        createdBy: uid,
      });
    }

    transaction.set(organizationRef.collection('auditLogs').doc(), {
      organizationId,
      actorUserId: uid,
      actorName,
      action: 'logisticsIssue.registered',
      entityType: 'shipment',
      entityId: shipmentId,
      previousValue: null,
      newValue: { logisticsIssueId, type, responsibleUserId },
      timestamp: now,
    });

    return { correlationId, logisticsIssueId, shipmentId, status: 'open' };
  });

  logger.info('registerLogisticsIssue succeeded', {
    correlationId,
    organizationId,
    shipmentId,
    logisticsIssueId,
    type,
    uid,
    durationMs: Date.now() - startedAt,
  });

  return result;
});
