import {
  calculatePricingEngine,
  exceedsPricingTolerance,
  type PricingEngineCampaign,
  type PricingEngineDiscountPolicy,
  type PricingEngineInput,
} from '../../src/pricing/pricing-engine';

function buildInput(
  overrides: Partial<PricingEngineInput> = {},
): PricingEngineInput {
  return {
    selectedPriceList: {
      id: 'price-list-1',
      companyId: 'company-1',
      currency: 'BRL',
      status: 'active',
      validFrom: '2026-08-01T00:00:00.000Z',
    },
    priceListItems: [
      {
        productId: 'product-1',
        companyId: 'company-1',
        price: 100,
      },
    ],
    paymentTerm: {
      id: 'term-1',
      companyId: 'company-1',
      name: '30 dias',
      averageTermDays: 30,
      status: 'active',
      priceListIds: ['price-list-1'],
    },
    discountPolicy: {
      id: 'policy-1',
      companyId: 'company-1',
      role: 'SALES_REP',
      maxDiscountPercent: 15,
      requiresApprovalAbovePercent: 10,
      priceListIds: ['price-list-1'],
      status: 'active',
    },
    campaigns: [],
    customerSegment: 'vip',
    items: [
      {
        productId: 'product-1',
        quantity: 2,
      },
    ],
    shippingAmount: 15,
    ...overrides,
  };
}

function buildCampaign(
  overrides: Partial<PricingEngineCampaign> = {},
): PricingEngineCampaign {
  return {
    id: 'campaign-1',
    companyId: 'company-1',
    name: 'Campanha VIP',
    customerSegment: 'vip',
    productIds: ['product-1'],
    collectionIds: [],
    categoryIds: [],
    discountType: 'percentage',
    discountValue: 10,
    stackableWithOtherCampaigns: true,
    priority: 1,
    status: 'active',
    validFrom: '2026-08-01T00:00:00.000Z',
    validTo: '2026-12-31T23:59:59.000Z',
    ...overrides,
  };
}

describe('calculatePricingEngine', () => {
  it('calculates base pricing without discount or campaign', () => {
    const result = calculatePricingEngine(
      buildInput({
        items: [{ productId: 'product-1', quantity: 2 }],
        shippingAmount: 0,
      }),
    );

    expect(result.subtotal).toBe(200);
    expect(result.total).toBe(200);
    expect(result.campaignDiscountTotal).toBe(0);
    expect(result.manualDiscountTotal).toBe(0);
    expect(result.paymentTermAdjustmentTotal).toBe(0);
  });

  it('applies a manual discount inside the policy limit', () => {
    const result = calculatePricingEngine(
      buildInput({
        items: [
          {
            productId: 'product-1',
            quantity: 2,
            manualDiscountPercent: 5,
          },
        ],
      }),
    );

    expect(result.manualDiscountTotal).toBe(10);
    expect(result.blocked).toBe(false);
    expect(result.approvalRequired).toBe(false);
    expect(result.total).toBe(205);
  });

  it('blocks a manual discount above the policy maximum', () => {
    const result = calculatePricingEngine(
      buildInput({
        items: [
          {
            productId: 'product-1',
            quantity: 1,
            manualDiscountPercent: 18,
          },
        ],
        shippingAmount: 0,
      }),
    );

    expect(result.blocked).toBe(true);
    expect(result.items[0].validationStatus).toBe('blocked');
    expect(result.items[0].finalUnitPrice).toBe(100);
    expect(result.total).toBe(100);
  });

  it('applies a single eligible campaign before manual discount validation', () => {
    const result = calculatePricingEngine(
      buildInput({
        campaigns: [buildCampaign()],
        items: [
          {
            productId: 'product-1',
            quantity: 1,
            manualDiscountPercent: 12,
          },
        ],
        shippingAmount: 0,
      }),
    );

    expect(result.items[0].priceAfterCampaigns).toBe(90);
    expect(result.items[0].finalUnitPrice).toBe(79.2);
    expect(result.approvalRequired).toBe(true);
    expect(result.campaignDiscountTotal).toBe(10);
    expect(result.manualDiscountTotal).toBe(10.8);
  });

  it('prefers the highest-priority non-stackable campaign over stackable combinations', () => {
    const result = calculatePricingEngine(
      buildInput({
        campaigns: [
          buildCampaign({
            id: 'campaign-stackable',
            discountValue: 10,
            stackableWithOtherCampaigns: true,
            priority: 2,
          }),
          buildCampaign({
            id: 'campaign-non-stackable',
            discountValue: 25,
            stackableWithOtherCampaigns: false,
            priority: 9,
          }),
          buildCampaign({
            id: 'campaign-stackable-2',
            discountValue: 5,
            stackableWithOtherCampaigns: true,
            priority: 1,
          }),
        ],
        items: [{ productId: 'product-1', quantity: 1 }],
        shippingAmount: 0,
      }),
    );

    expect(result.items[0].appliedDiscounts).toHaveLength(1);
    expect(result.items[0].appliedDiscounts[0].campaignId).toBe(
      'campaign-non-stackable',
    );
    expect(result.items[0].finalUnitPrice).toBe(75);
  });

  it('composes price list, stackable campaigns, manual discount, payment term stage and shipping deterministically', () => {
    const discountPolicy: PricingEngineDiscountPolicy = {
      id: 'policy-2',
      companyId: 'company-1',
      role: 'MANAGER',
      maxDiscountPercent: 20,
      requiresApprovalAbovePercent: 10,
      priceListIds: ['price-list-1'],
      status: 'active',
    };

    const result = calculatePricingEngine(
      buildInput({
        discountPolicy,
        campaigns: [
          buildCampaign({
            id: 'campaign-percentage',
            discountValue: 10,
            stackableWithOtherCampaigns: true,
            priority: 3,
          }),
          buildCampaign({
            id: 'campaign-fixed',
            discountType: 'fixedAmount',
            discountValue: 5,
            stackableWithOtherCampaigns: true,
            priority: 2,
          }),
        ],
        items: [
          {
            productId: 'product-1',
            quantity: 2,
            manualDiscountPercent: 10,
          },
        ],
        shippingAmount: 20,
      }),
    );

    expect(result.items[0].baseUnitPrice).toBe(100);
    expect(result.items[0].priceAfterCampaigns).toBe(85);
    expect(result.items[0].finalUnitPrice).toBe(76.5);
    expect(result.campaignDiscountTotal).toBe(30);
    expect(result.manualDiscountTotal).toBe(17);
    expect(result.paymentTermAdjustmentTotal).toBe(0);
    expect(result.total).toBe(173);
  });
});

describe('exceedsPricingTolerance', () => {
  it('flags totals only when the difference exceeds tolerance', () => {
    expect(exceedsPricingTolerance(100, 100.009)).toBe(false);
    expect(exceedsPricingTolerance(100, 100.02)).toBe(true);
  });
});
