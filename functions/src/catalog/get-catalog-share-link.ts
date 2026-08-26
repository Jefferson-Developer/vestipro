import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { hashSecureToken } from '../shared/secure-token';
import {
  findCatalogShareByTokenHash,
  requireNonEmptyString,
  resolveCatalogShareOutcome,
  serializeCatalogSharePreview,
  type CatalogSharePreviewResponse,
} from './catalog-share-shared';

export interface GetCatalogShareLinkRequest extends RequestWithMeta {
  token?: string;
}

export interface GetCatalogShareLinkResponse extends CatalogSharePreviewResponse {
  correlationId: string;
}

/**
 * Looks up the `CatalogShare` behind [GetCatalogShareLinkRequest.token] and
 * reports what the public `CatalogSharePublicPage` (TASK-081, Flutter) should
 * show — same "never throw for an ordinary outcome" contract as
 * `invites/validate-invite.ts`'s `validateInvite`: `'notFound'`/`'expired'`/
 * `'revoked'` are everyday outcomes of opening a link, not exceptional
 * server conditions. `HttpsError` is only used for a genuinely malformed
 * request (`token` missing).
 *
 * Callable without authentication ([request.auth] is never checked) — the
 * whole point of a catalog share link is working for a customer who never
 * signs in at all (TASK-081: "sem exigir login do cliente").
 *
 * Only [serializeCatalogSharePreview]'s restricted view ever leaves this
 * Function — no `id`/`organizationId`/`createdBy`/`tokenHash`/open-count is
 * ever returned to an anonymous caller, and nothing is returned at all
 * (`items`/`scope`/`collectionName` stay absent) once [outcome] is not
 * `'valid'`, so an expired/revoked link never leaks what it used to expose.
 */
export const getCatalogShareLink = onCall<
  GetCatalogShareLinkRequest,
  Promise<GetCatalogShareLinkResponse>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);
  const token = requireNonEmptyString(request.data?.token, 'token');
  const tokenHash = hashSecureToken(token);

  const db = getFirestore();
  const lookup = await findCatalogShareByTokenHash(db, tokenHash);

  if (!lookup) {
    logger.info('getCatalogShareLink: token not found', { correlationId });
    return {
      outcome: 'notFound',
      organizationName: null,
      scope: null,
      items: [],
      collectionName: null,
      expiresAt: null,
      correlationId,
    };
  }

  const now = Timestamp.now();
  const outcome = resolveCatalogShareOutcome(lookup.data, now);

  if (outcome !== 'valid') {
    logger.info('getCatalogShareLink succeeded', {
      correlationId,
      organizationId: lookup.organizationRef.id,
      outcome,
    });
    return {
      outcome,
      organizationName: null,
      scope: null,
      items: [],
      collectionName: null,
      expiresAt: null,
      correlationId,
    };
  }

  const organizationSnapshot = await lookup.organizationRef.get();
  const organizationName =
    (organizationSnapshot.data()?.name as string | undefined) ?? null;

  logger.info('getCatalogShareLink succeeded', {
    correlationId,
    organizationId: lookup.organizationRef.id,
    outcome,
  });

  return {
    ...serializeCatalogSharePreview(outcome, organizationName, lookup.data),
    correlationId,
  };
});
