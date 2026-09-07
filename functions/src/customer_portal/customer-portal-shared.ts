import { createHash, randomBytes } from 'node:crypto';
import { HttpsError } from 'firebase-functions/v2/https';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';

export const CUSTOMER_PORTAL_ROLE = 'CUSTOMER_PORTAL';
export const PORTAL_INVITER_ROLES = new Set([
  'OWNER', 'ADMIN', 'SALES_MANAGER', 'SALES_REP',
]);

export function portalTokenHash(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}

export function newPortalToken(): { token: string; tokenHash: string } {
  const token = randomBytes(32).toString('base64url');
  return { token, tokenHash: portalTokenHash(token) };
}

export async function requirePortalMembership(
  organizationId: string,
  uid: string,
): Promise<{ customerId: string }> {
  const snapshot = await getFirestore()
    .doc(`organizations/${organizationId}/members/${uid}`)
    .get();
  const data = snapshot.data();
  if (!snapshot.exists || data?.status !== 'active' ||
      data.roleName !== CUSTOMER_PORTAL_ROLE ||
      typeof data.customerId !== 'string' || data.customerId.length === 0) {
    throw new HttpsError('permission-denied', 'Acesso de cliente inválido.');
  }
  return { customerId: data.customerId };
}

export function portalInviteExpiresAt(now: Timestamp): Timestamp {
  return Timestamp.fromMillis(now.toMillis() + 7 * 24 * 60 * 60 * 1000);
}
