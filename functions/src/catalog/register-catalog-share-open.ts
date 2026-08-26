import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { hashSecureToken } from '../shared/secure-token';
import {
  findCatalogShareByTokenHash,
  requireNonEmptyString,
  resolveCatalogShareOutcome,
} from './catalog-share-shared';

export interface RegisterCatalogShareOpenRequest extends RequestWithMeta {
  token?: string;
}

export interface RegisterCatalogShareOpenResponse {
  /**
   * `true` only when the open was actually recorded (a matching, currently
   * valid share was found and its counters updated). `CatalogSharePublicPage`
   * never acts on this value — see the Function's own doc for why.
   */
  recorded: boolean;
  correlationId: string;
}

/**
 * Best-effort counter for "the recipient actually opened this link"
 * (TASK-081: "contador de aberturas... vendedor consegue ver... se e quando
 * o link foi aberto"). Called once by `CatalogSharePublicPage` right after
 * `getCatalogShareLink` reports `outcome: 'valid'` — deliberately a
 * *separate* call from that lookup, never combined into one, so a failure
 * here (network blip, a transient Firestore error, a share that expired in
 * the few seconds between the two calls) can never affect whether the
 * visitor already sees the shared products; the caller is expected to
 * invoke this without awaiting/blocking on its result.
 *
 * Never throws: unlike every other Function in this feature, even a
 * malformed/missing `token` degrades to `{ recorded: false }` instead of an
 * `HttpsError` — nothing about "did the open counter update" should ever be
 * capable of surfacing an error to a customer who is only here to look at a
 * catalog (TASK-081: "nunca deve bloquear o acesso do destinatário em caso
 * de falha no registro").
 */
export const registerCatalogShareOpen = onCall<
  RegisterCatalogShareOpenRequest,
  Promise<RegisterCatalogShareOpenResponse>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);

  try {
    const token = requireNonEmptyString(request.data?.token, 'token');
    const tokenHash = hashSecureToken(token);

    const db = getFirestore();
    const lookup = await findCatalogShareByTokenHash(db, tokenHash);
    if (!lookup) {
      return { recorded: false, correlationId };
    }

    const now = Timestamp.now();
    const outcome = resolveCatalogShareOutcome(lookup.data, now);
    if (outcome !== 'valid') {
      return { recorded: false, correlationId };
    }

    const alreadyOpened = lookup.data.firstOpenedAt != null;
    await lookup.ref.update({
      openCount: ((lookup.data.openCount as number | undefined) ?? 0) + 1,
      firstOpenedAt: alreadyOpened ? lookup.data.firstOpenedAt : now,
      lastOpenedAt: now,
      updatedAt: now,
    });

    logger.info('registerCatalogShareOpen succeeded', {
      correlationId,
      organizationId: lookup.organizationRef.id,
      shareId: lookup.ref.id,
    });
    return { recorded: true, correlationId };
  } catch (error) {
    logger.warn('registerCatalogShareOpen: best-effort recording failed', {
      correlationId,
      error: error instanceof Error ? error.message : String(error),
    });
    return { recorded: false, correlationId };
  }
});
