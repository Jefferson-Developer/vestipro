import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { loadActiveMembership, requireNonEmptyString, resolveActorName } from '../invites/invite-shared';
import { appendPostSaleEvent } from '../after_sales/after-sales-shared';
import {
  ROLES_ALLOWED_TO_MANAGE_SHIPMENT,
  ensureRequesterMayActOnOrder,
  mapReturnRequestOrder,
  normalizeTeamIds,
  requireOptionalBoundedString,
} from './fulfillment-shared';

const MAX_NOTE_LENGTH = 1000;

export interface ResolveLogisticsIssueRequest extends RequestWithMeta {
  organizationId?: string;
  shipmentId?: string;
  logisticsIssueId?: string;
  status?: 'in_progress' | 'resolved';
  resolutionNote?: string;
}

export interface ResolveLogisticsIssueResponse {
  correlationId: string;
  logisticsIssueId: string;
  status: 'in_progress' | 'resolved';
}

/**
 * Advances a `LogisticsIssue` to `in_progress`/`resolved` (TASK-214,
 * EPIC-32) — never deletes it (occorrência history is always kept, same
 * "não é editado, apenas complementado" precedent `postSaleEvents` already
 * establishes for the timeline it also appends to). Recomputes
 * `Shipment.hasOpenIssue` from the real remaining ledger of open ocorrências
 * every time (never an isolated boolean flip), so a shipment with more than
 * one open ocorrência only clears the flag once every one of them is
 * resolved.
 */
export const resolveLogisticsIssue = onCall<
  ResolveLogisticsIssueRequest,
  Promise<ResolveLogisticsIssueResponse>
>(async (request) => {
  const startedAt = Date.now();
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'É necessário estar autenticado para resolver uma ocorrência.');
  }
  const uid = request.auth.uid;

  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const shipmentId = requireNonEmptyString(request.data?.shipmentId, 'shipmentId');
  const logisticsIssueId = requireNonEmptyString(request.data?.logisticsIssueId, 'logisticsIssueId');
  const status = request.data?.status;
  if (status !== 'in_progress' && status !== 'resolved') {
    throw new HttpsError('invalid-argument', 'status deve ser "in_progress" ou "resolved".');
  }
  const resolutionNote = requireOptionalBoundedString(
    request.data?.resolutionNote,
    'resolutionNote',
    MAX_NOTE_LENGTH,
  );

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  if (!ROLES_ALLOWED_TO_MANAGE_SHIPMENT.has(membership.roleName)) {
    throw new HttpsError('permission-denied', 'Seu perfil não pode resolver ocorrências logísticas.');
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

  await db.runTransaction(async (transaction) => {
    const issueSnapshot = await transaction.get(issueRef);
    if (!issueSnapshot.exists) {
      throw new HttpsError('failed-precondition', 'Ocorrência não encontrada.');
    }
    const issue = issueSnapshot.data();
    if (!issue || issue.organizationId !== organizationId || issue.shipmentId !== shipmentId) {
      throw new HttpsError('failed-precondition', 'Ocorrência não pertence a esta expedição.');
    }
    if (issue.status === 'resolved') return;

    const orderRef = organizationRef.collection('orders').doc(issue.orderId as string);
    const orderSnapshot = await transaction.get(orderRef);
    if (!orderSnapshot.exists) {
      throw new HttpsError('failed-precondition', 'Pedido vinculado à ocorrência não encontrado.');
    }
    const order = mapReturnRequestOrder(orderRef.id, orderSnapshot.data());

    await ensureRequesterMayActOnOrder(transaction, organizationRef, {
      roleName: membership.roleName,
      uid,
      order,
      requesterTeamIds,
    });

    const otherOpenIssuesSnapshot = await transaction.get(
      organizationRef
        .collection('logisticsIssues')
        .where('shipmentId', '==', shipmentId)
        .where('status', 'in', ['open', 'in_progress']),
    );
    const willStillHaveOpenIssues = otherOpenIssuesSnapshot.docs.some(
      (doc) => doc.id !== logisticsIssueId && doc.data().status !== 'resolved',
    );

    const now = Timestamp.now();
    transaction.set(
      issueRef,
      {
        status,
        resolutionNote: resolutionNote ?? null,
        resolvedAt: status === 'resolved' ? now : null,
        resolvedBy: status === 'resolved' ? uid : null,
      },
      { merge: true },
    );

    if (status === 'resolved' && !willStillHaveOpenIssues) {
      transaction.set(
        shipmentRef,
        { hasOpenIssue: false, updatedAt: now, updatedBy: uid, version: FieldValue.increment(1) },
        { merge: true },
      );
    }

    if (status === 'resolved') {
      appendPostSaleEvent(transaction, organizationRef, {
        eventRef: organizationRef.collection('postSaleEvents').doc(),
        organizationId,
        companyId: issue.companyId as string,
        orderId: issue.orderId as string,
        orderNumber: (issue.orderNumber as string | null) ?? null,
        customerId: issue.customerId as string,
        sellerId: issue.sellerId as string,
        type: 'resolved',
        description: resolutionNote ?? 'Ocorrência de expedição resolvida.',
        source: 'system',
        sourceRequestId: logisticsIssueId,
        createdBy: uid,
        createdByName: actorName,
        now,
      });
    }
  });

  logger.info('resolveLogisticsIssue succeeded', {
    correlationId,
    organizationId,
    shipmentId,
    logisticsIssueId,
    status,
    uid,
    durationMs: Date.now() - startedAt,
  });

  return { correlationId, logisticsIssueId, status };
});
