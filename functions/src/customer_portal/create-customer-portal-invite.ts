import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { loadActiveMembership, requireNonEmptyString, requireValidEmail } from '../invites/invite-shared';
import { newPortalToken, PORTAL_INVITER_ROLES, portalInviteExpiresAt } from './customer-portal-shared';

export const createCustomerPortalInvite = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Autenticação obrigatória.');
  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const customerId = requireNonEmptyString(request.data?.customerId, 'customerId');
  const email = requireValidEmail(request.data?.email);
  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, request.auth.uid);
  if (!PORTAL_INVITER_ROLES.has(membership.roleName)) {
    throw new HttpsError('permission-denied', 'Usuário não pode provisionar clientes.');
  }
  const customer = await db.doc(`organizations/${organizationId}/customers/${customerId}`).get();
  if (!customer.exists || customer.data()?.status !== 'active') {
    throw new HttpsError('failed-precondition', 'Cliente não está ativo.');
  }
  if (membership.roleName === 'SALES_REP' && customer.data()?.primarySalesRepId !== request.auth.uid) {
    throw new HttpsError('permission-denied', 'Cliente não pertence à carteira do vendedor.');
  }
  const now = Timestamp.now();
  const { token, tokenHash } = newPortalToken();
  const ref = db.collection(`organizations/${organizationId}/customerPortalInvites`).doc();
  await ref.set({
    organizationId, customerId, email, tokenHash, status: 'pending',
    invitedByUserId: request.auth.uid, createdAt: now,
    expiresAt: portalInviteExpiresAt(now),
  });
  return { inviteId: ref.id, token, organizationId, customerId };
});
