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

export type PricingEngineCommercialRuleType =
  | 'progressiveDiscount'
  | 'segmentCondition'
  | 'productCombo'
  | 'channelSpecific';

export interface PricingEngineCommercialRuleCondition {
  customerIds?: string[];
  customerSegments?: string[];
  productIds?: string[];
  collectionIds?: string[];
  categoryIds?: string[];
  channels?: string[];
  minimumQuantity?: number;
  comboProductIds?: string[];
}

export interface PricingEngineCommercialRuleEffect {
  type: 'percentage' | 'fixedAmount' | 'paymentTerm';
  value?: number;
  paymentTermId?: string;
}

export interface PricingEngineCommercialRule {
  id: string;
  companyId?: string;
  name: string;
  type: PricingEngineCommercialRuleType;
  priority: number;
  status: 'draft' | 'active' | 'ended' | 'inactive';
  validFrom: string;
  validTo: string;
  conditions: PricingEngineCommercialRuleCondition;
  effect: PricingEngineCommercialRuleEffect;
  stackable: boolean;
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
  origin: 'campaign' | 'commercial_rule' | 'manual';
  amount: number;
  description: string;
  campaignId?: string;
  commercialRuleId?: string;
}

export interface PricingEngineCommercialRuleTrace {
  ruleId: string;
  ruleName: string;
  priority: number;
  status: PricingEngineCommercialRule['status'];
  evaluated: boolean;
  applied: boolean;
  reason: string;
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
  commercialRuleTrace: PricingEngineCommercialRuleTrace[];
}

export interface PricingEngineInput {
  selectedPriceList: PricingEnginePriceList;
  priceListItems: PricingEnginePriceListItem[];
  paymentTerm: PricingEnginePaymentTerm;
  discountPolicy?: PricingEngineDiscountPolicy;
  campaigns: PricingEngineCampaign[];
  commercialRules?: PricingEngineCommercialRule[];
  customerId?: string;
  customerSegment: string;
  channel?: string;
  items: PricingEngineItemInput[];
  shippingAmount: number;
  effectiveAt?: string;
}

export interface PricingEngineOutput {
  currency: string;
  subtotal: number;
  campaignDiscountTotal: number;
  commercialRuleDiscountTotal: number;
  manualDiscountTotal: number;
  paymentTermAdjustmentTotal: number;
  appliedPaymentTermRuleId?: string;
  shippingAmount: number;
  total: number;
  blocked: boolean;
  approvalRequired: boolean;
  items: PricingEngineItemOutput[];
  commercialRuleTrace: PricingEngineCommercialRuleTrace[];
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
  const commercialRuleDiscountTotal = roundCurrency(
    items.reduce(
      (sum, item) =>
        sum +
        item.appliedDiscounts
          .filter((discount) => discount.origin === 'commercial_rule')
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
  const commercialRuleTrace = items.flatMap((item) => item.commercialRuleTrace);
  const paymentTermRule = commercialRuleTrace.find((trace) =>
    trace.applied && trace.reason === 'payment_term_effect',
  );

  return {
    currency: input.selectedPriceList.currency,
    subtotal,
    campaignDiscountTotal,
    commercialRuleDiscountTotal,
    manualDiscountTotal,
    paymentTermAdjustmentTotal: 0,
    appliedPaymentTermRuleId: paymentTermRule?.ruleId,
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
    commercialRuleTrace,
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
  const commercialRules = resolveCommercialRulesForItem(item, input);
  const appliedDiscounts: PricingEngineAppliedDiscount[] = [];
  const commercialRuleTrace: PricingEngineCommercialRuleTrace[] = [];

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

  for (const rule of commercialRules) {
    const effect = rule.effect;
    if (effect.type === 'paymentTerm') {
      commercialRuleTrace.push(buildCommercialRuleTrace(rule, true, 'payment_term_effect'));
      continue;
    }

    const discountValue = effect.value ?? 0;
    const amount = effect.type === 'percentage'
      ? runningUnitPrice * (discountValue / 100)
      : Math.min(runningUnitPrice, discountValue);
    runningUnitPrice = roundCurrency(Math.max(0, runningUnitPrice - amount));
    appliedDiscounts.push({
      origin: 'commercial_rule',
      amount: roundCurrency(amount * quantity),
      description: `Commercial rule ${rule.name} applied.`,
      commercialRuleId: rule.id,
    });
    commercialRuleTrace.push(buildCommercialRuleTrace(rule, true, 'discount_effect'));
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
    commercialRuleTrace,
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

function resolveCommercialRulesForItem(
  item: PricingEngineItemInput,
  input: PricingEngineInput,
): PricingEngineCommercialRule[] {
  const effectiveAt = new Date(input.effectiveAt ?? new Date().toISOString());
  const rules = input.commercialRules ?? [];
  const eligible = rules
    .filter((rule) => rule.status === 'active')
    .filter((rule) => new Date(rule.validFrom) <= effectiveAt && new Date(rule.validTo) >= effectiveAt)
    .filter((rule) => matchesCommercialRuleConditions(rule, item, input))
    .sort((left, right) => {
      const byPriority = right.priority - left.priority;
      if (byPriority !== 0) return byPriority;
      return left.id.localeCompare(right.id);
    });

  const nonStackable = eligible.filter((rule) => !rule.stackable);
  if (nonStackable.length > 0) return [nonStackable[0]];
  return eligible;
}

function matchesCommercialRuleConditions(
  rule: PricingEngineCommercialRule,
  item: PricingEngineItemInput,
  input: PricingEngineInput,
): boolean {
  const conditions = rule.conditions;
  if (conditions.customerIds?.length && !conditions.customerIds.includes(input.customerId ?? '')) {
    return false;
  }
  if (
    conditions.customerSegments?.length &&
    !conditions.customerSegments
      .map((segment) => segment.trim().toLowerCase())
      .includes(input.customerSegment.trim().toLowerCase())
  ) {
    return false;
  }
  if (
    conditions.channels?.length &&
    !conditions.channels
      .map((channel) => channel.trim().toLowerCase())
      .includes((input.channel ?? 'internal').trim().toLowerCase())
  ) {
    return false;
  }
  if (
    conditions.minimumQuantity !== undefined &&
    item.quantity < conditions.minimumQuantity
  ) {
    return false;
  }
  if (conditions.comboProductIds?.length) {
    const presentProductIds = new Set(input.items.map((candidate) => candidate.productId));
    if (!conditions.comboProductIds.every((productId) => presentProductIds.has(productId))) {
      return false;
    }
  }
  if (
    !conditions.productIds?.length &&
    !conditions.collectionIds?.length &&
    !conditions.categoryIds?.length
  ) {
    return true;
  }
  return (
    conditions.productIds?.includes(item.productId) === true ||
    (!!item.collectionId && conditions.collectionIds?.includes(item.collectionId) === true) ||
    (!!item.categoryId && conditions.categoryIds?.includes(item.categoryId) === true)
  );
}

function buildCommercialRuleTrace(
  rule: PricingEngineCommercialRule,
  applied: boolean,
  reason: string,
): PricingEngineCommercialRuleTrace {
  return {
    ruleId: rule.id,
    ruleName: rule.name,
    priority: rule.priority,
    status: rule.status,
    evaluated: true,
    applied,
    reason,
  };
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
