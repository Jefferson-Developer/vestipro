import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { Timestamp, getFirestore, type DocumentData } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { loadActiveMembership, requireNonEmptyString, resolveActorName } from '../invites/invite-shared';
import {
  ROLES_ALLOWED_TO_DECIDE_BACKORDER,
  ensureRequesterMayActOnBackorder,
  mapReturnRequestOrder,
  normalizeTeamIds,
  requireBoundedString,
} from './backorder-shared';
import type { ReturnRequestOrder } from '../returns/return-shared';

const MAX_NOTE_LENGTH = 500;

export interface DecideBackorderApprovalRequest extends RequestWithMeta {
  organizationId?: string;
  backorderId?: string;
  approve?: boolean;
  note?: string;
}

export interface DecideBackorderApprovalResponse {
  correlationId: string;
  backorderId: string;
  status: 'queued' | 'rejected';
}

/**
 * Decides (aprova/recusa) a `BackorderRequest` parked at `awaiting_approval`
 * for exceeding the organization's own auto-approve threshold (TASK-215,
 * EPIC-32, `createBackorderRequest`'s own `resolveAutoApproveMaxQuantity`).
 * Approving only ever moves the request to `queued` — the exact same status
 * an auto-approved request starts at — never straight to `ready_to_fulfill`
 * (that only ever happens once `notifyBackordersOnStockAvailable` confirms
 * real stock, TASK-215: "Toda promessa exibida deve diferenciar previsão,
 * reserva aprovada e disponibilidade confirmada").
 */
export const decideBackorderApproval = onCall<
  DecideBackorderApprovalRequest,
  Promise<DecideBackorderApprovalResponse>
>(async (request) => {
  const startedAt = Date.now();
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'É necessário estar autenticado para decidir um backorder.');
  }
  const uid = request.auth.uid;

  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const backorderId = requireNonEmptyString(request.data?.backorderId, 'backorderId');
  const approve = request.data?.approve === true;
  const note = request.data?.note === undefined
    ? undefined
    : requireBoundedString(request.data?.note, 'note', MAX_NOTE_LENGTH);

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  if (!ROLES_ALLOWED_TO_DECIDE_BACKORDER.has(membership.roleName)) {
    throw new HttpsError('permission-denied', 'Seu perfil não pode decidir backorders.');
  }

  const actorName = await resolveActorName(db, uid, request.auth.token);
  const organizationRef = db.collection('organizations').doc(organizationId);
  const backorderRef = organizationRef.collection('backorders').doc(backorderId);

  let requesterTeamIds: string[] = [];
  if (membership.roleName === 'SALES_MANAGER') {
    const requesterMemberSnapshot = await organizationRef.collection('members').doc(uid).get();
    requesterTeamIds = normalizeTeamIds(requesterMemberSnapshot.data()?.teamIds);
  }

  const result = await db.runTransaction<DecideBackorderApprovalResponse>(async (transaction) => {
    const snapshot = await transaction.get(backorderRef);
    const backorder = snapshot.data();
    if (!snapshot.exists || !backorder) {
      throw new HttpsError('not-found', 'Backorder não encontrado.');
    }
    if (backorder.organizationId !== organizationId) {
      throw new HttpsError('failed-precondition', 'Backorder não pertence à organização informada.');
    }
    if (backorder.status !== 'awaiting_approval') {
      throw new HttpsError(
        'failed-precondition',
        'Somente backorders aguardando aprovação podem ser decididos.',
      );
    }

    let relatedOrder: ReturnRequestOrder | undefined;
    if (backorder.relatedOrderId) {
      const orderSnapshot = await transaction.get(organizationRef.collection('orders').doc(backorder.relatedOrderId));
      if (orderSnapshot.exists) {
        relatedOrder = mapReturnRequestOrder(backorder.relatedOrderId, orderSnapshot.data());
      }
    }

    await ensureRequesterMayActOnBackorder(transaction, organizationRef, {
      roleName: membership.roleName,
      uid,
      sellerId: backorder.sellerId as string,
      customerId: backorder.customerId as string,
      requesterTeamIds,
      relatedOrder,
    });

    const now = Timestamp.now();
    const newStatus = approve ? 'queued' : 'rejected';
    const update: DocumentData = {
      status: newStatus,
      resolutionNote: note ?? null,
      updatedAt: now,
      updatedBy: uid,
      version: (typeof backorder.version === 'number' ? backorder.version : 1) + 1,
    };
    transaction.set(backorderRef, update, { merge: true });

    transaction.set(organizationRef.collection('notifications').doc(), {
      organizationId,
      userId: backorder.sellerId,
      category: 'commercial',
      title: approve ? 'Backorder aprovado' : 'Backorder recusado',
      body: approve
        ? 'Sua solicitação de estoque futuro foi aprovada e entrou na fila de atendimento.'
        : `Sua solicitação de estoque futuro foi recusada.${note ? ` Motivo: ${note}` : ''}`,
      deepLink: `/org/${organizationId}/backorders/${backorderId}`,
      metadata: { backorderId, status: newStatus },
      readAt: null,
      deliverAt: now,
      createdAt: now,
      createdBy: uid,
    });

    transaction.set(organizationRef.collection('auditLogs').doc(), {
      organizationId,
      actorUserId: uid,
      actorName,
      action: approve ? 'backorder.approved' : 'backorder.rejected',
      entityType: 'backorder',
      entityId: backorderId,
      previousValue: { status: 'awaiting_approval' },
      newValue: { status: newStatus, note: note ?? null },
      timestamp: now,
    });

    return { correlationId, backorderId, status: newStatus };
  });

  logger.info('decideBackorderApproval succeeded', {
    correlationId,
    organizationId,
    backorderId,
    approve,
    uid,
    durationMs: Date.now() - startedAt,
  });

  return result;
});
