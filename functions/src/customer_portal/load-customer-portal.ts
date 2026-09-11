import { getFirestore } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { requireNonEmptyString } from '../invites/invite-shared';
import { requirePortalMembership } from './customer-portal-shared';

export const loadCustomerPortal = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Autenticação obrigatória.');
  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const { customerId } = await requirePortalMembership(organizationId, request.auth.uid);
  const db = getFirestore();
  const [organization, products, orders, shipments] = await Promise.all([
    db.doc(`organizations/${organizationId}`).get(),
    db.collection(`organizations/${organizationId}/products`).where('status', '==', 'active').limit(50).get(),
    db.collection(`organizations/${organizationId}/orders`).where('customerId', '==', customerId).orderBy('createdAt', 'desc').limit(50).get(),
    // TASK-214: "Cliente acompanha tracking no portal sem expor dados de
    // outros clientes" — scoped server-side (Admin SDK) by this same
    // portal's own `customerId`, exactly like `orders` above; the client
    // never receives another customer's shipment.
    db.collection(`organizations/${organizationId}/shipments`).where('customerId', '==', customerId).get(),
  ]);
  const settings = organization.data()?.settings ?? {};
  const latestShipmentByOrderId = new Map<string, FirebaseFirestore.DocumentData>();
  for (const doc of shipments.docs) {
    const data = doc.data();
    const orderId = data.orderId as string | undefined;
    if (!orderId) continue;
    const existing = latestShipmentByOrderId.get(orderId);
    const createdAt = data.createdAt?.toMillis?.() ?? 0;
    const existingCreatedAt = existing?.createdAt?.toMillis?.() ?? -1;
    if (!existing || createdAt >= existingCreatedAt) {
      latestShipmentByOrderId.set(orderId, data);
    }
  }
  return {
    organizationId, customerId,
    branding: { name: organization.data()?.name ?? 'Catálogo', logoUrl: settings.brandingLogoUrl ?? null, primaryColorHex: settings.brandingPrimaryColorHex ?? null },
    products: products.docs.map((doc) => ({ id: doc.id, name: doc.data().name ?? '', imageUrl: doc.data().imageUrl ?? null })),
    orders: orders.docs.map((doc) => {
      const shipment = latestShipmentByOrderId.get(doc.id);
      return {
        id: doc.id,
        orderNumber: doc.data().orderNumber ?? '',
        status: doc.data().status ?? '',
        total: doc.data().total ?? 0,
        createdAt: doc.data().createdAt?.toDate().toISOString() ?? null,
        shipmentStatus: shipment?.status ?? null,
        hasOpenLogisticsIssue: shipment?.hasOpenIssue ?? false,
        estimatedDeliveryDate: shipment?.estimatedDeliveryDate?.toDate().toISOString() ?? null,
      };
    }),
  };
});
