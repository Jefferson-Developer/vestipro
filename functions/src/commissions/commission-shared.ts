import { createHash } from 'node:crypto';

import { HttpsError } from 'firebase-functions/v2/https';
import type { DocumentData, Timestamp } from 'firebase-admin/firestore';

export type CommissionRuleType = 'percentage' | 'fixed';
export type CommissionEntryStatus = 'provisioned' | 'approved' | 'paid' | 'reversed';

export interface CommissionRule {
  id: string;
  organizationId: string;
  companyId?: string;
  teamId?: string;
  sellerId?: string;
  productId?: string;
  campaignId?: string;
  type: CommissionRuleType;
  percentage?: number;
  fixedAmount?: number;
  priority: number;
  status: 'active' | 'inactive';
  validFrom?: Date;
  validTo?: Date;
}

export interface CommissionOrderItem {
  id: string;
  productId: string;
  subtotal: number;
}

export interface CommissionOrder {
  id: string;
  organizationId: string;
  companyId: string;
  sellerId: string;
  sellerName?: string;
  teamIds: string[];
  orderNumber?: string;
  currency: string;
  status: string;
  total: number;
  discountAmount: number;
  campaignIds: string[];
  items: CommissionOrderItem[];
  occurredAt: Date;
}

export interface CommissionCalculation {
  entryId: string;
  rule: CommissionRule;
  baseAmount: number;
  commissionAmount: number;
  calculationTrace: Record<string, unknown>;
}

export function mapCommissionRule(id: string, data: DocumentData | undefined): CommissionRule {
  if (!data) throw new HttpsError('failed-precondition', 'Commission rule missing.');
  const type = requireRuleType(data.type);
  return {
    id,
    organizationId: requireString(data.organizationId, 'organizationId'),
    companyId: optionalString(data.companyId),
    teamId: optionalString(data.teamId),
    sellerId: optionalString(data.sellerId),
    productId: optionalString(data.productId),
    campaignId: optionalString(data.campaignId),
    type,
    percentage: type === 'percentage' ? requirePercent(data.percentage) : undefined,
    fixedAmount: type === 'fixed' ? requireMoney(data.fixedAmount, 'fixedAmount') : undefined,
    priority: integer(data.priority),
    status: requireString(data.status, 'status') as CommissionRule['status'],
    validFrom: timestampToDate(data.validFrom),
    validTo: timestampToDate(data.validTo),
  };
}

export function mapCommissionOrder(id: string, data: DocumentData | undefined): CommissionOrder {
  if (!data) throw new HttpsError('failed-precondition', 'Order missing.');
  const items = Array.isArray(data.items)
    ? data.items.map((item, index) => mapOrderItem(item, index))
    : [];
  return {
    id,
    organizationId: requireString(data.organizationId, 'organizationId'),
    companyId: requireString(data.companyId, 'companyId'),
    sellerId: requireString(data.sellerId, 'sellerId'),
    sellerName: optionalString(data.sellerName),
    teamIds: stringArray(data.teamIds),
    orderNumber: optionalString(data.orderNumber),
    currency: optionalString(data.currency) ?? 'BRL',
    status: requireString(data.status, 'status'),
    total: requireMoney(resolveOrderTotal(data, items), 'total'),
    discountAmount: money(data.discountAmount),
    campaignIds: stringArray(data.campaignIds),
    items,
    occurredAt: timestampToDate(data.invoicedAt) ?? timestampToDate(data.approvedAt) ??
      timestampToDate(data.createdAt) ?? new Date(),
  };
}

export function selectCommissionRule(
  order: CommissionOrder,
  rules: readonly CommissionRule[],
): CommissionRule {
  const applicable = rules
    .filter((rule) => rule.status === 'active')
    .filter((rule) => rule.organizationId === order.organizationId)
    .filter((rule) => rule.companyId === undefined || rule.companyId === order.companyId)
    .filter((rule) => rule.sellerId === undefined || rule.sellerId === order.sellerId)
    .filter((rule) => rule.teamId === undefined || order.teamIds.includes(rule.teamId))
    .filter((rule) => rule.campaignId === undefined || order.campaignIds.includes(rule.campaignId))
    .filter((rule) => rule.productId === undefined || order.items.some((item) => item.productId === rule.productId))
    .filter((rule) => rule.validFrom === undefined || rule.validFrom.getTime() <= order.occurredAt.getTime())
    .filter((rule) => rule.validTo === undefined || rule.validTo.getTime() >= order.occurredAt.getTime())
    .sort(compareRulePriority);

  const rule = applicable[0];
  if (!rule) {
    throw new HttpsError('failed-precondition', 'Nenhuma regra de comissao ativa atende este pedido.');
  }
  return rule;
}

