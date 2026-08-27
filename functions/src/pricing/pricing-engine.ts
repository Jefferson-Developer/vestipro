export type DiscountValidationStatus = 'allowed' | 'requires_approval' | 'blocked';

export interface PricingEngineDiscountPolicy {
  id: string;
  companyId?: string;
  role: string;
  maxDiscountPercent: number;
  requiresApprovalAbovePercent?: number;
  priceListIds?: string[];
  status: 'active' | 'inactive';
}

export interface PricingEngineCampaign {
  id: string;
  companyId?: string;
  name: string;
  customerSegment: string;
  productIds: string[];
  collectionIds: string[];
  categoryIds: string[];
  discountType: 'percentage' | 'fixedAmount';
  discountValue: number;
  stackableWithOtherCampaigns: boolean;
  priority: number;
  status: 'draft' | 'active' | 'ended';
  validFrom: string;
  validTo: string;
}

export interface PricingEnginePriceList {
  id: string;
  companyId?: string;
  currency: string;
  status: 'draft' | 'active' | 'expired' | 'archived';
  validFrom: string;
  validTo?: string | null;
}

export interface PricingEnginePriceListItem {
  productId: string;
  variantId?: string | null;
  companyId?: string;
  price: number;
}

export interface PricingEnginePaymentTerm {
  id: string;
  companyId?: string;
  name: string;
  averageTermDays: number;
  status: 'active' | 'inactive';
  priceListIds: string[];
}

export interface PricingEngineItemInput {
  productId: string;
  quantity: number;
  variantId?: string;
  collectionId?: string;
  categoryId?: string;
  manualDiscountPercent?: number;
}

export interface PricingEngineAppliedDiscount {
  origin: 'campaign' | 'manual';
  amount: number;
  description: string;
  campaignId?: string;
}

export interface PricingEngineItemOutput {
  productId: string;
  variantId?: string;
  quantity: number;
  baseUnitPrice: number;
  priceAfterCampaigns: number;
  finalUnitPrice: number;
  lineSubtotal: number;
  lineTotal: number;
  validationStatus: DiscountValidationStatus;
  approvalRequest?: {
    discountPolicyId: string;
    requestedDiscountPercent: number;
    approvalThresholdPercent: number;
    maxDiscountPercent: number;
  };
  appliedDiscounts: PricingEngineAppliedDiscount[];
}

export interface PricingEngineInput {
  selectedPriceList: PricingEnginePriceList;
  priceListItems: PricingEnginePriceListItem[];
  paymentTerm: PricingEnginePaymentTerm;
  discountPolicy?: PricingEngineDiscountPolicy;
  campaigns: PricingEngineCampaign[];
  customerSegment: string;
  items: PricingEngineItemInput[];
  shippingAmount: number;
}

export interface PricingEngineOutput {
  currency: string;
  subtotal: number;
  campaignDiscountTotal: number;
  manualDiscountTotal: number;
  paymentTermAdjustmentTotal: number;
  shippingAmount: number;
  total: number;
  blocked: boolean;
  approvalRequired: boolean;
  items: PricingEngineItemOutput[];
}

const roundingTolerance = 0.01;

export function exceedsPricingTolerance(
  clientTotal: number,
  serverTotal: number,
  tolerance = roundingTolerance,
): boolean {
  return Math.abs(clientTotal - serverTotal) > tolerance;
}

export function calculatePricingEngine(
  input: PricingEngineInput,
): PricingEngineOutput {
  const items = input.items.map((item) =>
    calculatePricingItem(item, input),
  );

  const subtotal = roundCurrency(
    items.reduce((sum, item) => sum + item.lineSubtotal, 0),
  );
  const campaignDiscountTotal = roundCurrency(
    items.reduce(
      (sum, item) =>
        sum +
        item.appliedDiscounts
          .filter((discount) => discount.origin === 'campaign')
          .reduce((lineSum, discount) => lineSum + discount.amount, 0),
      0,
    ),
  );
  const manualDiscountTotal = roundCurrency(
    items.reduce(
      (sum, item) =>
        sum +
        item.appliedDiscounts
          .filter((discount) => discount.origin === 'manual')
          .reduce((lineSum, discount) => lineSum + discount.amount, 0),
      0,
    ),
  );

  return {
    currency: input.selectedPriceList.currency,
    subtotal,
    campaignDiscountTotal,
    manualDiscountTotal,
    paymentTermAdjustmentTotal: 0,
    shippingAmount: roundCurrency(input.shippingAmount),
    total: roundCurrency(
      items.reduce((sum, item) => sum + item.lineTotal, 0) +
        input.shippingAmount,
    ),
    blocked: items.some((item) => item.validationStatus === 'blocked'),
    approvalRequired: items.some(
      (item) => item.validationStatus === 'requires_approval',
    ),
    items,
  };
}

