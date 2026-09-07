import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import type { AuthProviderConfig } from 'firebase-admin/auth';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import {
  loadActiveMembership,
  requireNonEmptyString,
  resolveActorName,
} from '../invites/invite-shared';
import {
  assertCanManageSso,
  buildProviderId,
  ssoConnectionRef,
  ssoConnectionsCollection,
  validateDefaultRoleName,
  validateEmailDomains,
  validateOidcInput,
  validateSamlInput,
  validateSsoProtocol,
} from './sso-shared';
import type { SsoConnectionStatus } from './types';

export interface ConfigureSsoConnectionRequest extends RequestWithMeta {
  organizationId?: string;
  /** Absent (or empty) creates a new connection; present updates the
   * existing one — same create-or-update shape as `saveWebhookConfig`
   * (TASK-170). */
  connectionId?: string;
  protocol?: string;
  displayName?: string;
  emailDomains?: unknown;
  defaultRoleName?: string;
  isActive?: boolean;
  /** Required (and only read) when `protocol === 'saml'`. */
  saml?: unknown;
  /** Required (and only read) when `protocol === 'oidc'`. */
  oidc?: unknown;
}

export interface ConfigureSsoConnectionResponse {
  correlationId: string;
  connectionId: string;
  providerId: string;
  status: SsoConnectionStatus;
}

/**
 * Creates or updates an organization's corporate SSO connection (TASK-173,
 * EPIC-23): registers the IdP's SAML/OIDC metadata with Identity Platform
 * (`admin.auth().createProviderConfig`/`updateProviderConfig`) and persists
 * VestiPro's own routing/RBAC decision on top of it
 * (`organizations/{organizationId}/ssoConnections/{connectionId}`) — which
 * e-mail domains route to this organization, and the `defaultRoleName` a
 * brand-new user is JIT-provisioned with on first login
 * (`completeSsoLogin`).
 *
 * RBAC (`assertCanManageSso`, OWNER/ADMIN only) is re-validated here from the
 * caller's real Membership, independent of anything the client claims — same
 * posture `saveWebhookConfig`/`saveErpIntegrationConfig` already document.
 *
 * **Domain isolation (TASK-173: "Configuração de um IdP pertence
 * exclusivamente à organização que o cadastrou")**: every domain in
 * [ConfigureSsoConnectionRequest.emailDomains] must not already be claimed by
 * *any other* `ssoConnections` document (any organization, any connection) —
 * checked via `collectionGroup('ssoConnections')` before ever touching
 * Identity Platform. A collision is rejected with `already-exists`, never
 * silently reassigned.
 *
 * **Fail-safe configuration (TASK-173: "Login SSO mal configurado... falha
 * de forma segura e informativa, nunca concede acesso por fallback
 * silencioso")**: the call to Identity Platform is wrapped in a `try/catch`
 * — a rejected/invalid metadata (bad certificate, unreachable issuer) never
 * throws away the attempt silently nor pretends success. The connection is
 * still persisted, but with `status: 'invalid_config'` and
 * `lastConfigError` set, which `resolveSsoForEmail`/`completeSsoLogin` both
 * treat identically to "no connection at all" — no organization is ever
 * resolved/authenticated against it — and this call itself still rejects
 * with `failed-precondition`, so the caller is never told it succeeded.
 */
