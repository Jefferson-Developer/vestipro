import {
  buildApprovalChainInstance,
} from '../../src/orders/approval-chain';
import type { PricingEngineOutput } from '../../src/pricing/pricing-engine';

describe('buildApprovalChainInstance', () => {
  it('selects the most specific active band for the server-calculated discount', () => {
    const chain = buildApprovalChainInstance(
      [
        {
          id: 'default-low',
          data: {
            status: 'active',
            minDiscountPercent: 10,
            maxDiscountPercent: 20,
            levels: [{ role: 'SALES_MANAGER', label: 'Gestor' }],
          },
        },
        {
          id: 'company-high',
          data: {
            companyId: 'company-1',
            status: 'active',
            version: 3,
            minDiscountPercent: 15,
            maxDiscountPercent: 30,
            levels: [
              { role: 'SALES_MANAGER', label: 'Gestor direto' },
              { role: 'ADMIN', label: 'Diretoria comercial' },
            ],
          },
        },
      ],
      'company-1',
      pricingWithRequestedDiscount(18),
      'Desconto manual de 18.00%.',
    );

    expect(chain?.policyId).toBe('company-high');
    expect(chain?.policyVersion).toBe(3);
    expect(chain?.discountPercent).toBe(18);
    expect(chain?.currentLevelIndex).toBe(0);
    expect(chain?.levels.map((level) => level.role)).toEqual([
      'SALES_MANAGER',
      'ADMIN',
    ]);
  });

  it('returns null when no active band covers the required discount', () => {
    const chain = buildApprovalChainInstance(
      [
        {
          id: 'low',
          data: {
            status: 'active',
            minDiscountPercent: 5,
            maxDiscountPercent: 10,
            levels: [{ role: 'SALES_MANAGER' }],
          },
        },
      ],
      'company-1',
      pricingWithRequestedDiscount(18),
      'Desconto manual de 18.00%.',
    );

    expect(chain).toBeNull();
  });
});

function pricingWithRequestedDiscount(discountPercent: number): PricingEngineOutput {
  return {
    currency: 'BRL',
    subtotal: 100,
    campaignDiscountTotal: 0,
    manualDiscountTotal: 18,
    paymentTermAdjustmentTotal: 0,
    shippingAmount: 0,
    total: 82,
    blocked: false,
    approvalRequired: true,
    items: [
      {
        productId: 'product-1',
        variantId: 'variant-1',
        quantity: 1,
        baseUnitPrice: 100,
        priceAfterCampaigns: 100,
        finalUnitPrice: 82,
        lineSubtotal: 100,
        lineTotal: 82,
        validationStatus: 'requires_approval',
        approvalRequest: {
          discountPolicyId: 'discount-policy-1',
          requestedDiscountPercent: discountPercent,
          approvalThresholdPercent: 10,
          maxDiscountPercent: 30,
        },
        appliedDiscounts: [],
      },
    ],
  };
}
