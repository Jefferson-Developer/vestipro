import { logger } from 'firebase-functions/v2';
import { Timestamp, getFirestore } from 'firebase-admin/firestore';
import type { NextFunction, Request, RequestHandler, Response } from 'express';

import { hashSecureToken } from '../../shared/secure-token';
import {
  checkAndConsumeRateLimit,
  DEFAULT_API_KEY_RATE_LIMIT_PER_MINUTE,
  findApiKeyByHash,
  logApiUsage,
} from '../api-key-shared';
import type { ApiKeyScope } from '../types';

/**
 * Authenticated request context `authenticateApiKey` attaches to every
 * request that clears authentication + rate limiting — every route handler
 * under `public_api/rest/*` reads `req.apiKey!.organizationId` as the *only*
 * source of truth for which tenant a request is scoped to (TASK-171: "nunca
 * aceitar organizationId vindo do corpo/query da requisição como fonte de
 * verdade").
 */
export interface AuthenticatedApiKey {
  keyId: string;
  organizationId: string;
  scopes: ApiKeyScope[];
  rateLimitPerMinute: number;
}

declare module 'express-serve-static-core' {
  interface Request {
    apiKey?: AuthenticatedApiKey;
  }
}

const API_KEY_HEADER = 'x-api-key';

export function sendApiError(
  res: Response,
  status: number,
  code: string,
  message: string,
): void {
  res.status(status).json({ error: { code, message } });
}

/** Wraps an async Express handler so a rejected promise is forwarded to
 * `next(error)` instead of crashing the process/hanging the response —
 * Express 4 does not do this automatically for `async` handlers. */
export function asyncHandler(
  handler: (req: Request, res: Response) => Promise<void>,
): RequestHandler {
  return (req, res, next) => {
    handler(req, res).catch(next);
  };
}

/**
 * Resolves the caller's `X-Api-Key` header into an {@link AuthenticatedApiKey}
 * (TASK-171): looks up the key by its hash (`findApiKeyByHash`, never trusts
 * anything the request itself claims about which organization it belongs
 * to), rejects an unknown/revoked key, then atomically checks-and-consumes
 * this minute's rate-limit budget (`checkAndConsumeRateLimit`) — every
 * response, allowed or not, always carries the standardized
 * `X-RateLimit-*` headers (TASK-171: "headers de limite restante"). Usage is
 * logged exactly once per request, on `res.on('finish')`, so the recorded
 * `statusCode`/`latencyMs` always reflects what the caller actually
 * received, including from a downstream route handler's own error path.
 */
export async function authenticateApiKey(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  const startedAt = Date.now();
  const rawKey = req.header(API_KEY_HEADER);
  if (!rawKey || rawKey.trim().length === 0) {
    sendApiError(res, 401, 'unauthenticated', 'Cabeçalho X-Api-Key é obrigatório.');
    return;
  }

  const db = getFirestore();
  const tokenHash = hashSecureToken(rawKey.trim());
  const lookup = await findApiKeyByHash(db, tokenHash);
  if (!lookup || lookup.data.status !== 'active') {
    sendApiError(res, 401, 'unauthenticated', 'API key inválida ou revogada.');
    return;
  }

  const organizationId = lookup.data.organizationId as string;
  const keyId = lookup.ref.id;
  const scopes: ApiKeyScope[] = Array.isArray(lookup.data.scopes)
    ? (lookup.data.scopes as ApiKeyScope[])
    : [];
  const rateLimitPerMinute =
    typeof lookup.data.rateLimitPerMinute === 'number'
      ? lookup.data.rateLimitPerMinute
      : DEFAULT_API_KEY_RATE_LIMIT_PER_MINUTE;

  const rateLimit = await checkAndConsumeRateLimit(
    db,
    organizationId,
    keyId,
    rateLimitPerMinute,
  );
  res.setHeader('X-RateLimit-Limit', String(rateLimit.limit));
  res.setHeader('X-RateLimit-Remaining', String(rateLimit.remaining));
  res.setHeader('X-RateLimit-Reset', rateLimit.resetAt.toISOString());

  res.on('finish', () => {
    logApiUsage(db, organizationId, {
      keyId,
      method: req.method,
      path: req.path,
      statusCode: res.statusCode,
      latencyMs: Date.now() - startedAt,
    }).catch((error) => {
      logger.error('logApiUsage failed', { error, keyId, organizationId });
    });
  });

  if (!rateLimit.allowed) {
    sendApiError(res, 429, 'rate_limited', 'Limite de requisições excedido para esta chave.');
    return;
  }

  req.apiKey = { keyId, organizationId, scopes, rateLimitPerMinute };

  // Fire-and-forget: `lastUsedAt` is a diagnostic field only, never read by
  // any authorization decision — worth updating even if this specific write
  // races with a concurrent request from the same key.
  lookup.ref.set({ lastUsedAt: Timestamp.now() }, { merge: true }).catch((error) => {
    logger.error('apiKeys.lastUsedAt update failed', { error, keyId, organizationId });
  });

  next();
}

/** Route-level guard requiring [scope] to be one of the resolved key's
 * granted scopes (TASK-171: escopos por chave) — always runs after
 * {@link authenticateApiKey}, never standalone. */
export function requireScope(scope: ApiKeyScope): RequestHandler {
  return (req, res, next) => {
    if (!req.apiKey?.scopes.includes(scope)) {
      sendApiError(
        res,
        403,
        'permission-denied',
        `Esta API key não tem o escopo "${scope}".`,
      );
      return;
    }
    next();
  };
}
