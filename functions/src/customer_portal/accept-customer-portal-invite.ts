import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { requireNonEmptyString } from '../invites/invite-shared';
import { CUSTOMER_PORTAL_ROLE, portalTokenHash } from './customer-portal-shared';

export const acceptCustomerPortalInvite = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Crie sua conta ou entre para aceitar.');
  const token = requireNonEmptyString(request.data?.token, 'token');
  const email = String(request.auth.token.email ?? '').toLowerCase();
  const db = getFirestore();
  const query = db.collectionGroup('customerPortalInvites')
    .where('tokenHash', '==', portalTokenHash(token)).limit(1);
  const result = await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(query);
    if (snapshot.empty) throw new HttpsError('not-found', 'Convite não encontrado.');
    const invite = snapshot.docs[0];
    const data = invite.data();
    if (data.status !== 'pending' || data.expiresAt.toMillis() <= Date.now()) {
      throw new HttpsError('failed-precondition', 'Convite expirado ou já utilizado.');
    }
    if (email !== String(data.email).toLowerCase()) {
      throw new HttpsError('permission-denied', 'Convite emitido para outro e-mail.');
    }
    const memberRef = db.doc(`organizations/${data.organizationId}/members/${request.auth!.uid}`);
    const now = Timestamp.now();
    transaction.set(memberRef, {
      organizationId: data.organizationId, userId: request.auth!.uid,
      roleId: CUSTOMER_PORTAL_ROLE, roleName: CUSTOMER_PORTAL_ROLE,
      customerId: data.customerId, email, status: 'active', teamIds: [],
      version: 1, createdAt: now, createdBy: data.invitedByUserId,
      updatedAt: now, updatedBy: request.auth!.uid, deletedAt: null,
    });
    transaction.update(invite.ref, { status: 'accepted', acceptedAt: now });
    return { organizationId: data.organizationId, customerId: data.customerId, roleName: CUSTOMER_PORTAL_ROLE };
  });
  return result;
});
