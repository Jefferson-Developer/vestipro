import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';
import { getFirestore } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { requireValidEmail } from '../invites/invite-shared';
import { extractEmailDomain } from './sso-shared';
import type { SsoProtocol } from './types';

export interface ResolveSsoForEmailRequest extends RequestWithMeta {
  email?: string;
}

export interface ResolveSsoForEmailResponse {
  found: boolean;
  organizationId: string | null;
  organizationName: string | null;
  protocol: SsoProtocol | null;
  providerId: string | null;
  correlationId: string;
}

/**
 * Resolves which organization's corporate SSO connection (if any) [email]'s
 * domain routes to (TASK-173) — `LoginPage`'s "Entrar com SSO corporativo"
 * flow calls this *before* redirecting to any IdP, so it knows which
 * `providerId` to hand `FirebaseAuth.signInWithProvider`
 * (`SAMLAuthProvider`/`OAuthProvider`).
 *
 * Callable without authentication (mirrors `validateInvite`,
 * `functions/src/invites/validate-invite.ts`): the whole point is being safe
 * to call before anyone is signed in. Never throws for the ordinary "no SSO
 * configured for this domain" outcome — only [found] distinguishes it,
 * never an [HttpsError] — and never returns anything beyond
 * [ResolveSsoForEmailResponse]'s own shape (no domain list, no
 * `defaultRoleName`, nothing about *other* organizations), so this endpoint
 * cannot be used to enumerate an organization's configuration.
 *
 * Only ever resolves a connection whose `status === 'active'` — a
 * `'disabled'`/`'invalid_config'` connection is indistinguishable from "no
 * connection at all" here (TASK-173: "Login SSO mal configurado... falha de
 * forma segura e informativa, nunca concede acesso por fallback
 * silencioso").
 */
export const resolveSsoForEmail = onCall<
  ResolveSsoForEmailRequest,
  Promise<ResolveSsoForEmailResponse>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);
  const email = requireValidEmail(request.data?.email);
  const domain = extractEmailDomain(email);

  if (!domain) {
    return {
      found: false,
      organizationId: null,
      organizationName: null,
      protocol: null,
      providerId: null,
      correlationId,
    };
  }

  const db = getFirestore();
  const snapshot = await db
    .collectionGroup('ssoConnections')
    .where('emailDomains', 'array-contains', domain)
    .where('status', '==', 'active')
    .limit(1)
    .get();

  if (snapshot.empty) {
    logger.info('resolveSsoForEmail: no active connection for domain', {
      correlationId,
      domain,
    });
    return {
      found: false,
      organizationId: null,
      organizationName: null,
      protocol: null,
      providerId: null,
      correlationId,
    };
  }

  const connectionDoc = snapshot.docs[0];
  const organizationRef = connectionDoc.ref.parent.parent;
  const organizationId = organizationRef?.id ?? null;
  const organizationSnapshot = organizationRef ? await organizationRef.get() : null;
  const organizationName =
    (organizationSnapshot?.data()?.name as string | undefined) ?? null;

  logger.info('resolveSsoForEmail succeeded', {
    correlationId,
    organizationId,
    connectionId: connectionDoc.id,
  });

  return {
    found: true,
    organizationId,
    organizationName,
    protocol: connectionDoc.data().protocol as SsoProtocol,
    providerId: connectionDoc.data().providerId as string,
    correlationId,
  };
});
