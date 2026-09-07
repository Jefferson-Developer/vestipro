import { Timestamp } from 'firebase-admin/firestore';
import { newPortalToken, portalInviteExpiresAt, portalTokenHash } from '../../src/customer_portal/customer-portal-shared';
import { revalidatePortalLine } from '../../src/customer_portal/repeat-customer-portal-order';

describe('customer portal provisioning (TASK-182)', () => {
  it('persists only a stable hash and uses a seven-day expiration', () => {
    const generated = newPortalToken();
    expect(generated.token).not.toBe(generated.tokenHash);
    expect(portalTokenHash(generated.token)).toBe(generated.tokenHash);
    const now = Timestamp.fromMillis(1_000);
    expect(portalInviteExpiresAt(now).toMillis() - now.toMillis()).toBe(7 * 24 * 60 * 60 * 1000);
  });

  it('repeats with current price and caps quantity at current stock', () => {
    const result = revalidatePortalLine(
      { productId: 'p1', variantId: 'v1', quantity: 8, unitPrice: 99 },
      125,
      3,
    );
    expect(result).toMatchObject({ quantity: 3, unitPrice: 125, subtotal: 375 });
    expect(revalidatePortalLine({ quantity: 2 }, 125, 0)).toBeNull();
  });
});
