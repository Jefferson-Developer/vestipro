import { HttpsError } from 'firebase-functions/v2/https';
import type { Firestore } from 'firebase-admin/firestore';

import { SYSTEM_ROLE_RANK } from '../invites/invite-shared';
import type { OidcConnectionInput, SamlConnectionInput, SsoProtocol } from './types';

/**
 * Shared by every corporate-SSO Cloud Function (TASK-173, EPIC-23) —
 * `configureSsoConnection`, `resolveSsoForEmail`, `completeSsoLogin` — same
 * "RBAC/validation/paths defined exactly once" rationale
 * `webhook-shared.ts`/`erp-integration-shared.ts` already document.
 */

/** Configuring which corporate IdP an organization trusts is an
 * infrastructure decision, same restrictive scope as
 * `WEBHOOK_MANAGE_ROLES`/`Capability.erpIntegrationManage`: never delegated
 * to SALES_MANAGER/SALES_REP/SALES_ASSISTANT/FINANCE. */
export const SSO_MANAGE_ROLES: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
]);

export function assertCanManageSso(roleName: string): void {
  if (!SSO_MANAGE_ROLES.has(roleName)) {
    throw new HttpsError(
      'permission-denied',
      'Seu perfil não pode configurar autenticação corporativa (SSO).',
    );
  }
}

/** Roles a `defaultRoleName` may never be (TASK-173: "SSO nunca provisiona
 * usuário com papel administrativo/gestor por padrão — papel inicial é
 * sempre o mais restritivo configurado pela organização"). Deliberately only
 * `OWNER`/`ADMIN` — `SALES_MANAGER` is not an "administrative" role in the
 * RBAC sense (`RolePermissionMatrix` never grants it
 * `organizationSettingsManage`/`roleManage`), so an organization remains free
 * to JIT-provision straight into it if that is genuinely its most permissive
 * self-service default. */
const SSO_FORBIDDEN_DEFAULT_ROLES: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
]);

/**
 * Validates [raw] is a known `SystemRoleName` (`SYSTEM_ROLE_RANK`'s keys) and
 * never `OWNER`/`ADMIN`. Throws `HttpsError('invalid-argument', ...)`
 * otherwise — never silently coerces to a default, since a JIT-provisioned
 * Membership's very first role must be an explicit, auditable organization
 * decision.
 */
export function validateDefaultRoleName(raw: unknown): string {
  if (typeof raw !== 'string' || raw.trim().length === 0) {
    throw new HttpsError('invalid-argument', 'defaultRoleName é obrigatório.');
  }
  const roleName = raw.trim().toUpperCase();
  if (SYSTEM_ROLE_RANK[roleName] === undefined) {
    throw new HttpsError('invalid-argument', 'defaultRoleName inválido.');
  }
  if (SSO_FORBIDDEN_DEFAULT_ROLES.has(roleName)) {
    throw new HttpsError(
      'invalid-argument',
      'defaultRoleName nunca pode ser OWNER/ADMIN — SSO nunca provisiona com papel administrativo por padrão.',
    );
  }
  return roleName;
}

export function validateSsoProtocol(raw: unknown): SsoProtocol {
  if (raw === 'saml' || raw === 'oidc') {
    return raw;
  }
  throw new HttpsError('invalid-argument', 'protocol deve ser "saml" ou "oidc".');
}

const DOMAIN_PATTERN = /^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?(\.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)+$/;

/** Normalizes a single e-mail domain (lower-cased, trimmed) and validates it
 * looks like a plausible domain (no `@`, no spaces, at least one `.`) —
 * intentionally loose, same "reject obvious garbage, not RFC compliance"
 * posture as `requireValidEmail` (`invite-shared.ts`). */
export function normalizeEmailDomain(raw: unknown): string {
  if (typeof raw !== 'string' || raw.trim().length === 0) {
    throw new HttpsError('invalid-argument', 'emailDomains contém um domínio vazio.');
  }
  const domain = raw.trim().toLowerCase();
  if (!DOMAIN_PATTERN.test(domain)) {
    throw new HttpsError(
      'invalid-argument',
      `Domínio de e-mail inválido em emailDomains: ${domain}.`,
    );
  }
  return domain;
}

/** Validates the full `emailDomains` list — non-empty, every entry a
 * plausible domain, deduplicated. Throws `HttpsError('invalid-argument', ...)`
 * otherwise. */
export function validateEmailDomains(raw: unknown): string[] {
  if (!Array.isArray(raw) || raw.length === 0) {
    throw new HttpsError(
      'invalid-argument',
      'emailDomains deve ser uma lista não vazia de domínios de e-mail.',
    );
  }
  const seen = new Set<string>();
  const validated: string[] = [];
  for (const value of raw) {
    const domain = normalizeEmailDomain(value);
    if (!seen.has(domain)) {
      seen.add(domain);
      validated.push(domain);
    }
  }
  return validated;
}

