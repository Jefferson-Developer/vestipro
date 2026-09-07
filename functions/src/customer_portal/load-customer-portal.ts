import { getFirestore } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { requireNonEmptyString } from '../invites/invite-shared';
import { requirePortalMembership } from './customer-portal-shared';

export const loadCustomerPortal = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Autenticação obrigatória.');
  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const { customerId } = await requirePortalMembership(organizationId, request.auth.uid);
  const db = getFirestore();
  const [organization, products, orders] = await Promise.all([
    db.doc(`organizations/${organizationId}`).get(),
    db.collection(`organizations/${organizationId}/products`).where('status', '==', 'active').limit(50).get(),
    db.collection(`organizations/${organizationId}/orders`).where('customerId', '==', customerId).orderBy('createdAt', 'desc').limit(50).get(),
  ]);
  const settings = organization.data()?.settings ?? {};
  return {
    organizationId, customerId,
    branding: { name: organization.data()?.name ?? 'Catálogo', logoUrl: settings.brandingLogoUrl ?? null, primaryColorHex: settings.brandingPrimaryColorHex ?? null },
    products: products.docs.map((doc) => ({ id: doc.id, name: doc.data().name ?? '', imageUrl: doc.data().imageUrl ?? null })),
    orders: orders.docs.map((doc) => ({ id: doc.id, orderNumber: doc.data().orderNumber ?? '', status: doc.data().status ?? '', total: doc.data().total ?? 0, createdAt: doc.data().createdAt?.toDate().toISOString() ?? null })),
  };
});
