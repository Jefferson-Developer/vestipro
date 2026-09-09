import { HttpsError } from 'firebase-functions/v2/https';

import {
  buildReversalEntryId,
  calculateCommissionForOrder,
  commissionEntryId,
  isReversalOrderStatus,
  mapCommissionOrder,
  mapCommissionRule,
} from '../../src/commissions/commission-shared';

const order = mapCommissionOrder('order-1', {
  organizationId: 'org-1',
  companyId: 'company-1',
  sellerId: 'seller-1',
  teamIds: ['team-1'],
  orderNumber: '000123',
  currency: 'BRL',
  status: 'invoiced',
  total: 1000,
  discountAmount: 50,
  campaignIds: ['campaign-1'],
  items: [
    { id: 'item-1', productId: 'product-1', subtotal: 600 },
    { id: 'item-2', productId: 'product-2', subtotal: 400 },
  ],
});

describe('commission shared rules', () => {
  it('calculates a single percentage rule against the server order total', () => {
    const result = calculateCommissionForOrder(order, [
      mapCommissionRule('rule-1', {
        organizationId: 'org-1',
        companyId: 'company-1',
        type: 'percentage',
        percentage: 5,
        priority: 10,
        status: 'active',
      }),
    ]);

    expect(result.baseAmount).toBe(1000);
    expect(result.commissionAmount).toBe(50);
    expect(result.calculationTrace).toMatchObject({
      source: 'server_pricing_total',
      orderId: 'order-1',
      ruleId: 'rule-1',
    });
  });

  it('uses explicit priority when seller, campaign and product rules overlap', () => {
    const result = calculateCommissionForOrder(order, [
      mapCommissionRule('seller-rule', {
        organizationId: 'org-1',
        sellerId: 'seller-1',
        type: 'percentage',
        percentage: 4,
        priority: 20,
        status: 'active',
      }),
      mapCommissionRule('campaign-rule', {
        organizationId: 'org-1',
        campaignId: 'campaign-1',
        type: 'percentage',
        percentage: 7,
        priority: 90,
        status: 'active',
      }),
      mapCommissionRule('product-rule', {
        organizationId: 'org-1',
        productId: 'product-1',
        type: 'percentage',
        percentage: 10,
        priority: 50,
        status: 'active',
      }),
    ]);

    expect(result.rule.id).toBe('campaign-rule');
    expect(result.baseAmount).toBe(1000);
    expect(result.commissionAmount).toBe(70);
  });

  it('calculates product scoped rules only over matching item subtotals', () => {
    const result = calculateCommissionForOrder(order, [
      mapCommissionRule('product-rule', {
        organizationId: 'org-1',
        productId: 'product-1',
        type: 'percentage',
        percentage: 10,
        priority: 50,
        status: 'active',
      }),
    ]);

    expect(result.baseAmount).toBe(600);
    expect(result.commissionAmount).toBe(60);
  });

  it('keeps idempotency ids stable for provision and reversal entries', () => {
    expect(commissionEntryId('order-1', 'provision')).toBe(
      commissionEntryId('order-1', 'provision'),
    );
    expect(buildReversalEntryId('order-1', 'return-1')).toBe(
      buildReversalEntryId('order-1', 'return-1'),
    );
    expect(buildReversalEntryId('order-1', 'return-1')).not.toBe(
      buildReversalEntryId('order-1', 'return-2'),
    );
  });

  it('recognizes cancellation and partial return as reversal statuses', () => {
    expect(isReversalOrderStatus('cancelled')).toBe(true);
    expect(isReversalOrderStatus('partially_returned')).toBe(true);
    expect(isReversalOrderStatus('invoiced')).toBe(false);
  });

  it('rejects missing applicable rules so payable values are never guessed', () => {
    expect(() => calculateCommissionForOrder(order, [
      mapCommissionRule('other-org', {
        organizationId: 'org-2',
        type: 'percentage',
        percentage: 5,
        priority: 1,
        status: 'active',
      }),
    ])).toThrow(HttpsError);
  });
});
