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
  /**
   * `OrderItem.packId`/`OrderItem.packGroupId` (TASK-208, EPIC-32) — set
   * only when this item came from expanding a `CommercialPack`
   * (`ExpandCommercialPackToOrderItemsUseCase`, client-side). Every item
   * sharing one [packGroupId] is one single pack instance: once every
   * item's own campaign/commercial-rule/manual pricing above is resolved,
   * [PricingEngineCommercialPack.pricingPolicyType] is applied once across
   * the whole group. [packId] is only ever used to look up the pack's own
   * policy server-side (`calculatePricing`/`submitOrder` fetch it fresh from
   * Firestore) — the policy/discount value itself is never trusted from
   * this input.
   */
  packId?: string;
  packGroupId?: string;
}

/**
 * `CommercialPack.pricingPolicyType` and its parameters (TASK-207,
 * `lib/features/commercial_packs/domain/entities/commercial_pack.dart`),
 * loaded fresh from Firestore by the caller (never accepted from the
 * client) — the server-side half of "a UI nunca calcula preço final do
 * pacote como fonte de verdade" (TASK-208).
 */
export interface PricingEngineCommercialPack {
  id: string;
  companyId?: string;
  status: 'draft' | 'active' | 'superseded' | 'expired' | 'archived';
  pricingPolicyType: 'componentSum' | 'fixedPrice' | 'packDiscount' | 'bonusItem';
  fixedPrice?: number;
  /** A fraction between 0 exclusive and 1 inclusive, mirroring
   * `CommercialPack.discountPercentage`'s own Dart-side contract. */
  discountPercentage?: number;
  /** The `variantId` (or, absent one, the `productId`) of the one component
   * given away for free under the `bonusItem` policy. */
  bonusComponentId?: string;
}

export interface PricingEngineAppliedDiscount {
  origin: 'campaign' | 'commercial_rule' | 'manual' | 'commercial_pack';
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
  /** Mirrors `PricingEngineItemInput.packGroupId` verbatim (TASK-208) — kept
   * on the output so a caller can regroup pack items after pricing without
   * re-zipping against the original input array. */
  packGroupId?: string;
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
  /**
   * Every `CommercialPack` referenced by at least one `items[].packId`
   * (TASK-208) — loaded and validated by the caller (`calculatePricing`/
   * `submitOrder`) straight from Firestore. A `packGroupId` whose pack is
   * missing here is simply priced as `componentSum` (no adjustment), never a
   * hard failure inside the pure engine itself — the caller decides whether
   * a missing/inactive pack should instead reject the whole request before
   * ever reaching this function.
   */
  packs?: PricingEngineCommercialPack[];
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
  /**
   * Net effect of every `CommercialPack.pricingPolicyType` adjustment
   * applied across every `packGroupId` present in `items` (TASK-208) —
   * positive when it reduced the group's total, `0` when nothing on this
   * request carried a `packGroupId` or every referenced pack used
   * `componentSum`. Already folded into each affected item's own
   * `finalUnitPrice`/`lineTotal` and into this output's own `total`; kept
   * here separately only so a caller can display/audit it distinctly from
   * campaign/commercial-rule/manual discounts.
   */
  packAdjustmentTotal: number;
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

