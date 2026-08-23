import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';
import { getFirestore, Timestamp, type DocumentData } from 'firebase-admin/firestore';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import {
  assertCanIssueInvite,
  generateInviteToken,
  loadActiveMembership,
  requireNonEmptyString,
  requireValidEmail,
  resolveActorName,
  resolveInviteExpiration,
  serializeInvite,
  type InviteResponse,
} from './invite-shared';

export interface CreateInviteRequest extends RequestWithMeta {
  organizationId?: string;
  email?: string;
  roleName?: string;
  message?: string;
}

export interface CreateInviteResponse {
  invite: InviteResponse;
  /**
   * The plaintext invite token, returned exactly once. `InviteListPage`
   * never receives this again on a subsequent read — building the
   * shareable invite link/e-mail with it is the caller's responsibility
   * right after this call succeeds.
   */
  token: string;
  correlationId: string;
}

/**
 * Creates a pending `Invite` for [CreateInviteRequest.email] to join
 * [CreateInviteRequest.organizationId] with [CreateInviteRequest.roleName]
 * (TASK-039, `tasks.md` seção 3.1/EPIC-04). OWNER/ADMIN only — re-validated
 * here from the caller's real Membership, never from anything the client
 * claims (`assertCanIssueInvite`).
 *
 * Generates a cryptographically secure token
 * (`generateInviteToken`) and persists only its SHA-256 hash
 * (`Invite.tokenHash`); the plaintext token is returned in this response
 * only, never written to Firestore, so no OWNER/ADMIN reading the pending
 * invites list can recover a token they were not the one to generate.
 *
 * The `Invite` document and its `organization.created`-style audit log
 * entry (`user.invited`) are written together in one Firestore transaction,
 * same pattern as `createOrganization`
 * (`functions/src/organizations/create-organization.ts`).
 *
 * E-mail delivery: unlike `createOrganization`, this Function does not send
 * anything itself — there is no transactional e-mail provider (SendGrid,
 * Firebase's `firestore-send-email` extension, ...) configured in this
 * project yet (`firebase.json` declares no `extensions`). The invite link
 * built from [CreateInviteResponse.token] is handed back to the caller,
 * which is responsible for presenting/copying it in `InviteUserPage` today;
 * wiring a real transactional e-mail send is left as a documented follow-up
 * (see TASK-039-...-CONCLUIDA.md, "Decisões técnicas"/"Pendências").
 */
export const createInvite = onCall<
  CreateInviteRequest,
  Promise<CreateInviteResponse>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'É necessário estar autenticado para convidar usuários.',
    );
  }
  const uid = request.auth.uid;

  const organizationId = requireNonEmptyString(
    request.data?.organizationId,
    'organizationId',
  );
  const email = requireValidEmail(request.data?.email);
  const roleName = requireNonEmptyString(request.data?.roleName, 'roleName');
  const rawMessage = request.data?.message;
  const message =
    typeof rawMessage === 'string' && rawMessage.trim().length > 0
      ? rawMessage.trim()
      : null;

  const db = getFirestore();
  const organizationRef = db.collection('organizations').doc(organizationId);

  const membership = await loadActiveMembership(db, organizationId, uid);
  assertCanIssueInvite(membership.roleName, roleName);

  const organizationSnapshot = await organizationRef.get();
  if (!organizationSnapshot.exists) {
    throw new HttpsError('not-found', 'Organization not found.');
  }

  const actorName = await resolveActorName(db, uid, request.auth.token);
  const { token, tokenHash } = generateInviteToken();
  const now = Timestamp.now();
  const expiresAt = resolveInviteExpiration(organizationSnapshot.data(), now);
  const inviteRef = organizationRef.collection('invites').doc();

  const inviteData: DocumentData = {
    organizationId,
    email,
    roleName,
    status: 'pending',
    tokenHash,
    invitedByUserId: uid,
    invitedByName: actorName,
    message,
    expiresAt,
    createdAt: now,
    createdBy: uid,
    updatedAt: now,
    updatedBy: uid,
  };

  await db.runTransaction(async (transaction) => {
    transaction.set(inviteRef, inviteData);
    transaction.set(organizationRef.collection('auditLogs').doc(), {
      organizationId,
      actorUserId: uid,
      actorName,
      action: 'user.invited',
      entityType: 'invite',
      entityId: inviteRef.id,
      previousValue: null,
      newValue: { email, roleName },
      timestamp: now,
    });
  });

  logger.info('createInvite succeeded', {
    correlationId,
    uid,
    organizationId,
    inviteId: inviteRef.id,
  });

  return {
    invite: serializeInvite(inviteRef.id, inviteData),
    token,
    correlationId,
  };
});
