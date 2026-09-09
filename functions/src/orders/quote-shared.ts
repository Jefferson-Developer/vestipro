import { HttpsError } from 'firebase-functions/v2/https';
import { Timestamp, type DocumentData } from 'firebase-admin/firestore';

export interface QuoteResponse {
  quoteId: string;
  organizationId: string;
  companyId: string;
  orderDraftId: string;
  customerId: string;
  sellerId: string;
  priceListId: string;
  paymentTermId: string;
  currency: string;
  subtotal: number;
  discountAmount: number;
  surchargeAmount: number;
  shippingAmount: number;
  total: number;
  status: string;
  expiresAt: string;
  createdAt: string;
  itemCount: number;
}

export function serializeQuote(quoteId: string, data: DocumentData): QuoteResponse {
  return {
    quoteId,
    organizationId: requireString(data.organizationId, 'organizationId'),
    companyId: requireString(data.companyId, 'companyId'),
    orderDraftId: requireString(data.orderDraftId, 'orderDraftId'),
    customerId: requireString(data.customerId, 'customerId'),
    sellerId: requireString(data.sellerId, 'sellerId'),
    priceListId: requireString(data.priceListId, 'priceListId'),
    paymentTermId: requireString(data.paymentTermId, 'paymentTermId'),
    currency: requireString(data.currency, 'currency'),
    subtotal: asNumber(data.subtotal),
    discountAmount: asNumber(data.discountAmount),
    surchargeAmount: asNumber(data.surchargeAmount),
    shippingAmount: asNumber(data.shippingAmount),
    total: asNumber(data.total),
    status: requireString(data.status, 'status'),
    expiresAt: serializeTimestamp(data.expiresAt),
    createdAt: serializeTimestamp(data.createdAt),
    itemCount: Array.isArray(data.items) ? data.items.length : 0,
  };
}

export function serializeTimestamp(value: unknown): string {
  if (value instanceof Timestamp) return value.toDate().toISOString();
  if (value instanceof Date) return value.toISOString();
  if (typeof value === 'string') return new Date(value).toISOString();
  throw new HttpsError('internal', 'Invalid quote timestamp.');
}

export function asNumber(value: unknown): number {
  return typeof value === 'number' && !Number.isNaN(value) ? value : 0;
}

function requireString(value: unknown, field: string): string {
  if (typeof value === 'string' && value.length > 0) return value;
  throw new HttpsError('internal', `Invalid quote ${field}.`);
}
