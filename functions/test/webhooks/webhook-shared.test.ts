import { HttpsError } from 'firebase-functions/v2/https';

import {
  MAX_WEBHOOK_DELIVERY_ATTEMPTS,
  WEBHOOK_MANAGE_ROLES,
  assertCanManageWebhooks,
  computeWebhookEventId,
  generateWebhookSecret,
  isWebhookDomainEventType,
  nextWebhookRetryDelayMinutes,
  signWebhookPayload,
  validateWebhookEvents,
  validateWebhookUrl,
  verifyWebhookSignature,
} from '../../src/webhooks/webhook-shared';

describe('assertCanManageWebhooks', () => {
  it('allows only OWNER/ADMIN', () => {
    expect(WEBHOOK_MANAGE_ROLES.has('OWNER')).toBe(true);
    expect(WEBHOOK_MANAGE_ROLES.has('ADMIN')).toBe(true);
    expect(() => assertCanManageWebhooks('OWNER')).not.toThrow();
    expect(() => assertCanManageWebhooks('ADMIN')).not.toThrow();
  });

  it.each(['SALES_MANAGER', 'SALES_REP', 'SALES_ASSISTANT', 'FINANCE', 'READ_ONLY'])(
    'denies %s',
    (roleName) => {
      expect(() => assertCanManageWebhooks(roleName)).toThrow(HttpsError);
    },
  );
});

describe('isWebhookDomainEventType', () => {
  it('accepts every known domain event type', () => {
    expect(isWebhookDomainEventType('order.created')).toBe(true);
    expect(isWebhookDomainEventType('order.status_changed')).toBe(true);
    expect(isWebhookDomainEventType('customer.created')).toBe(true);
    expect(isWebhookDomainEventType('inventory.updated')).toBe(true);
  });

  it('rejects unknown values and the test-only pseudo event type', () => {
    expect(isWebhookDomainEventType('webhook.test')).toBe(false);
    expect(isWebhookDomainEventType('order.deleted')).toBe(false);
    expect(isWebhookDomainEventType('')).toBe(false);
  });
});

describe('validateWebhookEvents', () => {
  it('accepts a non-empty list of known event types', () => {
    expect(validateWebhookEvents(['order.created', 'customer.created'])).toEqual([
      'order.created',
      'customer.created',
    ]);
  });

  it('deduplicates repeated event types', () => {
    expect(validateWebhookEvents(['order.created', 'order.created'])).toEqual([
      'order.created',
    ]);
  });

  it('rejects an empty or missing list', () => {
    expect(() => validateWebhookEvents([])).toThrow(HttpsError);
    expect(() => validateWebhookEvents(undefined)).toThrow(HttpsError);
    expect(() => validateWebhookEvents(null)).toThrow(HttpsError);
  });

  it('rejects an unknown event type, including the test-only pseudo event', () => {
    expect(() => validateWebhookEvents(['order.deleted'])).toThrow(HttpsError);
    expect(() => validateWebhookEvents(['webhook.test'])).toThrow(HttpsError);
  });
});

describe('validateWebhookUrl', () => {
  it('accepts a well-formed https:// URL', () => {
    expect(validateWebhookUrl('https://example.com/hooks/vestipro')).toBe(
      'https://example.com/hooks/vestipro',
    );
  });

  it('rejects a plain http:// URL — commercial data never travels over '
    + 'plaintext HTTP', () => {
    expect(() => validateWebhookUrl('http://example.com/hooks')).toThrow(HttpsError);
  });

  it('rejects a missing/empty/malformed URL', () => {
    expect(() => validateWebhookUrl(undefined)).toThrow(HttpsError);
    expect(() => validateWebhookUrl('')).toThrow(HttpsError);
    expect(() => validateWebhookUrl('not-a-url')).toThrow(HttpsError);
  });
});

describe('generateWebhookSecret', () => {
  it('generates a 256-bit (64 hex chars), unique secret every call', () => {
    const first = generateWebhookSecret();
    const second = generateWebhookSecret();
    expect(first).toHaveLength(64);
    expect(second).toHaveLength(64);
    expect(first).not.toBe(second);
  });
});

describe('signWebhookPayload / verifyWebhookSignature', () => {
  const secret = 'a-shared-secret';
  const rawBody = JSON.stringify({ eventId: 'evt-1', data: { foo: 'bar' } });

  it('produces a signature the consumer can validate with the same secret', () => {
    const signature = signWebhookPayload(secret, rawBody);
    expect(verifyWebhookSignature(secret, rawBody, signature)).toBe(true);
  });

  it('rejects a signature computed with the wrong secret', () => {
    const signature = signWebhookPayload('a-different-secret', rawBody);
    expect(verifyWebhookSignature(secret, rawBody, signature)).toBe(false);
  });

  it('rejects an adulterated payload signed under the original body', () => {
    const signature = signWebhookPayload(secret, rawBody);
    const adulteredBody = JSON.stringify({ eventId: 'evt-1', data: { foo: 'TAMPERED' } });
    expect(verifyWebhookSignature(secret, adulteredBody, signature)).toBe(false);
  });

  it('is deterministic for the exact same secret/body pair', () => {
    expect(signWebhookPayload(secret, rawBody)).toBe(signWebhookPayload(secret, rawBody));
  });
});

describe('computeWebhookEventId', () => {
  it('is deterministic for the exact same occurrence, so a redelivered '
    + 'event always carries the same eventId a consumer can dedupe by', () => {
    const input = {
      organizationId: 'org-1',
      eventType: 'order.created',
      entityId: 'order-1',
      sourceVersion: '1',
    };
    expect(computeWebhookEventId(input)).toBe(computeWebhookEventId({ ...input }));
  });

  it('changes when the organization changes, so two tenants never collide '
    + 'even for the exact same entity id', () => {
    const base = {
      eventType: 'order.created',
      entityId: 'order-1',
      sourceVersion: '1',
    };
    expect(computeWebhookEventId({ organizationId: 'org-1', ...base })).not.toBe(
      computeWebhookEventId({ organizationId: 'org-2', ...base }),
    );
  });

  it('changes when sourceVersion changes, so a real, later occurrence of '
    + 'the same entity is never mistaken for an already-delivered one', () => {
    const base = {
      organizationId: 'org-1',
      eventType: 'order.status_changed',
      entityId: 'order-1',
    };
    expect(computeWebhookEventId({ ...base, sourceVersion: '1:submitted' })).not.toBe(
      computeWebhookEventId({ ...base, sourceVersion: '1:approved' }),
    );
  });
});

describe('nextWebhookRetryDelayMinutes', () => {
  it('follows the 1min/5min/30min/2h schedule (TASK-170)', () => {
    expect(nextWebhookRetryDelayMinutes(1)).toBe(1);
    expect(nextWebhookRetryDelayMinutes(2)).toBe(5);
    expect(nextWebhookRetryDelayMinutes(3)).toBe(30);
    expect(nextWebhookRetryDelayMinutes(MAX_WEBHOOK_DELIVERY_ATTEMPTS)).toBe(120);
  });

  it('caps at the last (longest) backoff beyond the table length', () => {
    expect(nextWebhookRetryDelayMinutes(MAX_WEBHOOK_DELIVERY_ATTEMPTS + 10)).toBe(120);
  });
});
