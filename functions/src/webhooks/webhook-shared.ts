import { createHash, createHmac, randomBytes, timingSafeEqual } from 'node:crypto';

import { HttpsError } from 'firebase-functions/v2/https';
import type { Firestore } from 'firebase-admin/firestore';

import {
  WEBHOOK_DOMAIN_EVENT_TYPES,
  type WebhookDomainEventType,
} from './types';

/**
 * Shared by every outbound-webhook Cloud Function (TASK-170, EPIC-22) —
 * `saveWebhookConfig`, `regenerateWebhookSecret`, `sendTestWebhookEvent`,
 * `enqueueWebhookEvent`, `deliverWebhookEvent`,
 * `retryFailedWebhookDeliveries` — same "RBAC/vocabulary/validation/paths
 * defined exactly once" rationale `erp-integration-shared.ts` (TASK-169)
 * already documents.
 */

/** Configuring which URLs an organization pushes events to — plus reading
 * its secret's *existence* (never its value) and delivery history — is an
 * infrastructure decision, same restrictive scope as
 * `ERP_INTEGRATION_ROLES`/`Capability.erpIntegrationManage`: never delegated
 * to SALES_MANAGER/SALES_REP/SALES_ASSISTANT/FINANCE. */
export const WEBHOOK_MANAGE_ROLES: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
]);

export function assertCanManageWebhooks(roleName: string): void {
  if (!WEBHOOK_MANAGE_ROLES.has(roleName)) {
    throw new HttpsError(
      'permission-denied',
      'Seu perfil não pode configurar webhooks.',
    );
  }
}

export function isWebhookDomainEventType(
  value: string,
): value is WebhookDomainEventType {
  return (WEBHOOK_DOMAIN_EVENT_TYPES as readonly string[]).includes(value);
}

/** Validates the list of events a webhook subscribes to — non-empty, every
 * entry a known `WebhookDomainEventType`, no duplicates. Throws
 * `HttpsError('invalid-argument', ...)` otherwise. */
export function validateWebhookEvents(raw: unknown): WebhookDomainEventType[] {
  if (!Array.isArray(raw) || raw.length === 0) {
    throw new HttpsError(
      'invalid-argument',
      'events deve ser uma lista não vazia de eventos.',
    );
  }
  const seen = new Set<string>();
  const validated: WebhookDomainEventType[] = [];
  for (const value of raw) {
    if (typeof value !== 'string' || !isWebhookDomainEventType(value)) {
      throw new HttpsError(
        'invalid-argument',
        `Tipo de evento desconhecido em events: ${String(value)}.`,
      );
    }
    if (!seen.has(value)) {
      seen.add(value);
      validated.push(value);
    }
  }
  return validated;
}

/** Only ever accepts an `https://` URL — a webhook carrying commercial data
 * (pedidos, clientes, estoque) is never allowed to travel over plaintext
 * HTTP, regardless of what a gestor types in. */
export function validateWebhookUrl(raw: unknown): string {
  if (typeof raw !== 'string' || raw.trim().length === 0) {
    throw new HttpsError('invalid-argument', 'url é obrigatória.');
  }
  const url = raw.trim();
  let parsed: URL;
  try {
    parsed = new URL(url);
  } catch {
    throw new HttpsError('invalid-argument', 'url inválida.');
  }
  if (parsed.protocol !== 'https:') {
    throw new HttpsError(
      'invalid-argument',
      'url deve usar https:// (nunca http://).',
    );
  }
  return url;
}

/** Cryptographically random, opaque HMAC secret — 256 bits of entropy,
 * hex-encoded so it is safe to display/copy exactly once at
 * creation/regeneration time (TASK-170: "Segredo HMAC nunca é reexibido em
 * texto claro após a criação inicial"). */
export function generateWebhookSecret(): string {
  return randomBytes(32).toString('hex');
}

export const WEBHOOK_SIGNATURE_HEADER = 'X-VestiPro-Signature';
export const WEBHOOK_EVENT_ID_HEADER = 'X-VestiPro-Event-Id';
export const WEBHOOK_EVENT_TYPE_HEADER = 'X-VestiPro-Event-Type';

