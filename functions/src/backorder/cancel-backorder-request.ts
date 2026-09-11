import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { Timestamp, getFirestore, type DocumentData } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { loadActiveMembership, requireNonEmptyString, resolveActorName } from '../invites/invite-shared';
import {
  OPEN_BACKORDER_STATUSES,
  ROLES_ALLOWED_TO_REQUEST_BACKORDER,
  ensureRequesterMayActOnBackorder,
  mapReturnRequestOrder,
  normalizeTeamIds,
  optionalString,
  requireBoundedString,
  type BackorderStatus,
} from './backorder-shared';
import type { ReturnRequestOrder } from '../returns/return-shared';

const MAX_REASON_LENGTH = 500;

export interface CancelBackorderRequestRequest extends RequestWithMeta {
  organizationId?: string;
  backorderId?: string;
  reason?: string;
}

export interface CancelBackorderRequestResponse {
  correlationId: string;
  backorderId: string;
  status: 'cancelled';
}

/**
 * Cancels a still-open `BackorderRequest` (TASK-215, EPIC-32) — never
 * reaches a converted/rejected one (both already terminal). Since a
 * backorder never moved/reserved stock in the first place
 * (`createBackorderRequest`), cancelling one has no inventory side effect to
 * undo — it only ever stops the request from being considered by
 * `notifyBackordersOnStockAvailable`/the atendimento queue going forward.
 */
export const cancelBackorderRequest = onCall<
  CancelBackorderRequestRequest,
  Promise<CancelBackorderRequestResponse>
>(async (request) => {
  const startedAt = Date.now();
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'É necessário estar autenticado para cancelar um backorder.');
  }
  const uid = request.auth.uid;

  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const backorderId = requireNonEmptyString(request.data?.backorderId, 'backorderId');
  const reason = request.data?.reason === undefined
    ? undefined
    : requireBoundedString(request.data?.reason, 'reason', MAX_REASON_LENGTH);

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  if (!ROLES_ALLOWED_TO_REQUEST_BACKORDER.has(membership.roleName)) {
    throw new HttpsError('permission-denied', 'Seu perfil não pode cancelar backorders.');
  }

  const actorName = await resolveActorName(db, uid, request.auth.token);
  const organizationRef = db.collection('organizations').doc(organizationId);
  const backorderRef = organizationRef.collection('backorders').doc(backorderId);

  let requesterTeamIds: string[] = [];
  if (membership.roleName === 'SALES_MANAGER') {
    const requesterMemberSnapshot = await organizationRef.collection('members').doc(uid).get();
    requesterTeamIds = normalizeTeamIds(requesterMemberSnapshot.data()?.teamIds);
  }

  let portalCustomerId: string | undefined;
  if (membership.roleName === 'CUSTOMER_PORTAL') {
    const portalMemberSnapshot = await organizationRef.collection('members').doc(uid).get();
    portalCustomerId = optionalString(portalMemberSnapshot.data()?.customerId);
  }

  const result = await db.runTransaction<CancelBackorderRequestResponse>(async (transaction) => {
    const snapshot = await transaction.get(backorderRef);
    const backorder = snapshot.data();
    if (!snapshot.exists || !backorder) {
      throw new HttpsError('not-found', 'Backorder não encontrado.');
    }
    if (backorder.organizationId !== organizationId) {
      throw new HttpsError('failed-precondition', 'Backorder não pertence à organização informada.');
    }
    if (!OPEN_BACKORDER_STATUSES.has(backorder.status as BackorderStatus)) {
      throw new HttpsError(
        'failed-precondition',
        'Este backorder não está mais aberto para cancelamento.',
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
      portalCustomerId,
      requesterTeamIds,
      relatedOrder,
    });

    const now = Timestamp.now();
    const update: DocumentData = {
      status: 'cancelled',
      resolutionNote: reason ?? null,
      updatedAt: now,
      updatedBy: uid,
      version: (typeof backorder.version === 'number' ? backorder.version : 1) + 1,
    };
    transaction.set(backorderRef, update, { merge: true });

    transaction.set(organizationRef.collection('auditLogs').doc(), {
      organizationId,
      actorUserId: uid,
      actorName,
      action: 'backorder.cancelled',
      entityType: 'backorder',
      entityId: backorderId,
      previousValue: { status: backorder.status },
      newValue: { status: 'cancelled', reason: reason ?? null },
      timestamp: now,
    });

    return { correlationId, backorderId, status: 'cancelled' };
  });

  logger.info('cancelBackorderRequest succeeded', {
    correlationId,
    organizationId,
    backorderId,
    uid,
    durationMs: Date.now() - startedAt,
  });

  return result;
});
