import { HttpsError } from 'firebase-functions/v2/https';
import { Timestamp, type DocumentData, type Firestore } from 'firebase-admin/firestore';

export type CartReviewDecision = 'approved' | 'changesRequested';

export function requiredString(value: unknown, field: string): string {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new HttpsError('invalid-argument', `${field} is required.`);
  }
  return value.trim();
}

export function requireCartItems(value: unknown): DocumentData[] {
  if (!Array.isArray(value) || value.length === 0 || value.length > 100) {
    throw new HttpsError('invalid-argument', 'items must contain between 1 and 100 variants.');
  }
  return value.map((raw, index) => {
    if (!raw || typeof raw !== 'object') {
      throw new HttpsError('invalid-argument', `items[${index}] is invalid.`);
    }
    const item = raw as Record<string, unknown>;
    const quantity = item.quantity;
    const unitPrice = item.unitPrice;
    if (!Number.isInteger(quantity) || (quantity as number) <= 0) {
      throw new HttpsError('invalid-argument', `items[${index}].quantity is invalid.`);
    }
    if (typeof unitPrice !== 'number' || !Number.isFinite(unitPrice) || unitPrice < 0) {
      throw new HttpsError('invalid-argument', `items[${index}].unitPrice is invalid.`);
    }
    return {
      itemId: requiredString(item.itemId, `items[${index}].itemId`),
      productId: requiredString(item.productId, `items[${index}].productId`),
      productName: requiredString(item.productName, `items[${index}].productName`),
      variantId: requiredString(item.variantId, `items[${index}].variantId`),
      quantity,
      unitPrice,
      subtotal: Math.round((quantity as number) * unitPrice * 100) / 100,
    };
  });
}

export async function findCartShare(db: Firestore, tokenHash: string) {
  const result = await db.collectionGroup('cartShares').where('tokenHash', '==', tokenHash).limit(1).get();
  if (result.empty) return null;
  const document = result.docs[0];
  const organizationRef = document.ref.parent.parent;
  if (!organizationRef) throw new HttpsError('internal', 'Cart share has no organization.');
  return { ref: document.ref, organizationRef, data: document.data() };
}

export function outcome(data: DocumentData, now: Timestamp): 'valid' | 'expired' | 'revoked' {
  if (data.status === 'revoked') return 'revoked';
  return (data.expiresAt as Timestamp).toMillis() <= now.toMillis() ? 'expired' : 'valid';
}

export function publicPreview(data: DocumentData, organizationName: string | null) {
  const showPrices = data.showPrices === true;
  const items = ((data.items as DocumentData[]) ?? []).map((item) => ({
    itemId: item.itemId,
    productName: item.productName,
    variantId: item.variantId,
    quantity: item.quantity,
    unitPrice: showPrices ? item.unitPrice : null,
    subtotal: showPrices ? item.subtotal : null,
  }));
  return {
    outcome: 'valid' as const,
    organizationName,
    showPrices,
    items,
    total: showPrices ? items.reduce((sum, item) => sum + (item.subtotal as number), 0) : null,
    review: data.review ?? null,
    expiresAt: (data.expiresAt as Timestamp).toDate().toISOString(),
  };
}
