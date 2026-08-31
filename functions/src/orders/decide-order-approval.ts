import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import {
  FieldValue,
  Timestamp,
  getFirestore,
  type DocumentData,
} from 'firebase-admin/firestore';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import {
  loadActiveMembership,
  requireNonEmptyString,
  resolveActorName,
} from '../invites/invite-shared';
import { optionalString } from '../pricing/calculate-pricing';

/**
 * Only these roles may ever decide a pedido's approval (TASK-103) — mirrors
 * exactly `Capability.orderApprove`'s grant list in
 * `lib/core/permissions/role_permission_matrix.dart` (OWNER/ADMIN/
 * SALES_MANAGER; SALES_REP and every other role never get it). Re-checked
 * here from the caller's real Membership — never trusted from the client,
 * same rule `submitOrder`'s own `ROLES_ALLOWED_TO_SUBMIT_ORDER` follows.
 */
const ROLES_ALLOWED_TO_DECIDE_ORDER_APPROVAL: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
  'SALES_MANAGER',
]);

const DECIDABLE_STATUSES: ReadonlySet<string> = new Set<string>(['approved', 'rejected']);

export type OrderApprovalDecisionValue = 'approved' | 'rejected';

export interface DecideOrderApprovalRequest extends RequestWithMeta {
  organizationId?: string;
  companyId?: string;
  orderId?: string;
  decision?: OrderApprovalDecisionValue;
  reason?: string;
}

export interface DecideOrderApprovalResponse {
  correlationId: string;
  orderId: string;
  status: OrderApprovalDecisionValue;
  approverId: string;
  decidedAt: string;
  reason: string | null;
}

/**
 * Idempotent Cloud Function deciding a pedido already routed to
 * `underReview` (EPIC-13, TASK-103, `submitOrder`'s own approval routing) —
 * the one and only place `Order.status` may ever transition out of
 * `underReview` into `approved`/`rejected`, with the exact same
 * `OrderStatusTransitionValidator` matrix
 * (`lib/features/orders/domain/services/order_status_transition_validator.dart`)
 * enforced here server-side, never trusting a client-computed transition.
 *
 * A rejection always requires a non-empty [DecideOrderApprovalRequest.reason]
 * (`tasks.md`'s own "pedido rejeitado retorna ao vendedor com o motivo") — an
 * approval's reason is optional context, never mandatory.
 *
 * A `SALES_MANAGER` may only decide orders whose seller shares at least one
 * of their own teams (`membership.teamIds`) — the exact same scope
 * `firestore.rules`' `managerCanReadOrder` already restricts read access to,
 * so a manager can never approve/reject a pedido they are not even allowed
 * to see. `OWNER`/`ADMIN` decide any order in the organization/company.
 *
 * A retried call for an order already resolved to the very same [decision]
 * short-circuits to that already-persisted result instead of writing again
 * (double tap/network retry safe, same idempotency precedent `submitOrder`
 * already sets) — deciding it differently a second time (e.g. approve then
 * reject) is rejected instead: once decided, only a brand-new pedido cycle
 * (a fresh submission) can change the outcome, never the same document.
 */
export const decideOrderApproval = onCall<
  DecideOrderApprovalRequest,
  Promise<DecideOrderApprovalResponse>
