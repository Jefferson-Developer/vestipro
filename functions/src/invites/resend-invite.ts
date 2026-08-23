import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import {
  assertCanIssueInvite,
  generateInviteToken,
  loadActiveMembership,
  requireNonEmptyString,
  resolveActorName,
  resolveInviteExpiration,
  serializeInvite,
  type InviteResponse,
} from './invite-shared';

export interface ResendInviteRequest extends RequestWithMeta {
  organizationId?: string;
  inviteId?: string;
}

export interface ResendInviteResponse {
  invite: InviteResponse;
  /** Same one-time-return contract as `CreateInviteResponse.token`. */
  token: string;
  correlationId: string;
}

/** Only a `pending` or already-`expired` invite may be resent — an
 * `accepted`/`revoked` one never can (TASK-039: "nunca aceitar novamente
 * nem duplicar o vínculo" applies just as much to resending as to
 * accepting). */
const RESENDABLE_STATUSES: ReadonlySet<string> = new Set([
  'pending',
  'expired',
]);

/**
 * Reissues [ResendInviteRequest.inviteId]: generates a brand-new token/hash
 * (invalidating whatever token was generated before — only the current
 * `tokenHash` is ever accepted) and a fresh `expiresAt`, on the *same*
 * `Invite` document (no new doc, no id churn) — matches TASK-039's
 * "reenviar (gera novo token, invalida o anterior)".
 *
 * Re-validates OWNER/ADMIN + role-hierarchy exactly like `createInvite`
 * (`assertCanIssueInvite`), against the invite's already-recorded
 * `roleName` — so a caller whose own role was downgraded after the invite
 * was first created can no longer resend one they would not be allowed to
 * create today.
 */
export const resendInvite = onCall<
  ResendInviteRequest,
  Promise<ResendInviteResponse>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'É necessário estar autenticado para reenviar convites.',
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

  const inviteSnapshot = await inviteRef.get();
  const inviteData = inviteSnapshot.data();
  if (
    !inviteSnapshot.exists ||
    !inviteData ||
    inviteData.organizationId !== organizationId
  ) {
    throw new HttpsError('not-found', 'Invite not found.');
  }
  if (!RESENDABLE_STATUSES.has(inviteData.status as string)) {
    throw new HttpsError(
      'failed-precondition',
      'Somente um convite pendente ou expirado pode ser reenviado.',
    );
  }

  assertCanIssueInvite(membership.roleName, inviteData.roleName as string);

  const organizationSnapshot = await organizationRef.get();
  const actorName = await resolveActorName(db, uid, request.auth.token);
  const { token, tokenHash } = generateInviteToken();
  const now = Timestamp.now();
  const expiresAt = resolveInviteExpiration(organizationSnapshot.data(), now);

  const updatedFields = {
    status: 'pending',
    tokenHash,
    expiresAt,
    updatedAt: now,
    updatedBy: uid,
  };

  await db.runTransaction(async (transaction) => {
    transaction.update(inviteRef, updatedFields);
    transaction.set(organizationRef.collection('auditLogs').doc(), {
      organizationId,
      actorUserId: uid,
      actorName,
      action: 'user.inviteResent',
      entityType: 'invite',
      entityId: inviteId,
      previousValue: { status: inviteData.status },
      newValue: { status: 'pending' },
      timestamp: now,
    });
  });

  logger.info('resendInvite succeeded', {
    correlationId,
    uid,
    organizationId,
    inviteId,
  });

  return {
    invite: serializeInvite(inviteId, { ...inviteData, ...updatedFields }),
    token,
    correlationId,
  };
});
