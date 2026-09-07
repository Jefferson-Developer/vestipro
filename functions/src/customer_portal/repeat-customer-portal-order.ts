import { getFirestore } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { requireNonEmptyString } from '../invites/invite-shared';
import { requirePortalMembership } from './customer-portal-shared';

export interface PortalRepeatItem {
  productId: string;
  variantId: string;
  quantity: number;
  unitPrice: number;
  subtotal: number;
}

export function revalidatePortalLine(
  source: Record<string, unknown>,
  currentUnitPrice: number,
  currentAvailable: number,
): PortalRepeatItem | null {
  const requested = Number(source.quantity ?? 0);
  if (currentUnitPrice < 0 || currentAvailable <= 0 || requested <= 0) return null;
  const quantity = Math.min(requested, currentAvailable);
  return {
    productId: String(source.productId ?? ''),
    variantId: String(source.variantId ?? ''),
    quantity,
    unitPrice: currentUnitPrice,
    subtotal: quantity * currentUnitPrice,
  };
}

export const repeatCustomerPortalOrder = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Autenticação obrigatória.');
  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const orderId = requireNonEmptyString(request.data?.orderId, 'orderId');
  const { customerId } = await requirePortalMembership(organizationId, request.auth.uid);
  const db = getFirestore();
  const order = await db.doc(`organizations/${organizationId}/orders/${orderId}`).get();
  if (!order.exists || order.data()?.customerId !== customerId) {
    throw new HttpsError('permission-denied', 'Pedido não pertence ao cliente autenticado.');
  }
  const priceListId = String(order.data()?.priceListId ?? '');
  const sourceItems = Array.isArray(order.data()?.items) ? order.data()!.items : [];
  const items = [];
  for (const source of sourceItems) {
    const variantId = String(source.variantId ?? '');
    const [prices, inventory] = await Promise.all([
      db.collection(`organizations/${organizationId}/priceLists/${priceListId}/items`).where('variantId', '==', variantId).limit(1).get(),
      db.collection(`organizations/${organizationId}/inventory`).where('variantId', '==', variantId).get(),
    ]);
    const available = inventory.docs.reduce((sum, balance) => sum + Math.max(0,
      Number(balance.data().physicalQuantity ?? 0) -
      Number(balance.data().reservedQuantity ?? 0) -
      Number(balance.data().blockedQuantity ?? 0)), 0);
    if (prices.empty) continue;
    const unitPrice = Number(prices.docs[0].data().price ?? 0);
    const revalidated = revalidatePortalLine(source, unitPrice, available);
    if (revalidated) items.push(revalidated);
  }
  return { sourceOrderId: orderId, priceListId, items, revalidatedAt: new Date().toISOString() };
});
