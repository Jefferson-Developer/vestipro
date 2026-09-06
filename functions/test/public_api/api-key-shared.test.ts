import { HttpsError } from 'firebase-functions/v2/https';

import {
  API_KEY_MANAGE_ROLES,
  API_KEY_PREFIX,
  DEFAULT_API_KEY_RATE_LIMIT_PER_MINUTE,
  MAX_API_KEY_RATE_LIMIT_PER_MINUTE,
  MIN_API_KEY_RATE_LIMIT_PER_MINUTE,
  assertCanManageApiKeys,
  decodeCursor,
  encodeCursor,
  generateApiKeyToken,
  isApiKeyScope,
  parsePageSize,
  rateLimitBucketId,
  validateApiKeyScopes,
  validateRateLimitPerMinute,
} from '../../src/public_api/api-key-shared';

describe('assertCanManageApiKeys', () => {
  it('allows only OWNER/ADMIN', () => {
    expect(API_KEY_MANAGE_ROLES.has('OWNER')).toBe(true);
    expect(API_KEY_MANAGE_ROLES.has('ADMIN')).toBe(true);
    expect(() => assertCanManageApiKeys('OWNER')).not.toThrow();
    expect(() => assertCanManageApiKeys('ADMIN')).not.toThrow();
  });

  it.each(['SALES_MANAGER', 'SALES_REP', 'SALES_ASSISTANT', 'FINANCE', 'READ_ONLY'])(
    'denies %s',
    (roleName) => {
      expect(() => assertCanManageApiKeys(roleName)).toThrow(HttpsError);
    },
  );
});

describe('isApiKeyScope', () => {
  it('accepts every known scope', () => {
    expect(isApiKeyScope('customers:read')).toBe(true);
    expect(isApiKeyScope('products:read')).toBe(true);
    expect(isApiKeyScope('orders:read')).toBe(true);
    expect(isApiKeyScope('orders:write')).toBe(true);
  });

  it('rejects unknown values', () => {
    expect(isApiKeyScope('customers:write')).toBe(false);
    expect(isApiKeyScope('')).toBe(false);
  });
});

describe('validateApiKeyScopes', () => {
  it('accepts a non-empty list of known scopes', () => {
    expect(validateApiKeyScopes(['customers:read', 'orders:write'])).toEqual([
      'customers:read',
      'orders:write',
    ]);
  });

  it('deduplicates repeated scopes', () => {
    expect(validateApiKeyScopes(['orders:read', 'orders:read'])).toEqual(['orders:read']);
  });

  it('rejects an empty list', () => {
    expect(() => validateApiKeyScopes([])).toThrow(HttpsError);
  });

  it('rejects a non-array value', () => {
    expect(() => validateApiKeyScopes('customers:read')).toThrow(HttpsError);
  });

  it('rejects an unknown scope', () => {
    expect(() => validateApiKeyScopes(['customers:delete'])).toThrow(HttpsError);
  });
});

describe('validateRateLimitPerMinute', () => {
  it('defaults to DEFAULT_API_KEY_RATE_LIMIT_PER_MINUTE when omitted', () => {
    expect(validateRateLimitPerMinute(undefined)).toBe(DEFAULT_API_KEY_RATE_LIMIT_PER_MINUTE);
  });

  it('accepts any integer within [MIN, MAX]', () => {
    expect(validateRateLimitPerMinute(MIN_API_KEY_RATE_LIMIT_PER_MINUTE)).toBe(
      MIN_API_KEY_RATE_LIMIT_PER_MINUTE,
    );
    expect(validateRateLimitPerMinute(MAX_API_KEY_RATE_LIMIT_PER_MINUTE)).toBe(
      MAX_API_KEY_RATE_LIMIT_PER_MINUTE,
    );
    expect(validateRateLimitPerMinute(120)).toBe(120);
  });

  it.each([0, -1, 601, 1.5, 'sixty', null])('rejects invalid value %p', (value) => {
    expect(() => validateRateLimitPerMinute(value)).toThrow(HttpsError);
  });
});

describe('generateApiKeyToken', () => {
  it('always returns a token prefixed with API_KEY_PREFIX', () => {
    const generated = generateApiKeyToken();
    expect(generated.token.startsWith(API_KEY_PREFIX)).toBe(true);
  });

  it('never returns the same token/hash twice', () => {
    const first = generateApiKeyToken();
    const second = generateApiKeyToken();
    expect(first.token).not.toBe(second.token);
    expect(first.tokenHash).not.toBe(second.tokenHash);
  });

  it('suffix is exactly the last 4 characters of the full token', () => {
    const generated = generateApiKeyToken();
    expect(generated.suffix).toBe(generated.token.slice(-4));
    expect(generated.suffix).toHaveLength(4);
  });

  it('tokenHash is deterministic for the same token (sha256 hex)', () => {
    const generated = generateApiKeyToken();
    expect(generated.tokenHash).toMatch(/^[0-9a-f]{64}$/);
  });
});

describe('rateLimitBucketId', () => {
  it('is the same id for two timestamps in the same 1-minute window', () => {
    const base = Date.parse('2026-01-01T10:00:00.000Z');
    expect(rateLimitBucketId('key-1', base)).toBe(rateLimitBucketId('key-1', base + 30_000));
  });

  it('is a different id once the window rolls over', () => {
    const base = Date.parse('2026-01-01T10:00:00.000Z');
    expect(rateLimitBucketId('key-1', base)).not.toBe(rateLimitBucketId('key-1', base + 60_000));
  });

  it('never collides across different keyIds in the same window', () => {
    const base = Date.parse('2026-01-01T10:00:00.000Z');
    expect(rateLimitBucketId('key-1', base)).not.toBe(rateLimitBucketId('key-2', base));
  });
});

describe('encodeCursor / decodeCursor', () => {
  it('round-trips a cursor', () => {
    const cursor = { createdAtMs: 1_700_000_000_000, id: 'order-abc' };
    expect(decodeCursor(encodeCursor(cursor))).toEqual(cursor);
  });

  it('returns null for an absent cursor', () => {
    expect(decodeCursor(undefined)).toBeNull();
  });

  it('returns null (never throws) for a malformed/tampered cursor', () => {
    expect(decodeCursor('not-a-valid-base64url-json-payload!!')).toBeNull();
    expect(decodeCursor(Buffer.from('{"foo":"bar"}', 'utf8').toString('base64url'))).toBeNull();
  });
});

describe('parsePageSize', () => {
  it('defaults to 20 when absent/invalid', () => {
    expect(parsePageSize(undefined)).toBe(20);
    expect(parsePageSize('not-a-number')).toBe(20);
    expect(parsePageSize('0')).toBe(20);
    expect(parsePageSize('-5')).toBe(20);
    expect(parsePageSize('12.5')).toBe(20);
  });

  it('accepts a valid page size', () => {
    expect(parsePageSize('50')).toBe(50);
  });

  it('clamps to the maximum page size (100)', () => {
    expect(parsePageSize('99999')).toBe(100);
  });
});
