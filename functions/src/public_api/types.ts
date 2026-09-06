/**
 * Shared vocabulary for the public REST API (TASK-171, EPIC-22) — the scopes
 * an `apiKeys` document can grant, kept as a closed, explicit whitelist (same
 * "no-code, no arbitrary string" rationale `ERP_MANAGEABLE_FIELDS_BY_ENTITY`,
 * `erp_integration/erp-integration-shared.ts`, TASK-169, already documents)
 * so `saveWebhookConfig`-style callables and the REST middleware always agree
 * on exactly which strings are meaningful.
 */
export type ApiKeyScope =
  | 'customers:read'
  | 'products:read'
  | 'orders:read'
  | 'orders:write';

export const API_KEY_SCOPES: readonly ApiKeyScope[] = [
  'customers:read',
  'products:read',
  'orders:read',
  'orders:write',
];

export type ApiKeyStatus = 'active' | 'revoked';