function calculatePricingItem(
  item: PricingEngineItemInput,
  input: PricingEngineInput,
): PricingEngineItemOutput {
  const baseUnitPrice = resolveBaseUnitPrice(
    input.priceListItems,
    item.productId,
    item.variantId,
  );
  const quantity = item.quantity;
  const lineSubtotal = roundCurrency(baseUnitPrice * quantity);
  const campaigns = resolveApplicableCampaigns(item, input.campaigns, input.customerSegment);
  const appliedDiscounts: PricingEngineAppliedDiscount[] = [];

  let runningUnitPrice = baseUnitPrice;
  for (const campaign of campaigns) {
    const amount = resolveCampaignDiscountAmount(runningUnitPrice, campaign);
    runningUnitPrice = roundCurrency(Math.max(0, runningUnitPrice - amount));
    appliedDiscounts.push({
      origin: 'campaign',
      amount: roundCurrency(amount * quantity),
      description: `Campaign ${campaign.name} applied.`,
      campaignId: campaign.id,
    });
  }

  const discountPolicy = input.discountPolicy;
  const manualDiscountPercent = item.manualDiscountPercent ?? 0;
  const validation = validateManualDiscount(
    manualDiscountPercent,
    discountPolicy,
    input.selectedPriceList.id,
  );

  let finalUnitPrice = runningUnitPrice;
  let approvalRequest: PricingEngineItemOutput['approvalRequest'];
  if (validation.status === 'allowed' || validation.status === 'requires_approval') {
    const manualAmount = runningUnitPrice * (manualDiscountPercent / 100);
    finalUnitPrice = roundCurrency(Math.max(0, runningUnitPrice - manualAmount));
    if (manualAmount > 0) {
      appliedDiscounts.push({
        origin: 'manual',
        amount: roundCurrency(manualAmount * quantity),
        description: `Manual discount ${manualDiscountPercent.toFixed(2)}%.`,
      });
    }
  }
  if (validation.status === 'requires_approval' && discountPolicy) {
    approvalRequest = {
      discountPolicyId: discountPolicy.id,
      requestedDiscountPercent: manualDiscountPercent,
      approvalThresholdPercent:
        discountPolicy.requiresApprovalAbovePercent ?? discountPolicy.maxDiscountPercent,
      maxDiscountPercent: discountPolicy.maxDiscountPercent,
    };
  }

  return {
    productId: item.productId,
    variantId: item.variantId,
    quantity,
    baseUnitPrice: roundCurrency(baseUnitPrice),
    priceAfterCampaigns: roundCurrency(runningUnitPrice),
    finalUnitPrice: roundCurrency(finalUnitPrice),
    lineSubtotal,
    lineTotal: roundCurrency(finalUnitPrice * quantity),
    validationStatus: validation.status,
    approvalRequest,
    appliedDiscounts,
  };
}

function resolveBaseUnitPrice(
  items: PricingEnginePriceListItem[],
  productId: string,
  variantId?: string,
): number {
  const exact = items.find(
    (item) =>
      item.productId === productId &&
      (item.variantId ?? undefined) === (variantId ?? undefined),
  );
  if (exact) return exact.price;

  const fallback = items.find(
    (item) => item.productId === productId && !item.variantId,
  );
  if (fallback) return fallback.price;

  throw new Error(`Missing price for ${productId} (${variantId ?? '*'})`);
}

function resolveApplicableCampaigns(
  item: PricingEngineItemInput,
  campaigns: PricingEngineCampaign[],
  customerSegment: string,
): PricingEngineCampaign[] {
  const eligible = campaigns
    .filter((campaign) => campaign.status === 'active')
    .filter((campaign) => campaign.customerSegment.trim().toLowerCase() === customerSegment.trim().toLowerCase())
    .filter((campaign) => {
      const now = new Date();
      return new Date(campaign.validFrom) <= now && new Date(campaign.validTo) >= now;
    })
    .filter((campaign) => {
      if (
        campaign.productIds.length === 0 &&
        campaign.collectionIds.length === 0 &&
        campaign.categoryIds.length === 0
      ) {
        return true;
      }
      return (
        campaign.productIds.includes(item.productId) ||
        (!!item.collectionId && campaign.collectionIds.includes(item.collectionId)) ||
        (!!item.categoryId && campaign.categoryIds.includes(item.categoryId))
      );
    })
    .sort((left, right) => {
      const byPriority = right.priority - left.priority;
      if (byPriority !== 0) return byPriority;
      return left.id.localeCompare(right.id);
    });

  const nonStackable = eligible.filter((campaign) => !campaign.stackableWithOtherCampaigns);
  if (nonStackable.length > 0) return [nonStackable[0]];
  return eligible;
}

function resolveCampaignDiscountAmount(
  baseUnitPrice: number,
  campaign: PricingEngineCampaign,
): number {
  if (campaign.discountType === 'percentage') {
    return baseUnitPrice * (campaign.discountValue / 100);
  }
  return Math.min(baseUnitPrice, campaign.discountValue);
}

function validateManualDiscount(
  manualDiscountPercent: number,
  discountPolicy: PricingEngineDiscountPolicy | undefined,
  priceListId: string,
): {
  status: DiscountValidationStatus;
} {
  if (manualDiscountPercent <= 0) {
    return { status: 'allowed' };
  }
  if (!discountPolicy || discountPolicy.status !== 'active') {
    return { status: 'blocked' };
  }
  if (
    discountPolicy.priceListIds &&
    discountPolicy.priceListIds.length > 0 &&
    !discountPolicy.priceListIds.includes(priceListId)
  ) {
    return { status: 'blocked' };
  }

  const approvalThreshold =
    discountPolicy.requiresApprovalAbovePercent ?? discountPolicy.maxDiscountPercent;
  if (manualDiscountPercent <= approvalThreshold) {
    return { status: 'allowed' };
  }
  if (manualDiscountPercent <= discountPolicy.maxDiscountPercent) {
    return { status: 'requires_approval' };
  }
  return { status: 'blocked' };
}

function roundCurrency(value: number): number {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}