>(async (request) => {
  const startedAt = Date.now();
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'É necessário estar autenticado para decidir a aprovação de um pedido.',
    );
  }
  const uid = request.auth.uid;

  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const companyId = requireNonEmptyString(request.data?.companyId, 'companyId');
  const orderId = requireNonEmptyString(request.data?.orderId, 'orderId');
  const decision = requireDecision(request.data?.decision);
  const reason = optionalString(request.data?.reason);
  if (decision === 'rejected' && !reason) {
    throw new HttpsError(
      'invalid-argument',
      'É necessário informar o motivo da rejeição.',
    );
  }

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  if (!ROLES_ALLOWED_TO_DECIDE_ORDER_APPROVAL.has(membership.roleName)) {
    throw new HttpsError(
      'permission-denied',
      'Seu perfil não pode aprovar ou rejeitar pedidos.',
    );
  }

  const actorName = await resolveActorName(db, uid, request.auth.token);
  const organizationRef = db.collection('organizations').doc(organizationId);
  const orderRef = organizationRef.collection('orders').doc(orderId);

  let requesterTeamIds: string[] = [];
  if (membership.roleName === 'SALES_MANAGER') {
    const requesterMemberSnapshot = await organizationRef.collection('members').doc(uid).get();
    requesterTeamIds = normalizeTeamIds(requesterMemberSnapshot.data()?.teamIds);
  }

  const result = await db.runTransaction<DecideOrderApprovalResponse>(async (transaction) => {
    const orderSnapshot = await transaction.get(orderRef);
    const order = orderSnapshot.data();
    if (!orderSnapshot.exists || !order) {
      throw new HttpsError('failed-precondition', 'Pedido não encontrado.');
    }
    if (order.organizationId !== organizationId || order.companyId !== companyId) {
      throw new HttpsError(
        'failed-precondition',
        'Pedido não pertence à organização/empresa informada.',
      );
    }

    if (membership.roleName === 'SALES_MANAGER') {
      const sellerId = order.sellerId as string;
      const sellerSnapshot = await transaction.get(
        organizationRef.collection('members').doc(sellerId),
      );
      const sellerTeamIds = normalizeTeamIds(sellerSnapshot.data()?.teamIds);
      const sharesTeam = sellerTeamIds.some((teamId) => requesterTeamIds.includes(teamId));
      if (!sharesTeam) {
        throw new HttpsError(
          'permission-denied',
          'Você só pode decidir pedidos da sua própria equipe.',
        );
      }
    }

    // Retry/double-tap of the very same decision — never re-writes, just
    // replays what is already persisted (same precedent `submitOrder`'s own
    // double-submit branch sets).
    if (order.status === decision) {
      return serializeDecision(orderId, order, correlationId);
    }

    if (order.status !== 'under_review') {
      throw new HttpsError(
        'failed-precondition',
        'Este pedido não está aguardando aprovação.',
      );
    }

    const now = Timestamp.now();
    const historyEntry = {
      previousStatus: order.status,
      newStatus: decision,
      changedAt: now,
      actorId: uid,
      reason: reason ?? null,
    };
    const updates: DocumentData = {
      status: decision,
      statusHistory: FieldValue.arrayUnion(historyEntry),
      updatedAt: now,
      updatedBy: uid,
      version: FieldValue.increment(1),
    };
    if (decision === 'approved') {
      updates.approvedBy = uid;
      updates.approvedAt = now;
      updates.rejectionReason = null;
    } else {
      updates.approvedBy = null;
      updates.approvedAt = null;
      updates.rejectionReason = reason;
    }
    transaction.update(orderRef, updates);

    transaction.set(organizationRef.collection('auditLogs').doc(), {
      organizationId,
      actorUserId: uid,
      actorName,
      action: decision === 'approved' ? 'order.approved' : 'order.rejected',
      entityType: 'order',
      entityId: orderId,
      previousValue: { status: order.status },
      newValue: { status: decision, reason: reason ?? null },
      timestamp: now,
    });

    return {
      correlationId,
      orderId,
      status: decision,
      approverId: uid,
      decidedAt: now.toDate().toISOString(),
      reason: reason ?? null,
    };
  });

  logger.info('decideOrderApproval succeeded', {
    correlationId,
    organizationId,
    companyId,
    orderId,
    decision,
    uid,
    durationMs: Date.now() - startedAt,
  });

  return result;
});

function requireDecision(value: unknown): OrderApprovalDecisionValue {
  if (typeof value !== 'string' || !DECIDABLE_STATUSES.has(value)) {
    throw new HttpsError(
      'invalid-argument',
      'decision must be either "approved" or "rejected".',
    );
  }
  return value as OrderApprovalDecisionValue;
}

function normalizeTeamIds(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.filter((entry): entry is string => typeof entry === 'string');
}

function serializeDecision(
  orderId: string,
  data: DocumentData,
  correlationId: string,
): DecideOrderApprovalResponse {
  const status = data.status as string;
  if (status !== 'approved' && status !== 'rejected') {
    throw new HttpsError('internal', 'Invalid order record for a decided order.');
  }
  // The decision's own audit trail always lives in `statusHistory` (`actorId`/
  // `changedAt`/`reason` of the entry that produced this exact status) —
  // read from there instead of `approvedBy`/`approvedAt`/`rejectionReason`
  // alone so a replayed `rejected` decision (which has no top-level
  // "who rejected" field, only `rejectionReason`) resolves just as
  // completely as a replayed `approved` one.
  const history = Array.isArray(data.statusHistory)
    ? (data.statusHistory as DocumentData[])
    : [];
  const matchingEntry = [...history].reverse().find((entry) => entry.newStatus === status);
  const updatedAt = data.updatedAt as Timestamp;
  const decidedAt = (matchingEntry?.changedAt as Timestamp | undefined) ?? updatedAt;
  const approverId =
    (matchingEntry?.actorId as string | undefined) ?? (data.approvedBy as string | null) ?? '';
  const reason =
    (matchingEntry?.reason as string | null | undefined) ??
    (data.rejectionReason as string | null) ??
    null;

  return {
    correlationId,
    orderId,
    status,
    approverId,
    decidedAt: decidedAt.toDate().toISOString(),
    reason,
  };
}
