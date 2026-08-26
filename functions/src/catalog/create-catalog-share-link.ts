import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';
import { getFirestore, Timestamp, type DocumentData } from 'firebase-admin/firestore';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { generateSecureToken } from '../shared/secure-token';
import { loadActiveMembership, resolveActorName } from '../invites/invite-shared';
import {
  requireItems,
  requireNonEmptyString,
  requireScope,
  resolveExpiration,
  serializeCatalogShare,
  type CatalogShareResponse,
} from './catalog-share-shared';

export interface CreateCatalogShareLinkRequest extends RequestWithMeta {
  organizationId?: string;
  scope?: string;
  items?: unknown;
  collectionId?: string;
  collectionName?: string;
  expiresInDays?: number;
}

export interface CreateCatalogShareLinkResponse {
  share: CatalogShareResponse;
  /**
   * The plaintext share token, returned exactly once. Reading the share back
   * later (`listMyCatalogShares`-style reads, gated by `firestore.rules` to
   * the creator/an OWNER-ADMIN) never recovers this value — same restraint
   * as `createInvite`'s own `token` field.
   */
  token: string;
  correlationId: string;
}

/**
 * Creates a `CatalogShare` (TASK-081, EPIC-10) that lets a signed-in,
 * active member of [CreateCatalogShareLinkRequest.organizationId] share a
 * single product, a hand-picked selection or a collection with a customer
 * through a link — a token generated here, server-side, with
 * `crypto.randomBytes` (`generateSecureToken`), never on the client
 * (`AGENTS.md`: "nunca confiar apenas no organizationId vindo do cliente
 * como autorização"; TASK-081: "nunca gerar o link/token no cliente").
 *
 * Any active member may create a share — there is no dedicated
 * `Capability` for viewing/sharing the catalog itself (unlike
 * `catalog.manage`, which gates *editing* products/collections/campaigns),
 * mirroring the same "active membership is enough" bar TASK-079's
 * `favorites` already sets for a personal, read-only catalog interaction.
 *
 * Only the SHA-256 hash of the token (`tokenHash`) is ever persisted;
 * `getCatalogShareLink`/`registerCatalogShareOpen` are the only Functions
 * that ever look a share up again, both by re-hashing whatever the caller
 * presents.
 */
export const createCatalogShareLink = onCall<
  CreateCatalogShareLinkRequest,
  Promise<CreateCatalogShareLinkResponse>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'É necessário estar autenticado para compartilhar o catálogo.',
    );
  }
  const uid = request.auth.uid;

  const organizationId = requireNonEmptyString(
    request.data?.organizationId,
    'organizationId',
  );
  const scope = requireScope(request.data?.scope);
  const items = requireItems(request.data?.items, scope);
  const collectionId =
    scope === 'collection'
      ? requireNonEmptyString(request.data?.collectionId, 'collectionId')
      : null;
  const collectionName =
    scope === 'collection'
      ? requireNonEmptyString(request.data?.collectionName, 'collectionName')
      : null;

  const db = getFirestore();
  await loadActiveMembership(db, organizationId, uid);

  const actorName = await resolveActorName(db, uid, request.auth.token);
  const { token, tokenHash } = generateSecureToken();
  const now = Timestamp.now();
  const expiresAt = resolveExpiration(now, request.data?.expiresInDays);
  const shareRef = db
    .collection('organizations')
    .doc(organizationId)
    .collection('catalogShares')
    .doc();

  const shareData: DocumentData = {
    organizationId,
    scope,
    items,
    collectionId,
    collectionName,
    tokenHash,
    status: 'active',
    openCount: 0,
    firstOpenedAt: null,
    lastOpenedAt: null,
    expiresAt,
    createdBy: uid,
    createdByName: actorName,
    createdAt: now,
    updatedAt: now,
  };

  await shareRef.set(shareData);

  logger.info('createCatalogShareLink succeeded', {
    correlationId,
    uid,
    organizationId,
    shareId: shareRef.id,
    scope,
    itemCount: items.length,
  });

  return {
    share: serializeCatalogShare(shareRef.id, shareData),
    token,
    correlationId,
  };
});
