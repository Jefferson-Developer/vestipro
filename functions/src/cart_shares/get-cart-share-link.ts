import { onCall } from 'firebase-functions/v2/https';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { hashSecureToken } from '../shared/secure-token';
import { findCartShare, outcome, publicPreview, requiredString } from './cart-share-shared';

export const getCartShareLink = onCall<RequestWithMeta & { token?: string }>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);
  const tokenHash = hashSecureToken(requiredString(request.data?.token, 'token'));
  const found = await findCartShare(getFirestore(), tokenHash);
  if (!found) return { outcome: 'notFound', items: [], correlationId };
  const result = outcome(found.data, Timestamp.now());
  if (result !== 'valid') return { outcome: result, items: [], correlationId };
  const organization = await found.organizationRef.get();
  return { ...publicPreview(found.data, (organization.data()?.name as string | undefined) ?? null), correlationId };
});