export const configureSsoConnection = onCall<
  ConfigureSsoConnectionRequest,
  Promise<ConfigureSsoConnectionResponse>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Autenticação obrigatória.');
  }
  const uid = request.auth.uid;

  const organizationId = requireNonEmptyString(
    request.data?.organizationId,
    'organizationId',
  );

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  assertCanManageSso(membership.roleName);

  const protocol = validateSsoProtocol(request.data?.protocol);
  const displayName = requireNonEmptyString(
    request.data?.displayName,
    'displayName',
  );
  const emailDomains = validateEmailDomains(request.data?.emailDomains);
  const defaultRoleName = validateDefaultRoleName(request.data?.defaultRoleName);
  const isActive = request.data?.isActive !== false;
  const samlInput = protocol === 'saml' ? validateSamlInput(request.data?.saml) : null;
  const oidcInput = protocol === 'oidc' ? validateOidcInput(request.data?.oidc) : null;

  const requestedConnectionId = request.data?.connectionId?.trim();
  const isCreate = !requestedConnectionId;
  const connectionRef = isCreate
    ? ssoConnectionsCollection(db, organizationId).doc()
    : ssoConnectionRef(db, organizationId, requestedConnectionId as string);

  let previousVersion = 0;
  if (!isCreate) {
    const existing = await connectionRef.get();
    if (!existing.exists || existing.data()?.organizationId !== organizationId) {
      throw new HttpsError(
        'not-found',
        'Conexão de SSO não encontrada nesta organização.',
      );
    }
    previousVersion = (existing.data()?.version as number | undefined) ?? 0;
  }

  // Domain isolation (TASK-173): a domain already claimed by any other
  // `ssoConnections` document — regardless of which organization or
  // connection — is always a collision. Excludes only this exact
  // `connectionRef.id` (a create never matches any existing id; an update
  // legitimately re-claims its own already-assigned domains).
  for (const domain of emailDomains) {
    const collision = await db
      .collectionGroup('ssoConnections')
      .where('emailDomains', 'array-contains', domain)
      .get();
    const claimedByAnotherConnection = collision.docs.some(
      (document) => document.ref.id !== connectionRef.id,
    );
    if (claimedByAnotherConnection) {
      throw new HttpsError(
        'already-exists',
        `O domínio "${domain}" já está associado a outra configuração de SSO.`,
      );
    }
  }

  const providerId = buildProviderId(protocol, connectionRef.id);
  const now = new Date();

  let status: SsoConnectionStatus;
  let lastConfigError: string | null;
  try {
    const config: AuthProviderConfig =
      protocol === 'saml'
        ? {
            providerId,
            displayName,
            enabled: isActive,
            idpEntityId: samlInput!.idpEntityId,
            ssoURL: samlInput!.ssoURL,
            x509Certificates: samlInput!.x509Certificates,
            rpEntityId: samlInput!.rpEntityId,
            callbackURL: samlInput!.callbackURL,
          }
        : {
            providerId,
            displayName,
            enabled: isActive,
            clientId: oidcInput!.clientId,
            issuer: oidcInput!.issuer,
            clientSecret: oidcInput!.clientSecret,
            responseType: oidcInput!.clientSecret
              ? { code: true }
              : { idToken: true },
          };

    if (isCreate) {
      await getAuth().createProviderConfig(config);
    } else {
      await getAuth().updateProviderConfig(providerId, config);
    }
    status = isActive ? 'active' : 'disabled';
    lastConfigError = null;
  } catch (error) {
    status = 'invalid_config';
    lastConfigError = error instanceof Error ? error.message : String(error);
    logger.error('configureSsoConnection: Identity Platform rejected the configuration', {
      correlationId,
      organizationId,
      connectionId: connectionRef.id,
      error: lastConfigError,
    });
  }

  const actorName = await resolveActorName(db, uid, request.auth.token);

  await connectionRef.set(
    {
      organizationId,
      protocol,
      providerId,
      displayName,
      emailDomains,
      defaultRoleName,
      status,
      lastConfigError,
      ...(isCreate
        ? { createdAt: now, createdBy: uid, version: 1 }
        : { version: previousVersion + 1 }),
      updatedAt: now,
      updatedBy: uid,
    },
    { merge: true },
  );

  await db
    .collection('organizations')
    .doc(organizationId)
    .collection('auditLogs')
    .doc()
    .set({
      organizationId,
      actorUserId: uid,
      actorName,
      action: isCreate ? 'sso.connectionConfigured' : 'sso.connectionUpdated',
      entityType: 'ssoConnection',
      entityId: connectionRef.id,
      previousValue: null,
      newValue: { protocol, providerId, status, emailDomains, defaultRoleName },
      timestamp: now,
    });

  logger.info('configureSsoConnection processed', {
    correlationId,
    uid,
    organizationId,
    connectionId: connectionRef.id,
    status,
  });

  if (status === 'invalid_config') {
    throw new HttpsError(
      'failed-precondition',
      `Falha ao configurar o provedor de identidade: ${lastConfigError}. A configuração foi salva como inválida e não concede acesso até ser corrigida.`,
    );
  }

  return { correlationId, connectionId: connectionRef.id, providerId, status };
});