/** Lower-cased domain portion of [email] (everything after the last `@`), or
 * `null` when [email] has no `@` at all — the caller decides how to treat
 * that (`resolveSsoForEmail`/`completeSsoLogin` both just resolve to "no
 * connection found" rather than throwing, an ordinary outcome of a caller
 * mistyping an e-mail, not an exceptional server condition). */
export function extractEmailDomain(email: string): string | null {
  const at = email.lastIndexOf('@');
  if (at < 0 || at === email.length - 1) return null;
  return email.slice(at + 1).trim().toLowerCase();
}

/** `true` when [signInProvider] (Firebase Auth ID token's own
 * `firebase.sign_in_provider` claim) is a federated SAML/OIDC provider this
 * feature could have registered — `completeSsoLogin` rejects any other value
 * (`'password'`, `'google.com'`, etc.), so a plain e-mail/senha session can
 * never call it to self-provision (TASK-173: "usuário provisionado via SSO
 * segue exatamente o mesmo RBAC... não existe 'usuário SSO' com regras
 * diferentes" — the flip side of that is this Function only ever runs for a
 * *bona fide* SSO session, never a regular one calling it out of band). */
export function isFederatedSignInProvider(
  signInProvider: string | undefined,
): boolean {
  return (
    typeof signInProvider === 'string' &&
    (signInProvider.startsWith('saml.') || signInProvider.startsWith('oidc.'))
  );
}

/** Identity Platform's own required `providerId` prefix per protocol
 * (`admin.auth().createProviderConfig`'s documented constraint: "For a SAML
 * provider, this is always prefixed by `saml.`. For an OIDC provider, this
 * is always prefixed by `oidc.`"). [connectionId] is this feature's own
 * `ssoConnections/{connectionId}` document id, so a `providerId` never
 * collides across organizations/connections (Firestore ids are unique by
 * construction). */
export function buildProviderId(protocol: SsoProtocol, connectionId: string): string {
  return `${protocol}.${connectionId}`;
}

function requireNonEmptyStringField(raw: unknown, field: string): string {
  if (typeof raw !== 'string' || raw.trim().length === 0) {
    throw new HttpsError('invalid-argument', `${field} é obrigatório.`);
  }
  return raw.trim();
}

/** Validates the SAML-specific half of a `configureSsoConnection` request —
 * every field `SAMLAuthProviderConfig` (`firebase-admin/auth`) requires,
 * beyond what Identity Platform itself validates when this Function calls
 * `createProviderConfig`/`updateProviderConfig` (an invalid/expired
 * certificate is only ever caught there, never here). */
export function validateSamlInput(raw: unknown): SamlConnectionInput {
  const body = (raw ?? {}) as Record<string, unknown>;
  const idpEntityId = requireNonEmptyStringField(body.idpEntityId, 'idpEntityId');
  const ssoURL = requireNonEmptyStringField(body.ssoURL, 'ssoURL');
  const rpEntityId = requireNonEmptyStringField(body.rpEntityId, 'rpEntityId');
  const rawCertificates = body.x509Certificates;
  if (!Array.isArray(rawCertificates) || rawCertificates.length === 0) {
    throw new HttpsError(
      'invalid-argument',
      'x509Certificates deve ser uma lista não vazia com o(s) certificado(s) do IdP.',
    );
  }
  const x509Certificates = rawCertificates.map((certificate, index) => {
    if (typeof certificate !== 'string' || certificate.trim().length === 0) {
      throw new HttpsError(
        'invalid-argument',
        `x509Certificates[${index}] está vazio.`,
      );
    }
    return certificate.trim();
  });
  const callbackURL =
    typeof body.callbackURL === 'string' && body.callbackURL.trim().length > 0
      ? body.callbackURL.trim()
      : undefined;
  return { idpEntityId, ssoURL, rpEntityId, x509Certificates, callbackURL };
}

/** Validates the OIDC-specific half of a `configureSsoConnection` request —
 * `clientSecret` is optional (some OIDC flows use only the implicit
 * `id_token` response type, never exchanging a secret at all). */
export function validateOidcInput(raw: unknown): OidcConnectionInput {
  const body = (raw ?? {}) as Record<string, unknown>;
  const clientId = requireNonEmptyStringField(body.clientId, 'clientId');
  const issuer = requireNonEmptyStringField(body.issuer, 'issuer');
  const clientSecret =
    typeof body.clientSecret === 'string' && body.clientSecret.trim().length > 0
      ? body.clientSecret.trim()
      : undefined;
  return { clientId, issuer, clientSecret };
}

// ---------------------------------------------------------------------------
// Firestore path helpers — the single place this feature builds a path from,
// so a path can never accidentally drift outside
// `organizations/{organizationId}/...` and leak across tenants.
// ---------------------------------------------------------------------------

export function ssoConnectionsCollection(db: Firestore, organizationId: string) {
  return db
    .collection('organizations')
    .doc(organizationId)
    .collection('ssoConnections');
}

export function ssoConnectionRef(
  db: Firestore,
  organizationId: string,
  connectionId: string,
) {
  return ssoConnectionsCollection(db, organizationId).doc(connectionId);
}
