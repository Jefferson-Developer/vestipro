import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';
import { getFirestore, Timestamp, type DocumentData } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import {
  ACCESS_DISABLED_MESSAGE,
  resolveActorName,
} from '../invites/invite-shared';
import { extractEmailDomain, isFederatedSignInProvider } from './sso-shared';

export type CompleteSsoLoginRequest = RequestWithMeta;

export interface CompleteSsoLoginResponse {
  organizationId: string;
  organizationName: string;
  roleName: string;
  /** `true` the very first time this uid completes SSO login for this
   * organization (a brand-new Membership was just JIT-provisioned), `false`
   * on every subsequent login (only denormalized name/e-mail refreshed). */
  provisioned: boolean;
  correlationId: string;
}

/**
 * Completes a corporate SSO sign-in (TASK-173): the caller must already be
 * authenticated with Firebase Auth against a federated SAML/OIDC provider
 * this feature registered (`configureSsoConnection`) — this Function never
 * performs the federation handshake itself, that already happened via
 * `FirebaseAuth.signInWithProvider` client-side. What this Function owns is
 * exactly the just-in-time provisioning decision: create (first login) or
 * refresh (subsequent logins) the caller's
 * `organizations/{organizationId}/members/{uid}` Membership, respecting the
 * exact same RBAC/isolation model every other Membership already does
 * (TASK-173: "Usuário provisionado via SSO segue exatamente o mesmo RBAC e
 * isolamento multi-tenant que qualquer outro usuário").
 *
 * **Never callable from a regular e-mail/senha session**: rejects unless
 * `request.auth.token.firebase.sign_in_provider` is a federated `saml.*`/
 * `oidc.*` provider (`isFederatedSignInProvider`) — otherwise a signed-in
 * user could call this directly to self-provision into an arbitrary
 * organization's `defaultRoleName`, bypassing `acceptInvite`'s own
 * authorization entirely.
 *
 * **Never resets a role an admin already changed (TASK-173)**: on a second+
 * login, only `name`/`email`/`updatedAt`/`updatedBy` are refreshed —
 * `roleId`/`roleName`/`teamIds`/`status` are always preserved as-is. An
 * already-`'inactive'` Membership (an admin deactivated this user) is never
 * silently reactivated by an SSO login — same fail-closed posture
 * `loadActiveMembership` already documents for every other flow.
 */
export const completeSsoLogin = onCall<
  CompleteSsoLoginRequest,
  Promise<CompleteSsoLoginResponse>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Autenticação obrigatória.');
  }

  const signInProvider = (
    request.auth.token as { firebase?: { sign_in_provider?: string } } | undefined
  )?.firebase?.sign_in_provider;

  if (!isFederatedSignInProvider(signInProvider)) {
    throw new HttpsError(
      'permission-denied',
      'Esta função é exclusiva de sessões autenticadas via SSO corporativo.',
    );
  }
  const providerId = signInProvider as string;

  const uid = request.auth.uid;
  const email = (request.auth.token?.email as string | undefined)?.toLowerCase();
  if (!email) {
    throw new HttpsError(
      'failed-precondition',
      'O provedor de identidade não retornou um e-mail para esta conta.',
    );
  }

  const db = getFirestore();

  const connectionSnapshot = await db
    .collectionGroup('ssoConnections')
    .where('providerId', '==', providerId)
    .limit(1)
    .get();

  if (connectionSnapshot.empty) {
    throw new HttpsError(
      'failed-precondition',
      'Configuração de SSO não encontrada para este provedor.',
    );
  }

  const connectionDoc = connectionSnapshot.docs[0];
  const connectionData = connectionDoc.data();
  const organizationRef = connectionDoc.ref.parent.parent;
  if (!organizationRef) {
    throw new HttpsError(
      'internal',
      'Conexão de SSO referencia uma organização inexistente.',
    );
  }
  const organizationId = organizationRef.id;

  if (connectionData.status !== 'active') {
    throw new HttpsError(
      'failed-precondition',
      'Este provedor de SSO está desativado ou mal configurado.',
    );
  }

  const emailDomains = (connectionData.emailDomains as string[] | undefined) ?? [];
  const emailDomain = extractEmailDomain(email);
  if (!emailDomain || !emailDomains.includes(emailDomain)) {
    // Defense in depth: the IdP asserted an e-mail whose domain was never
    // assigned to this connection (a misconfigured/compromised IdP). Never
    // trusted, regardless of how the federation handshake itself resolved.
    throw new HttpsError(
      'permission-denied',
      'O e-mail retornado pelo provedor de identidade não pertence a este domínio corporativo.',
    );
  }

  const defaultRoleName = connectionData.defaultRoleName as string;
  const actorName = await resolveActorName(db, uid, request.auth.token);
  const now = Timestamp.now();

  const result = await db.runTransaction(async (transaction) => {
    const membershipRef = organizationRef.collection('members').doc(uid);
    const membershipSnapshot = await transaction.get(membershipRef);

    if (membershipSnapshot.exists) {
      const existing = membershipSnapshot.data() as DocumentData;
      if (existing.status !== 'active') {
        // Never silently reactivate a Membership an administrator
        // deactivated — same fail-closed posture as every other flow that
        // reads a Membership (`loadActiveMembership`).
        throw new HttpsError('permission-denied', ACCESS_DISABLED_MESSAGE);
      }

      transaction.update(membershipRef, {
        // Denormalized display fields only (TASK-042) — role/teamIds/status
        // are deliberately left untouched (TASK-173: "nunca reseta uma role
        // que um admin já alterou manualmente depois do primeiro login").
        name: actorName,
        email,
        version: ((existing.version as number | undefined) ?? 0) + 1,
        updatedAt: now,
        updatedBy: uid,
      });

      transaction.set(organizationRef.collection('auditLogs').doc(), {
        organizationId,
        actorUserId: uid,
        actorName,
        action: 'user.ssoLogin',
        entityType: 'member',
        entityId: uid,
        previousValue: null,
        newValue: { roleName: existing.roleName },
        timestamp: now,
      });

      return {
        organizationId,
        roleName: existing.roleName as string,
        provisioned: false,
      };
    }

    const membershipData: DocumentData = {
      organizationId,
      userId: uid,
      roleId: defaultRoleName,
      roleName: defaultRoleName,
      name: actorName,
      email,
      teamIds: [],
      status: 'active',
      version: 1,
      createdAt: now,
      createdBy: uid,
      updatedAt: now,
      updatedBy: uid,
      deletedAt: null,
    };
    transaction.set(membershipRef, membershipData);

    transaction.set(organizationRef.collection('auditLogs').doc(), {
      organizationId,
      actorUserId: uid,
      actorName,
      action: 'user.ssoLoginProvisioned',
      entityType: 'member',
      entityId: uid,
      previousValue: null,
      newValue: { roleName: defaultRoleName },
      timestamp: now,
    });

    return { organizationId, roleName: defaultRoleName, provisioned: true };
  });

  const organizationSnapshot = await organizationRef.get();
  const organizationName = (organizationSnapshot.data()?.name as string | undefined) ?? '';

  logger.info('completeSsoLogin succeeded', {
    correlationId,
    uid,
    organizationId: result.organizationId,
    provisioned: result.provisioned,
  });

  return { ...result, organizationName, correlationId };
});
