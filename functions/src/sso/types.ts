import type { DocumentData } from 'firebase-admin/firestore';

/**
 * The two federation protocols VestiPro's SSO corporativo (TASK-173,
 * EPIC-23) supports — mirrors Identity Platform's own two supported
 * external-IdP families. Every [SsoConnectionDoc.providerId] this feature
 * ever creates is prefixed accordingly (`saml.`/`oidc.`), per Identity
 * Platform's own requirement (`admin.auth().createProviderConfig`).
 */
export type SsoProtocol = 'saml' | 'oidc';

/**
 * `'active'` is the only status {@link resolveSsoForEmail}/`completeSsoLogin`
 * ever honor — `'disabled'` (an organization administrator turned it off) and
 * `'invalid_config'` (Identity Platform rejected the metadata/certificate at
 * configuration time, TASK-173: "Login SSO mal configurado... falha de forma
 * segura e informativa, nunca concede acesso por fallback silencioso") both
 * behave identically from the login flow's point of view: no organization is
 * ever resolved/authenticated against them.
 */
export type SsoConnectionStatus = 'active' | 'disabled' | 'invalid_config';

/**
 * `organizations/{organizationId}/ssoConnections/{connectionId}` — never
 * client-readable at all, by any role, under any capability
 * (`firestore.rules`): it carries enough of the IdP's own configuration
 * (SAML `x509Certificates`, OIDC `clientId`/`issuer`) that a leaked read
 * would help an attacker impersonate/probe the organization's real IdP, same
 * deliberately stricter posture `webhookSecrets`/`apiKeys` already set
 * (TASK-170/TASK-171). Exclusively written by this feature's own Cloud
 * Functions (Admin SDK bypasses these Rules) —
 * `configureSsoConnection`/`completeSsoLogin`'s own JIT bookkeeping never
 * touches this document, only `organizations/{organizationId}/members/{uid}`.
 */
export interface SsoConnectionDoc extends DocumentData {
  organizationId: string;
  protocol: SsoProtocol;
  /** Always `${protocol}.${connectionId}` — the exact Identity Platform
   * `providerId` this connection was registered under
   * (`admin.auth().createProviderConfig`/`updateProviderConfig`). */
  providerId: string;
  displayName: string;
  /** Normalized (lower-cased, deduplicated), non-empty — unique *globally*
   * across every organization's `ssoConnections` (TASK-173: "Configuração de
   * um IdP pertence exclusivamente à organização que o cadastrou"),
   * enforced by `assertEmailDomainsNotUsedElsewhere` at configuration time. */
  emailDomains: string[];
  /** The `SystemRoleName` a brand-new Membership is provisioned with on a
   * user's first SSO login (`completeSsoLogin`) — validated by
   * `validateDefaultRoleName` to never be `'OWNER'`/`'ADMIN'` (TASK-173:
   * "SSO nunca provisiona usuário com papel administrativo... por padrão"). */
  defaultRoleName: string;
  status: SsoConnectionStatus;
  /** Only meaningful when [status] is `'invalid_config'` — the raw message
   * Identity Platform (or this Function's own validation) rejected the
   * configuration with, surfaced back to `configureSsoConnection`'s caller
   * for diagnosis. `null` otherwise. */
  lastConfigError: string | null;
  createdAt: unknown;
  createdBy: string;
  updatedAt: unknown;
  updatedBy: string;
  version: number;
}

/** SAML-specific fields `configureSsoConnection` maps 1:1 onto Identity
 * Platform's own `SAMLAuthProviderConfig` (`firebase-admin/auth`) — never
 * persisted to Firestore itself (Identity Platform is the only store of
 * record for the IdP metadata/certificate; `SsoConnectionDoc` only stores
 * VestiPro's own routing/RBAC decision on top of it). */
export interface SamlConnectionInput {
  idpEntityId: string;
  ssoURL: string;
  x509Certificates: string[];
  rpEntityId: string;
  callbackURL?: string;
}

/** OIDC-specific fields, same "never persisted to Firestore" rationale as
 * {@link SamlConnectionInput}. */
export interface OidcConnectionInput {
  clientId: string;
  issuer: string;
  clientSecret?: string;
}
