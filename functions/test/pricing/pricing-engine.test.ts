import {
  calculatePricingEngine,
  exceedsPricingTolerance,
  type PricingEngineCampaign,
  type PricingEngineCommercialPack,
  type PricingEngineCommercialRule,
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

function buildCommercialRule(
  overrides: Partial<PricingEngineCommercialRule> = {},
): PricingEngineCommercialRule {
  return {
    id: 'rule-1',
    companyId: 'company-1',
    name: 'Volume VIP',
    type: 'progressiveDiscount',
    priority: 10,
    status: 'active',
    validFrom: '2026-08-01T00:00:00.000Z',
    validTo: '2026-12-31T23:59:59.000Z',
    conditions: {
      customerSegments: ['vip'],
      productIds: ['product-1'],
      minimumQuantity: 2,
      channels: ['internal'],
    },
    effect: {
      type: 'percentage',
      value: 8,
    },
    stackable: true,
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

  it('applies an advanced commercial rule inside the same deterministic pricing pipeline', () => {
    const result = calculatePricingEngine(
      buildInput({
        campaigns: [buildCampaign({ discountValue: 10, priority: 2 })],
        commercialRules: [buildCommercialRule()],
        channel: 'internal',
        items: [{ productId: 'product-1', quantity: 2 }],
        shippingAmount: 0,
        effectiveAt: '2026-09-09T12:00:00.000Z',
      }),
    );

    expect(result.campaignDiscountTotal).toBe(20);
    expect(result.commercialRuleDiscountTotal).toBe(14.4);
    expect(result.manualDiscountTotal).toBe(0);
    expect(result.items[0].finalUnitPrice).toBe(82.8);
    expect(result.items[0].appliedDiscounts.map((discount) => discount.origin)).toEqual([
      'campaign',
      'commercial_rule',
    ]);
    expect(result.commercialRuleTrace).toEqual([
      expect.objectContaining({
        ruleId: 'rule-1',
        applied: true,
        reason: 'discount_effect',
      }),
    ]);
  });

  it('uses priority and id as a deterministic tie-breaker for overlapping commercial rules', () => {
    const result = calculatePricingEngine(
      buildInput({
        commercialRules: [
          buildCommercialRule({ id: 'rule-low', priority: 1, stackable: false }),
          buildCommercialRule({ id: 'rule-high', priority: 9, stackable: false }),
          buildCommercialRule({ id: 'rule-high-b', priority: 9, stackable: false }),
        ],
        channel: 'internal',
        items: [{ productId: 'product-1', quantity: 2 }],
        shippingAmount: 0,
        effectiveAt: '2026-09-09T12:00:00.000Z',
      }),
    );

    expect(result.items[0].appliedDiscounts).toHaveLength(1);
    expect(result.items[0].appliedDiscounts[0].commercialRuleId).toBe('rule-high');
  });

  it('ignores expired commercial rules', () => {
    const result = calculatePricingEngine(
      buildInput({
        commercialRules: [
          buildCommercialRule({
            validFrom: '2026-01-01T00:00:00.000Z',
            validTo: '2026-01-31T23:59:59.000Z',
          }),
        ],
        channel: 'internal',
        items: [{ productId: 'product-1', quantity: 2 }],
        shippingAmount: 0,
        effectiveAt: '2026-09-09T12:00:00.000Z',
      }),
    );

    expect(result.commercialRuleDiscountTotal).toBe(0);
    expect(result.total).toBe(200);
  });

  it('ignores channel-specific commercial rules for a different channel', () => {
    const result = calculatePricingEngine(
      buildInput({
        commercialRules: [buildCommercialRule({ conditions: { channels: ['customer_portal'] } })],
        channel: 'internal',
        items: [{ productId: 'product-1', quantity: 2 }],
        shippingAmount: 0,
        effectiveAt: '2026-09-09T12:00:00.000Z',
      }),
    );

    expect(result.commercialRuleDiscountTotal).toBe(0);
    expect(result.total).toBe(200);
  });

  it('keeps existing campaign and discount-policy behavior when no advanced rules are configured', () => {
    const result = calculatePricingEngine(
      buildInput({
        campaigns: [buildCampaign({ discountValue: 10 })],
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

    expect(result.commercialRuleDiscountTotal).toBe(0);
    expect(result.items[0].priceAfterCampaigns).toBe(90);
    expect(result.items[0].finalUnitPrice).toBe(79.2);
    expect(result.approvalRequired).toBe(true);
  });
});

function buildPackPricingInput(
  pack: PricingEngineCommercialPack,
  overrides: Partial<PricingEngineInput> = {},
): PricingEngineInput {
  return buildInput({
    priceListItems: [
      { productId: 'product-1', companyId: 'company-1', price: 100 },
      { productId: 'product-2', companyId: 'company-1', price: 100 },
    ],
    packs: [pack],
    items: [
      { productId: 'product-1', quantity: 2, packId: 'pack-1', packGroupId: 'group-1' },
      { productId: 'product-2', quantity: 1, packId: 'pack-1', packGroupId: 'group-1' },
    ],
    shippingAmount: 0,
    ...overrides,
  });
}

describe('calculatePricingEngine — commercial pack adjustments (TASK-208)', () => {
  it('never adjusts anything for the componentSum policy', () => {
    const result = calculatePricingEngine(
      buildPackPricingInput({
        id: 'pack-1',
        companyId: 'company-1',
        status: 'active',
        pricingPolicyType: 'componentSum',
      }),
    );

    expect(result.total).toBe(300);
    expect(result.packAdjustmentTotal).toBe(0);
    expect(result.items.every((item) => item.appliedDiscounts.length === 0)).toBe(
      true,
    );
  });

  it('forces the group total to fixedPrice, distributed proportionally across its items', () => {
    const result = calculatePricingEngine(
      buildPackPricingInput({
        id: 'pack-1',
        companyId: 'company-1',
        status: 'active',
        pricingPolicyType: 'fixedPrice',
        fixedPrice: 250,
      }),
    );

    expect(result.packAdjustmentTotal).toBe(50);
    expect(result.total).toBe(250);
    // product-1 (200 of the 300 baseline, 2/3) absorbs 2/3 of the 50
    // adjustment; product-2 (the last item) absorbs the exact remainder so
    // both lines always sum back to fixedPrice, never an off-by-a-cent
    // drift.
    expect(result.items[0].lineTotal).toBeCloseTo(200 - 50 * (200 / 300), 2);
    expect(result.items[1].lineTotal).toBeCloseTo(
      250 - result.items[0].lineTotal,
      2,
    );
    expect(
      result.items.flatMap((item) => item.appliedDiscounts),
    ).toEqual([
      expect.objectContaining({ origin: 'commercial_pack' }),
      expect.objectContaining({ origin: 'commercial_pack' }),
    ]);
  });

  it('applies a packDiscount percentage across the whole group', () => {
    const result = calculatePricingEngine(
      buildPackPricingInput({
        id: 'pack-1',
        companyId: 'company-1',
        status: 'active',
        pricingPolicyType: 'packDiscount',
        discountPercentage: 0.1,
      }),
    );

    expect(result.packAdjustmentTotal).toBe(30);
    expect(result.total).toBe(270);
  });

  it('zeroes the bonus component under the bonusItem policy', () => {
    const result = calculatePricingEngine(
      buildPackPricingInput({
        id: 'pack-1',
        companyId: 'company-1',
        status: 'active',
        pricingPolicyType: 'bonusItem',
        bonusComponentId: 'product-2',
      }),
    );

    const bonusItem = result.items.find((item) => item.productId === 'product-2')!;
    expect(bonusItem.finalUnitPrice).toBe(0);
    expect(bonusItem.lineTotal).toBe(0);
    expect(result.packAdjustmentTotal).toBe(100);
    expect(result.total).toBe(200);
  });

  it('prices a group as componentSum when its referenced pack was not supplied', () => {
    const result = calculatePricingEngine(
      buildPackPricingInput(
        {
          id: 'pack-other',
          companyId: 'company-1',
          status: 'active',
          pricingPolicyType: 'fixedPrice',
          fixedPrice: 1,
        },
        // `pack-1` (the id every item references) is never in `packs` here.
        {},
      ),
    );

    expect(result.packAdjustmentTotal).toBe(0);
    expect(result.total).toBe(300);
  });
});

describe('exceedsPricingTolerance', () => {
  it('flags totals only when the difference exceeds tolerance', () => {
    expect(exceedsPricingTolerance(100, 100.009)).toBe(false);
    expect(exceedsPricingTolerance(100, 100.02)).toBe(true);
  });
});
