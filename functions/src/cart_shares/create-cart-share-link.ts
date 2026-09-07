import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { loadActiveMembership } from '../invites/invite-shared';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { generateSecureToken } from '../shared/secure-token';
import { requireCartItems, requiredString } from './cart-share-shared';

export const createCartShareLink = onCall<RequestWithMeta & Record<string, unknown>>(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Authentication is required.');
  const organizationId = requiredString(request.data.organizationId, 'organizationId');
  const sourceCartId = requiredString(request.data.sourceCartId, 'sourceCartId');
  const sourceCartVersion = request.data.sourceCartVersion;
  if (!Number.isInteger(sourceCartVersion) || (sourceCartVersion as number) < 0) {
    throw new HttpsError('invalid-argument', 'sourceCartVersion is invalid.');
  }
  const items = requireCartItems(request.data.items);
  const db = getFirestore();
  await loadActiveMembership(db, organizationId, request.auth.uid);
  const organizationRef = db.collection('organizations').doc(organizationId);
  const organization = await organizationRef.get();
  const settings = organization.data()?.settings as Record<string, unknown> | undefined;
  const showPrices = settings?.allowCartSharePrices === true && request.data.showPrices === true;
  const { token, tokenHash } = generateSecureToken();
  const now = Timestamp.now();
  const expiresAt = Timestamp.fromMillis(now.toMillis() + 14 * 24 * 60 * 60 * 1000);
  const ref = organizationRef.collection('cartShares').doc();
  await ref.set({
    organizationId, sourceCartId, sourceCartVersion, items, showPrices, tokenHash,
    status: 'active', review: null, createdBy: request.auth.uid,
    createdAt: now, updatedAt: now, expiresAt,
  });
  return {
    shareId: ref.id, token, showPrices, expiresAt: expiresAt.toDate().toISOString(),
    correlationId: resolveCorrelationId(request.data._meta),
  };
});
