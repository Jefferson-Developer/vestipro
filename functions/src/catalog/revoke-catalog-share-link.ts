import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import {
  SYSTEM_ROLE_RANK,
  loadActiveMembership,
} from '../invites/invite-shared';
import {
  requireNonEmptyString,
  serializeCatalogShare,
  type CatalogShareResponse,
} from './catalog-share-shared';

export interface RevokeCatalogShareLinkRequest extends RequestWithMeta {
  organizationId?: string;
  shareId?: string;
}

export interface RevokeCatalogShareLinkResponse {
  share: CatalogShareResponse;
  correlationId: string;
}

/** OWNER/ADMIN rank threshold (`SYSTEM_ROLE_RANK`) — an OWNER/ADMIN may
 * revoke any share in their organization, same oversight precedent
 * `revokeInvite` already sets for invites. */
const MAX_PRIVILEGED_RANK = SYSTEM_ROLE_RANK.ADMIN;

/**
 * Revokes an active `CatalogShare`, invalidating its link immediately
 * (TASK-081: "status (ativo, expirado, revogado)"). Only the share's own
 * creator, or an OWNER/ADMIN of the organization, may revoke it — mirrors
 * `revokeInvite`'s "issuer or privileged role" bar
 * (`functions/src/invites/revoke-invite.ts`), re-checked here from the
 * caller's real Membership, never from anything the client claims.
 *
 * Only an `'active'` share may be revoked — an already-revoked one is
 * rejected with `failed-precondition` instead of silently no-op'ing, same
 * "no false sense of having just done something" precedent as
 * `revokeInvite`. An already-expired share may still be revoked (harmless —
 * `resolveCatalogShareOutcome` already reports it as `'expired'` either
 * way, but recording the deliberate revocation keeps the audit trail
 * honest).
 */
export const revokeCatalogShareLink = onCall<
  RevokeCatalogShareLinkRequest,
  Promise<RevokeCatalogShareLinkResponse>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'É necessário estar autenticado para revogar um compartilhamento.',
    );
  }
  const uid = request.auth.uid;

  const organizationId = requireNonEmptyString(
    request.data?.organizationId,
    'organizationId',
  );
  const shareId = requireNonEmptyString(request.data?.shareId, 'shareId');

  const db = getFirestore();
  const organizationRef = db.collection('organizations').doc(organizationId);
  const shareRef = organizationRef.collection('catalogShares').doc(shareId);

  const membership = await loadActiveMembership(db, organizationId, uid);

  const shareSnapshot = await shareRef.get();
  const shareData = shareSnapshot.data();
  if (!shareSnapshot.exists || !shareData || shareData.organizationId !== organizationId) {
    throw new HttpsError('not-found', 'Compartilhamento não encontrado.');
  }

  const isOwnShare = shareData.createdBy === uid;
  const isPrivileged =
    (SYSTEM_ROLE_RANK[membership.roleName] ?? Number.MAX_SAFE_INTEGER) <=
    MAX_PRIVILEGED_RANK;
  if (!isOwnShare && !isPrivileged) {
    throw new HttpsError(
      'permission-denied',
      'Apenas quem criou o compartilhamento, ou um OWNER/ADMIN, pode revogá-lo.',
    );
  }

  if (shareData.status !== 'active') {
    throw new HttpsError(
      'failed-precondition',
      'Somente um compartilhamento ativo pode ser revogado.',
    );
  }

  const now = Timestamp.now();
  const updatedFields = { status: 'revoked' as const, updatedAt: now };
  await shareRef.update(updatedFields);

  logger.info('revokeCatalogShareLink succeeded', {
    correlationId,
    uid,
    organizationId,
    shareId,
  });

  return {
    share: serializeCatalogShare(shareId, { ...shareData, ...updatedFields }),
    correlationId,
  };
});