/** HMAC-SHA256 of the exact raw request body, hex-encoded — the consumer
 * recomputes the exact same value over the exact same raw bytes with its
 * own copy of the secret to validate origin/integrity (TASK-170:
 * "Assinatura HMAC-SHA256 do payload usando o segredo da organização"). */
export function signWebhookPayload(secret: string, rawBody: string): string {
  return createHmac('sha256', secret).update(rawBody, 'utf8').digest('hex');
}

/** Constant-time signature comparison — the reference implementation a
 * consumer's own verification code should mirror. Deliberately exported (and
 * unit-tested) even though the real verification always happens on the
 * consumer's side: it is the single source of truth this codebase relies on
 * when validating its own reference/test-harness signatures. */
export function verifyWebhookSignature(
  secret: string,
  rawBody: string,
  signatureHex: string,
): boolean {
  const expected = signWebhookPayload(secret, rawBody);
  const expectedBuffer = Buffer.from(expected, 'hex');
  const actualBuffer = Buffer.from(signatureHex, 'hex');
  if (expectedBuffer.length !== actualBuffer.length) {
    return false;
  }
  return timingSafeEqual(expectedBuffer, actualBuffer);
}

export const MAX_WEBHOOK_DELIVERY_ATTEMPTS = 4;

/** Minutes to wait before retrying a failed delivery, indexed by
 * `attempts - 1` — TASK-170's own schedule: "1min, 5min, 30min, 2h". Capped
 * at the last entry for any attempt beyond this table's length. */
export const WEBHOOK_RETRY_BACKOFF_MINUTES: readonly number[] = [1, 5, 30, 120];

export function nextWebhookRetryDelayMinutes(attempts: number): number {
  const index = Math.min(attempts, WEBHOOK_RETRY_BACKOFF_MINUTES.length) - 1;
  return WEBHOOK_RETRY_BACKOFF_MINUTES[Math.max(index, 0)];
}

export interface WebhookEventIdInput {
  organizationId: string;
  eventType: string;
  entityId: string;
  sourceVersion: string;
}

/** Deterministic `eventId` (TASK-170: "Todo evento carrega um eventId único
 * e idempotente para o consumidor poder deduplicar em caso de
 * reentrega") — the exact same organization/eventType/entityId/sourceVersion
 * tuple always hashes to the exact same id, so the exact same underlying
 * occurrence is never assigned two different ids no matter how many times
 * it is (re)enqueued or (re)delivered. Mirrors
 * `computeIdempotencyKey` (`erp-integration-shared.ts`, TASK-169). */
export function computeWebhookEventId(input: WebhookEventIdInput): string {
  const canonical = [
    input.organizationId,
    input.eventType,
    input.entityId,
    input.sourceVersion,
  ].join('|');
  return createHash('sha256').update(canonical).digest('hex');
}

// ---------------------------------------------------------------------------
// Firestore path helpers — the single place every outbound-webhook Cloud
// Function builds a path from, so a path can never accidentally drift
// outside `organizations/{organizationId}/...` and leak across tenants.
// ---------------------------------------------------------------------------

export function webhookConfigsCollection(db: Firestore, organizationId: string) {
  return db
    .collection('organizations')
    .doc(organizationId)
    .collection('webhooks');
}

export function webhookConfigRef(
  db: Firestore,
  organizationId: string,
  webhookId: string,
) {
  return webhookConfigsCollection(db, organizationId).doc(webhookId);
}

export function webhookSecretRef(
  db: Firestore,
  organizationId: string,
  webhookId: string,
) {
  return db
    .collection('organizations')
    .doc(organizationId)
    .collection('webhookSecrets')
    .doc(webhookId);
}

export function webhookDeliveriesCollection(
  db: Firestore,
  organizationId: string,
) {
  return db
    .collection('organizations')
    .doc(organizationId)
    .collection('webhookDeliveries');
}

export function webhookDeliveryLogsCollection(
  db: Firestore,
  organizationId: string,
) {
  return db
    .collection('organizations')
    .doc(organizationId)
    .collection('webhookDeliveryLogs');
}
