import type { DocumentData } from 'firebase-admin/firestore';

/**
 * Every domain event VestiPro can push to an organization's outbound
 * webhooks (TASK-170, EPIC-22). `'webhook.test'` is deliberately not a real
 * domain event — it only ever exists as the payload of
 * `sendTestWebhookEvent`, targeting exactly one webhook regardless of which
 * real events it is subscribed to (`WebhookConfigDoc.events` is never
 * consulted for a test send).
 */
export const WEBHOOK_DOMAIN_EVENT_TYPES = [
  'order.created',
  'order.status_changed',
  'customer.created',
  'inventory.updated',
] as const;

export type WebhookDomainEventType = (typeof WEBHOOK_DOMAIN_EVENT_TYPES)[number];

export type WebhookEventType = WebhookDomainEventType | 'webhook.test';

export type WebhookDeliveryStatus =
  | 'pending'
  | 'syncing'
  | 'synced'
  | 'failed';

export type WebhookHealthStatus = 'ok' | 'failing';

/**
 * Non-secret half of an organization's webhook configuration — the HMAC
 * secret itself lives exclusively in `WebhookSecretDoc`
 * (`organizations/{organizationId}/webhookSecrets/{webhookId}`), a document
 * `firestore.rules` denies read/write on outright for every client, same
 * split/justification as `ErpIntegrationConfig`/`ErpIntegrationCredentials`
 * (TASK-169).
 */
export interface WebhookConfigDoc extends DocumentData {
  organizationId: string;
  url: string;
  events: WebhookDomainEventType[];
  isActive: boolean;
  /** Rolls up the outcome of the most recent delivery *sequence* for this
   * webhook — `'failing'` once a delivery has exhausted every retry
   * attempt, reset back to `'ok'` the next time any delivery to this same
   * webhook succeeds. The closest thing to a "gestor é notificado" signal
   * this framework has without a dedicated push-notification channel: the
   * webhook configuration screen reads this field directly, same "state the
   * gestor sees when they open the screen" shape `productImportJobs.status`
   * already uses for import jobs. */
  healthStatus: WebhookHealthStatus;
  consecutiveFailureCount: number;
  lastFailureAt: unknown | null;
  lastSuccessAt: unknown | null;
  createdAt: unknown;
  createdBy: string;
  updatedAt: unknown;
  updatedBy: string;
}

/** Never read by any Firestore Security Rule path available to a client —
 * mirrors `ErpIntegrationCredentials` (TASK-169): only this feature's own
 * Cloud Functions (Admin SDK) ever read it, exclusively to sign an outbound
 * payload. Never echoed back in any callable response after creation/
 * regeneration. */
export interface WebhookSecretDoc extends DocumentData {
  organizationId: string;
  webhookId: string;
  secret: string;
  updatedAt: unknown;
  updatedBy: string;
}

export interface WebhookDeliveryDoc extends DocumentData {
  organizationId: string;
  webhookId: string;
  eventId: string;
  eventType: WebhookEventType;
  /** The event's own domain payload — never includes another organization's
   * data nor anything beyond what the event type needs (TASK-170: "Payload
   * de webhook nunca inclui dados de outra organização nem dados sensíveis
   * além do necessário ao evento"). */
  data: Record<string, unknown>;
  isTest: boolean;
  status: WebhookDeliveryStatus;
  attempts: number;
  lastError: string | null;
  lastResponseStatus: number | null;
  nextRetryAt: unknown | null;
  createdAt: unknown;
  processedAt: unknown | null;
}

export interface WebhookDeliveryLogDoc extends DocumentData {
  organizationId: string;
  webhookId: string;
  deliveryId: string;
  eventId: string;
  eventType: WebhookEventType;
  attempt: number;
  requestUrl: string;
  success: boolean;
  responseStatus: number | null;
  errorMessage: string | null;
  createdAt: unknown;
}

export interface EnqueueWebhookEventParams {
  organizationId: string;
  eventType: WebhookDomainEventType;
  /** The domain entity's own id (e.g. `orderId`, `customerId`,
   * `inventoryId`) — combined with `sourceVersion` to build a deterministic
   * `eventId`, so redelivering the exact same underlying occurrence (a
   * retried Cloud Function invocation, a duplicate trigger firing) always
   * resolves to the same `eventId` a consumer can dedupe by (TASK-170:
   * "Todo evento carrega um eventId único e idempotente"). */
  entityId: string;
  /** An opaque, monotonically-changing marker for this exact occurrence of
   * the event (e.g. the order's `version` for `order.created`, `newStatus`
   * for `order.status_changed`) — never reused across two materially
   * different occurrences of the same entity/event type. */
  sourceVersion: string;
  data: Record<string, unknown>;
  now: Date;
}
