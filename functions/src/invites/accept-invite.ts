import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';
import { getFirestore, Timestamp, type DocumentData } from 'firebase-admin/firestore';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import {
  findInviteByTokenHash,
  hashInviteToken,
  requireNonEmptyString,
  resolveActorName,
  resolveInviteOutcome,
} from './invite-shared';

export interface AcceptInviteRequest extends RequestWithMeta {
  token?: string;
}

export interface AcceptInviteResponse {
  organizationId: string;
  organizationName: string;
  roleName: string;
  correlationId: string;
}

/**
 * The clear, user-facing-mappable message for each non-`'valid'`
 * {@link resolveInviteOutcome} result — `AcceptInvitePage` is expected to
 * have already shown the equivalent message from `validateInvite`'s own
 * `outcome` *before* ever calling this Function, so reaching one of these
 * here only happens on a genuine race (e.g. the invite was accepted or
 * revoked by someone else, or it expired, in the gap between validating
 * and confirming) — still surfaced as `failed-precondition` with a precise
 * message, never a raw "something went wrong".
 */
const OUTCOME_MESSAGES: Readonly<Record<'expired' | 'accepted' | 'revoked', string>> = {
  expired: 'Este convite expirou.',
  accepted: 'Este convite já foi utilizado.',
  revoked: 'Este convite foi revogado.',
};

/**
 * Accepts the `Invite` behind [AcceptInviteRequest.token]: creates/overwrites
 * the caller's `organizations/{organizationId}/members/{uid}` Membership
 * with exactly the invite's `roleName` (never one the caller chooses,
 * TASK-040: "a role atribuída ao aceitar é exatamente a definida no
 * convite") and marks the `Invite` `'accepted'` — transactionally, so a
 * concurrent second accept of the same token (two tabs, a retried request)
 * can never both succeed nor leave a half-applied state (same "read
 * everything inside the transaction" rationale as `createOrganization`,
 * `functions/src/organizations/create-organization.ts`).
 *
 * Requires authentication: either a brand-new Firebase Auth account just
 * created by `AcceptInvitePage`'s embedded `SignUpForm` (e-mail locked to
 * the invite's), or an already signed-in user confirming the invite is
 * theirs.
 *
 * **E-mail divergence rule (TASK-040, decided and documented here):** the
 * caller's authenticated e-mail (`request.auth.token.email`) must match
 * `Invite.email` (case-insensitively) or this call is rejected with
 * `permission-denied` — accepting a colleague's invite with a different
 * account is never allowed, even though the token itself is the only
 * secret involved. `AcceptInvitePage` re-implements the same comparison
 * client-side (from `validateInvite`'s response) purely for UX — to steer
 * an already-signed-in, wrong-account user towards signing out *before*
 * ever calling this Function — but this server-side check is the only one
 * that actually matters, per `AGENTS.md`'s "nunca confiar apenas no
 * organizationId/role vindo do cliente".
 */
export const acceptInvite = onCall<
  AcceptInviteRequest,
  Promise<AcceptInviteResponse>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'É necessário estar autenticado para aceitar um convite.',
    );
  }
  const uid = request.auth.uid;
  const callerEmail = (request.auth.token?.email as string | undefined)?.toLowerCase();

  const token = requireNonEmptyString(request.data?.token, 'token');
  const tokenHash = hashInviteToken(token);

  const db = getFirestore();

  const result = await db.runTransaction(async (transaction) => {
    const lookup = await findInviteByTokenHash(db, tokenHash, transaction);
    if (!lookup) {
      throw new HttpsError('not-found', 'Convite não encontrado.');
    }

    const now = Timestamp.now();
    const outcome = resolveInviteOutcome(lookup.data, now);
    if (outcome !== 'valid') {
      throw new HttpsError('failed-precondition', OUTCOME_MESSAGES[outcome]);
    }

    const inviteEmail = (lookup.data.email as string).toLowerCase();
    if (!callerEmail || callerEmail !== inviteEmail) {
      throw new HttpsError(
        'permission-denied',
        'Este convite foi emitido para outro e-mail.',
      );
    }

    const organizationSnapshot = await transaction.get(lookup.organizationRef);
    if (!organizationSnapshot.exists) {
      // Should be impossible: an Invite only ever exists nested under a
      // real Organization. Failing loudly is safer than silently accepting
      // into nothing.
      throw new HttpsError(
        'internal',
        'Invite references a missing organization.',
      );
    }
    const organizationId = lookup.organizationRef.id;
    const roleName = lookup.data.roleName as string;
    const actorName = await resolveActorName(db, uid, request.auth?.token);

    const membershipRef = lookup.organizationRef.collection('members').doc(uid);
    const previousMembershipSnapshot = await transaction.get(membershipRef);

    // Unlike `revokeInvite`, `tokenHash` is deliberately *not* cleared here:
    // `status: 'accepted'` already makes `resolveInviteOutcome` reject any
    // further use of the same token with a precise `'accepted'` message
    // (`OUTCOME_MESSAGES`) — nulling it too would only turn a retried
    // accept into an indistinguishable `not-found`, a strictly worse
    // message for no extra security (a consumed token granting nothing
    // further is already guaranteed by the status check alone).
    transaction.update(lookup.ref, {
      status: 'accepted',
      updatedAt: now,
      updatedBy: uid,
    });

    const membershipData: DocumentData = {
      organizationId,
      userId: uid,
      roleId: roleName,
      roleName,
      // Denormalized display fields (TASK-042: `UserListPage` needs a name/
      // e-mail per row without the client ever reading another user's
      // `users/{uid}` profile — `firestore.rules` denies that). A snapshot
      // taken at Membership-creation/re-creation time, same trade-off
      // documented in `create-organization.ts`'s own Membership write.
      name: actorName,
      email: callerEmail,
      teamIds: previousMembershipSnapshot.exists
        ? (previousMembershipSnapshot.data()?.teamIds ?? [])
        : [],
      status: 'active',
      version: previousMembershipSnapshot.exists
        ? ((previousMembershipSnapshot.data()?.version as number | undefined) ?? 0) + 1
        : 1,
      createdAt: previousMembershipSnapshot.exists
        ? (previousMembershipSnapshot.data()?.createdAt ?? now)
        : now,
      createdBy: previousMembershipSnapshot.exists
        ? (previousMembershipSnapshot.data()?.createdBy ?? uid)
        : uid,
      updatedAt: now,
      updatedBy: uid,
      deletedAt: null,
    };
    transaction.set(membershipRef, membershipData);

    transaction.set(lookup.organizationRef.collection('auditLogs').doc(), {
      organizationId,
      actorUserId: uid,
      actorName,
      action: 'user.inviteAccepted',
      entityType: 'invite',
      entityId: lookup.ref.id,
      previousValue: { status: lookup.data.status },
      newValue: { status: 'accepted', roleName },
      timestamp: now,
    });

    return {
      organizationId,
      organizationName: organizationSnapshot.data()?.name as string,
      roleName,
    };
  });

  logger.info('acceptInvite succeeded', {
    correlationId,
    uid,
    organizationId: result.organizationId,
  });

  return { ...result, correlationId };
});
