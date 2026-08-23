import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import {
  loadActiveMembership,
  requireNonEmptyString,
  resolveActorName,
  serializeInvite,
  ROLES_ALLOWED_TO_INVITE,
  type InviteResponse,
} from './invite-shared';

export interface RevokeInviteRequest extends RequestWithMeta {
  organizationId?: string;
  inviteId?: string;
}

export interface RevokeInviteResponse {
  invite: InviteResponse;
  correlationId: string;
}

/**
 * Revokes [RevokeInviteRequest.inviteId]: marks it `revoked` and clears
 * `tokenHash` (set to `null`) so the previously issued token can never be
 * used to accept it, even as defense-in-depth on top of the status check
 * TASK-040's `acceptInvite` is expected to perform (TASK-039: "revogar
 * (marca como `revoked`, invalidando o token)").
 *
 * Only a `pending` invite may be revoked — an already `accepted`/`revoked`/
 * `expired` one is rejected with `failed-precondition` instead of silently
 * no-op'ing, so the caller gets a clear signal instead of a false sense of
 * having "just revoked" something that was already settled.
 */
export const revokeInvite = onCall<
  RevokeInviteRequest,
  Promise<RevokeInviteResponse>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'É necessário estar autenticado para revogar convites.',
    );
  }
  const uid = request.auth.uid;

  const organizationId = requireNonEmptyString(
    request.data?.organizationId,
    'organizationId',
  );
  const inviteId = requireNonEmptyString(request.data?.inviteId, 'inviteId');

  const db = getFirestore();
  const organizationRef = db.collection('organizations').doc(organizationId);
  const inviteRef = organizationRef.collection('invites').doc(inviteId);

  const membership = await loadActiveMembership(db, organizationId, uid);
  if (!ROLES_ALLOWED_TO_INVITE.has(membership.roleName)) {
    throw new HttpsError(
      'permission-denied',
      'Apenas OWNER/ADMIN podem revogar convites.',
    );
  }

  const inviteSnapshot = await inviteRef.get();
  const inviteData = inviteSnapshot.data();
  if (
    !inviteSnapshot.exists ||
    !inviteData ||
    inviteData.organizationId !== organizationId
  ) {
    throw new HttpsError('not-found', 'Invite not found.');
  }
  if (inviteData.status !== 'pending') {
    throw new HttpsError(
      'failed-precondition',
      'Somente um convite pendente pode ser revogado.',
    );
  }

  const actorName = await resolveActorName(db, uid, request.auth.token);
  const now = Timestamp.now();
  const updatedFields = {
    status: 'revoked',
    tokenHash: null,
    updatedAt: now,
    updatedBy: uid,
  };

  await db.runTransaction(async (transaction) => {
    transaction.update(inviteRef, updatedFields);
    transaction.set(organizationRef.collection('auditLogs').doc(), {
      organizationId,
      actorUserId: uid,
      actorName,
      action: 'user.inviteRevoked',
      entityType: 'invite',
      entityId: inviteId,
      previousValue: { status: 'pending' },
      newValue: { status: 'revoked' },
      timestamp: now,
    });
  });

  logger.info('revokeInvite succeeded', {
    correlationId,
    uid,
    organizationId,
    inviteId,
  });

  return {
    invite: serializeInvite(inviteId, { ...inviteData, ...updatedFields }),
    correlationId,
  };
});