  // TASK-208: applied once every item's own campaign/commercial-rule/manual
  // pricing above is already resolved — mutates `finalUnitPrice`/`lineTotal`
  // (and appends a `commercial_pack`-origin `appliedDiscounts` entry) on
  // every item whose `packGroupId` references a pack with an adjustment
  // policy. `lineSubtotal` (the pre-discount gross) is deliberately never
  // touched, same precedent every other discount origin already follows.
  applyCommercialPackAdjustments(items, input.items, input.packs ?? []);

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
  const packAdjustmentTotal = roundCurrency(
    items.reduce(
      (sum, item) =>
        sum +
        item.appliedDiscounts
          .filter((discount) => discount.origin === 'commercial_pack')
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
    packAdjustmentTotal,
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
    packGroupId: item.packGroupId,
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

/**
 * Groups `items`/`inputItems` (same order, 1:1 by index) by
 * `packGroupId` and applies each referenced pack's own
 * `pricingPolicyType` once per group (TASK-208) — mutates `items` in place
 * (`finalUnitPrice`/`lineTotal`/`appliedDiscounts`), never touches an item
 * outside a `packGroupId`, and is a complete no-op when `packs` is empty
 * (every existing call site that never sends packs behaves exactly as
 * before this task).
 */
function applyCommercialPackAdjustments(
  items: PricingEngineItemOutput[],
  inputItems: PricingEngineItemInput[],
  packs: PricingEngineCommercialPack[],
): void {
  if (packs.length === 0) return;
  const packsById = new Map(packs.map((pack) => [pack.id, pack]));
  const indicesByGroup = new Map<string, number[]>();
  inputItems.forEach((inputItem, index) => {
    const packGroupId = inputItem.packGroupId;
    if (!packGroupId) return;
    const indices = indicesByGroup.get(packGroupId) ?? [];
    indices.push(index);
    indicesByGroup.set(packGroupId, indices);
  });

  for (const indices of indicesByGroup.values()) {
    const groupItems = indices.map((index) => items[index]!);
    const packId = inputItems[indices[0]!]!.packId;
    const pack = packId ? packsById.get(packId) : undefined;
    if (!pack || pack.pricingPolicyType === 'componentSum') continue;

    const groupBaselineTotal = roundCurrency(
      groupItems.reduce((sum, item) => sum + item.lineTotal, 0),
    );

    switch (pack.pricingPolicyType) {
      case 'fixedPrice': {
        if (pack.fixedPrice === undefined || groupBaselineTotal <= 0) break;
        const adjustment = roundCurrency(
          groupBaselineTotal - roundCurrency(pack.fixedPrice),
        );
        distributeGroupAdjustment(
          groupItems,
          groupBaselineTotal,
          adjustment,
          pack.id,
        );
        break;
      }
      case 'packDiscount': {
        if (
          pack.discountPercentage === undefined ||
          pack.discountPercentage <= 0 ||
          groupBaselineTotal <= 0
        ) {
          break;
        }
        const adjustment = roundCurrency(
          groupBaselineTotal * pack.discountPercentage,
        );
        distributeGroupAdjustment(
          groupItems,
          groupBaselineTotal,
          adjustment,
          pack.id,
        );
        break;
      }
      case 'bonusItem': {
        const bonusComponentId = pack.bonusComponentId;
        if (!bonusComponentId) break;
        const bonusItem = groupItems.find(
          (item) =>
            item.variantId === bonusComponentId ||
            item.productId === bonusComponentId,
        );
        if (!bonusItem || bonusItem.lineTotal <= 0) break;
        const amount = roundCurrency(bonusItem.lineTotal);
        bonusItem.appliedDiscounts.push({
          origin: 'commercial_pack',
          amount,
          description: `Commercial pack ${pack.id} bonus item.`,
        });
        bonusItem.finalUnitPrice = 0;
        bonusItem.lineTotal = 0;
        break;
      }
    }
  }
}

/**
 * Splits [adjustment] (positive = discount, negative = surcharge)
 * proportionally across [groupItems] by each item's own share of
 * [groupBaselineTotal] — the last item absorbs whatever rounding remainder
 * the proportional shares leave behind, so the group's items always sum
 * back to exactly `groupBaselineTotal - adjustment`, never an
 * off-by-a-cent drift. A no-op when [groupBaselineTotal] is `0` (nothing to
 * distribute against).
 */
function distributeGroupAdjustment(
  groupItems: PricingEngineItemOutput[],
  groupBaselineTotal: number,
  adjustment: number,
  packId: string,
): void {
  if (groupBaselineTotal <= 0) return;
  let allocated = 0;
  groupItems.forEach((item, index) => {
    const isLast = index === groupItems.length - 1;
    const share = isLast
      ? roundCurrency(adjustment - allocated)
      : roundCurrency(adjustment * (item.lineTotal / groupBaselineTotal));
    allocated = roundCurrency(allocated + share);
    if (share === 0) return;
    item.appliedDiscounts.push({
      origin: 'commercial_pack',
      amount: share,
      description: `Commercial pack ${packId} adjustment.`,
    });
    item.lineTotal = roundCurrency(Math.max(0, item.lineTotal - share));
    item.finalUnitPrice = item.quantity > 0
      ? roundCurrency(item.lineTotal / item.quantity)
      : item.finalUnitPrice;
  });
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
