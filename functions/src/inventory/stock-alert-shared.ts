import { Timestamp, type DocumentData } from 'firebase-admin/firestore';

export type StockAlertLevel = 'low' | 'critical';
export type StockAlertTransitionType =
  | 'entered'
  | 'escalated'
  | 'deescalated'
  | 'recovered';

export interface InventoryBalanceSnapshot {
  organizationId: string;
  companyId: string;
  productId: string;
  variantId: string;
  warehouseId: string;
  physicalQuantity: number;
  reservedQuantity: number;
  blockedQuantity: number;
  version: number;
  updatedAt: Timestamp;
  updatedBy: string;
  lastSource: string;
}

export interface StockAlertRuleDocument {
  id: string;
  organizationId: string;
  productId?: string | null;
  variantId?: string | null;
  warehouseId?: string | null;
  minQuantity: number;
  alertLevel: StockAlertLevel;
  isActive: boolean;
}

export interface ResolvedStockAlertRule extends StockAlertRuleDocument {
  specificityScore: number;
}

export function asBalanceSnapshot(data: DocumentData | undefined): InventoryBalanceSnapshot | null {
  if (!data) return null;
  if (
    typeof data.organizationId !== 'string' ||
    typeof data.companyId !== 'string' ||
    typeof data.productId !== 'string' ||
    typeof data.variantId !== 'string' ||
    typeof data.warehouseId !== 'string' ||
    typeof data.updatedBy !== 'string' ||
    typeof data.lastSource !== 'string' ||
    typeof data.physicalQuantity !== 'number' ||
    typeof data.reservedQuantity !== 'number' ||
    typeof data.blockedQuantity !== 'number' ||
    typeof data.version !== 'number' ||
    !(data.updatedAt instanceof Timestamp)
  ) {
    return null;
  }

  return {
    organizationId: data.organizationId,
    companyId: data.companyId,
    productId: data.productId,
    variantId: data.variantId,
    warehouseId: data.warehouseId,
    physicalQuantity: data.physicalQuantity,
    reservedQuantity: data.reservedQuantity,
    blockedQuantity: data.blockedQuantity,
    version: data.version,
    updatedAt: data.updatedAt,
    updatedBy: data.updatedBy,
    lastSource: data.lastSource,
  };
}

export function sellableQuantity(balance: InventoryBalanceSnapshot | null): number | null {
  if (!balance) return null;
  const total =
    balance.physicalQuantity - balance.reservedQuantity - balance.blockedQuantity;
  return total < 0 ? 0 : total;
}

export function asStockAlertRuleDocument(
  id: string,
  data: DocumentData | undefined,
): StockAlertRuleDocument | null {
  if (!data) return null;
  if (
    typeof data.organizationId !== 'string' ||
    typeof data.minQuantity !== 'number' ||
    !Number.isInteger(data.minQuantity) ||
    (data.productId != null && typeof data.productId !== 'string') ||
    (data.variantId != null && typeof data.variantId !== 'string') ||
    (data.warehouseId != null && typeof data.warehouseId !== 'string') ||
    (data.alertLevel !== 'low' && data.alertLevel !== 'critical') ||
    typeof data.isActive !== 'boolean'
  ) {
    return null;
  }

  return {
    id,
    organizationId: data.organizationId,
    productId: data.productId ?? null,
    variantId: data.variantId ?? null,
    warehouseId: data.warehouseId ?? null,
    minQuantity: data.minQuantity,
    alertLevel: data.alertLevel,
    isActive: data.isActive,
  };
}

export function resolveApplicableRules(
  rules: ReadonlyArray<StockAlertRuleDocument>,
  balance: InventoryBalanceSnapshot,
): ReadonlyArray<ResolvedStockAlertRule> {
  const applicable = rules
    .filter((rule) => rule.isActive)
    .filter((rule) => rule.organizationId === balance.organizationId)
    .filter((rule) => rule.variantId == null || rule.variantId === balance.variantId)
    .filter((rule) => rule.productId == null || rule.productId === balance.productId)
    .filter((rule) => rule.warehouseId == null || rule.warehouseId === balance.warehouseId)
    .map((rule) => ({
      ...rule,
      specificityScore:
        (rule.variantId ? 20 : rule.productId ? 10 : 0) + (rule.warehouseId ? 1 : 0),
    }));

  if (applicable.length === 0) {
    return [];
  }

  const highestSpecificity = applicable.reduce(
    (best, rule) => Math.max(best, rule.specificityScore),
    0,
  );
  return applicable.filter((rule) => rule.specificityScore === highestSpecificity);
}

export function levelForQuantity(
  quantity: number | null,
  rules: ReadonlyArray<ResolvedStockAlertRule>,
): StockAlertLevel | null {
  if (quantity == null || rules.length === 0) {
    return null;
  }

  const crossed = rules.filter((rule) => quantity <= rule.minQuantity);
  if (crossed.some((rule) => rule.alertLevel === 'critical')) {
    return 'critical';
  }
  if (crossed.some((rule) => rule.alertLevel === 'low')) {
    return 'low';
  }
  return null;
}

export function chooseRuleForLevel(
  level: StockAlertLevel,
  rules: ReadonlyArray<ResolvedStockAlertRule>,
): ResolvedStockAlertRule {
  const matching = rules
    .filter((rule) => rule.alertLevel === level)
    .sort((left, right) => right.minQuantity - left.minQuantity);
  if (matching.length === 0) {
    throw new Error(`No matching stock alert rule found for level ${level}.`);
  }
  return matching[0];
}

export function resolveTransitionType(
  previousLevel: StockAlertLevel | null,
  currentLevel: StockAlertLevel | null,
): StockAlertTransitionType | null {
  if (previousLevel === currentLevel) {
    return null;
  }
  if (previousLevel == null && currentLevel != null) {
    return 'entered';
  }
  if (previousLevel === 'low' && currentLevel === 'critical') {
    return 'escalated';
  }
  if (previousLevel === 'critical' && currentLevel === 'low') {
    return 'deescalated';
  }
  if (previousLevel != null && currentLevel == null) {
    return 'recovered';
  }
  return null;
}