export function calculateCommissionForOrder(
  order: CommissionOrder,
  rules: readonly CommissionRule[],
): CommissionCalculation {
  const rule = selectCommissionRule(order, rules);
  const baseAmount = roundMoney(rule.productId
    ? order.items
      .filter((item) => item.productId === rule.productId)
      .reduce((sum, item) => sum + item.subtotal, 0)
    : order.total);
  const commissionAmount = roundMoney(rule.type === 'percentage'
    ? baseAmount * ((rule.percentage ?? 0) / 100)
    : rule.fixedAmount ?? 0);
  return {
    entryId: commissionEntryId(order.id, 'provision'),
    rule,
    baseAmount,
    commissionAmount,
    calculationTrace: {
      source: 'server_pricing_total',
      orderId: order.id,
      orderNumber: order.orderNumber ?? null,
      ruleId: rule.id,
      ruleType: rule.type,
      rulePriority: rule.priority,
      baseAmount,
      percentage: rule.percentage ?? null,
      fixedAmount: rule.fixedAmount ?? null,
      formula: rule.type === 'percentage' ? 'baseAmount * percentage / 100' : 'fixedAmount',
    },
  };
}

export function buildReversalEntryId(orderId: string, sourceEventId: string): string {
  return commissionEntryId(orderId, `reversal:${sourceEventId}`);
}

export function commissionEntryId(orderId: string, discriminator: string): string {
  return createHash('sha256').update(`${orderId}:${discriminator}`).digest('hex');
}

export function isCommissionableOrderStatus(status: string): boolean {
  return ['submitted', 'approved', 'invoiced', 'paid'].includes(status);
}

export function isReversalOrderStatus(status: string): boolean {
  return ['cancelled', 'canceled', 'returned', 'partially_returned', 'refunded'].includes(status);
}

function compareRulePriority(left: CommissionRule, right: CommissionRule): number {
  return right.priority - left.priority ||
    specificity(right) - specificity(left) ||
    left.id.localeCompare(right.id);
}

function specificity(rule: CommissionRule): number {
  return [rule.sellerId, rule.teamId, rule.productId, rule.campaignId, rule.companyId]
    .filter((value) => value !== undefined).length;
}

function mapOrderItem(value: unknown, index: number): CommissionOrderItem {
  const data = value as DocumentData | null;
  if (!data || typeof data !== 'object') {
    throw new HttpsError('failed-precondition', `Order item ${index} is invalid.`);
  }
  return {
    id: optionalString(data.id) ?? `item-${index}`,
    productId: requireString(data.productId, `items[${index}].productId`),
    subtotal: requireMoney(data.subtotal, `items[${index}].subtotal`),
  };
}

function resolveOrderTotal(data: DocumentData, items: CommissionOrderItem[]): number {
  if (typeof data.total === 'number') return data.total;
  return roundMoney(
    items.reduce((sum, item) => sum + item.subtotal, 0) +
      money(data.surchargeAmount) +
      money(data.shippingAmount),
  );
}

function requireRuleType(value: unknown): CommissionRuleType {
  const type = requireString(value, 'type') as CommissionRuleType;
  if (type !== 'percentage' && type !== 'fixed') {
    throw new HttpsError('failed-precondition', 'Invalid commission rule type.');
  }
  return type;
}

function requireString(value: unknown, field: string): string {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new HttpsError('failed-precondition', `${field} is required.`);
  }
  return value.trim();
}

function optionalString(value: unknown): string | undefined {
  return typeof value === 'string' && value.trim().length > 0 ? value.trim() : undefined;
}

function stringArray(value: unknown): string[] {
  return Array.isArray(value)
    ? value.filter((item): item is string => typeof item === 'string' && item.trim().length > 0)
    : [];
}

function integer(value: unknown): number {
  return Number.isInteger(value) ? value as number : 0;
}

function requirePercent(value: unknown): number {
  if (typeof value !== 'number' || Number.isNaN(value) || value < 0 || value > 100) {
    throw new HttpsError('failed-precondition', 'percentage must stay between 0 and 100.');
  }
  return value;
}

function requireMoney(value: unknown, field: string): number {
  if (typeof value !== 'number' || Number.isNaN(value) || value < 0) {
    throw new HttpsError('failed-precondition', `${field} must be zero or greater.`);
  }
  return roundMoney(value);
}

function money(value: unknown): number {
  return typeof value === 'number' && Number.isFinite(value) ? roundMoney(value) : 0;
}

function roundMoney(value: number): number {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

function timestampToDate(value: unknown): Date | undefined {
  const timestamp = value as Timestamp | undefined;
  return typeof timestamp?.toDate === 'function' ? timestamp.toDate() : undefined;
}
