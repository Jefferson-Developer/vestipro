import { Timestamp } from 'firebase-admin/firestore';
import { outcome, publicPreview, requireCartItems } from '../../src/cart_shares/cart-share-shared';

describe('cart share validation and public scope (TASK-181)', () => {
  const now = Timestamp.fromMillis(1_000);
  const item = {
    itemId: 'line-1', productId: 'product-1', productName: 'Camisa',
    variantId: 'blue-m', quantity: 2, unitPrice: 50,
  };

  it('captures quantities and computes the subtotal', () => {
    expect(requireCartItems([item])).toEqual([{ ...item, subtotal: 100 }]);
    expect(() => requireCartItems([{ ...item, quantity: 0 }])).toThrow();
  });

  it('never exposes prices when the organization disabled them', () => {
    const preview = publicPreview({
      items: [{ ...item, subtotal: 100 }], showPrices: false,
      expiresAt: Timestamp.fromMillis(2_000),
    }, 'Moda Ltda');
    expect(preview.items[0].unitPrice).toBeNull();
    expect(preview.items[0].subtotal).toBeNull();
    expect(preview.total).toBeNull();
  });

  it('resolves expiration server-side', () => {
    expect(outcome({ status: 'active', expiresAt: Timestamp.fromMillis(999) }, now)).toBe('expired');
    expect(outcome({ status: 'active', expiresAt: Timestamp.fromMillis(1_001) }, now)).toBe('valid');
  });
});
