import { createHash, createHmac, timingSafeEqual } from 'node:crypto';

import { HttpsError } from 'firebase-functions/v2/https';
import type { DocumentData, Timestamp } from 'firebase-admin/firestore';

export type PaymentProviderStatus = 'active' | 'inactive';
export type PaymentTransactionStatus =
  | 'pending'
  | 'processing'
  | 'approved'
  | 'declined'
  | 'refunded'
  | 'failed';

export interface PaymentProvider {
  id: string;
  gateway: string;
  status: PaymentProviderStatus;
  companyId?: string;
  country: string;
  supportedCurrencies: string[];
  credentialsSecretName: string;
  webhookSecretId?: string;
  mockMode?: 'success' | 'unavailable' | 'declined';
}

export interface PaymentWebhookEvent {
  eventId: string;
  providerId: string;
  transactionId: string;
  gatewayTransactionId?: string;
  status: PaymentTransactionStatus;
  reason?: string;
  occurredAt?: string;
}

const STATUS_RANK: Readonly<Record<PaymentTransactionStatus, number>> = {
  pending: 0,
  processing: 1,
  failed: 2,
  declined: 3,
  approved: 4,
  refunded: 5,
};

export function requireNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new HttpsError('invalid-argument', `${field} is required.`);
  }
  return value.trim();
}

export function optionalString(value: unknown): string | undefined {
  if (typeof value !== 'string') return undefined;
  const trimmed = value.trim();
  return trimmed.length === 0 ? undefined : trimmed;
}

export function normalizeMoney(value: unknown, field: string): number {
  if (typeof value !== 'number' || Number.isNaN(value) || value < 0) {
    throw new HttpsError('invalid-argument', `${field} must be zero or greater.`);
  }
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

export function normalizeCurrencyCode(value: unknown): string {
  const code = requireNonEmptyString(value, 'currency').toUpperCase();
  if (!/^[A-Z]{3}$/.test(code)) {
    throw new HttpsError('invalid-argument', 'currency must be an ISO 4217 code.');
  }
  return code;
}

export function computePaymentIdempotencyKey(orderId: string, attempt: number): string {
  if (!Number.isInteger(attempt) || attempt <= 0) {
    throw new HttpsError('invalid-argument', 'attempt must be a positive integer.');
  }
  return `${orderId}:${attempt}`;
}

export function computePaymentTransactionId(idempotencyKey: string): string {
  return createHash('sha256').update(idempotencyKey).digest('hex');
}

export function mapPaymentProvider(id: string, data: DocumentData | undefined): PaymentProvider {
  if (!data) throw new HttpsError('failed-precondition', 'Payment provider missing.');
  return {
    id,
    gateway: requireNonEmptyString(data.gateway, 'gateway'),
    status: requireNonEmptyString(data.status, 'status') as PaymentProviderStatus,
    companyId: optionalString(data.companyId),
    country: requireNonEmptyString(data.country, 'country').toUpperCase(),
    supportedCurrencies: Array.isArray(data.supportedCurrencies)
      ? data.supportedCurrencies
        .filter((value): value is string => typeof value === 'string')
        .map((value) => value.toUpperCase())
      : [],
    credentialsSecretName: requireNonEmptyString(
      data.credentialsSecretName,
      'credentialsSecretName',
    ),
    webhookSecretId: optionalString(data.webhookSecretId),
    mockMode: optionalString(data.mockMode) as PaymentProvider['mockMode'],
  };
}

export function selectPaymentProvider(
  providers: readonly PaymentProvider[],
  input: { companyId: string; country: string; currency: string },
): PaymentProvider {
  const country = input.country.toUpperCase();
  const currency = input.currency.toUpperCase();
  const provider = providers
    .filter((candidate) =>
      candidate.status === 'active' &&
      candidate.country === country &&
      candidate.supportedCurrencies.includes(currency) &&
      (candidate.companyId === undefined || candidate.companyId === input.companyId),
    )
    .sort((left, right) => {
      const leftCompany = left.companyId === input.companyId ? 0 : 1;
      const rightCompany = right.companyId === input.companyId ? 0 : 1;
      return leftCompany - rightCompany || left.id.localeCompare(right.id);
    })[0];
  if (!provider) {
    throw new HttpsError(
      'failed-precondition',
      'Nenhum gateway de pagamento ativo atende este pedido.',
    );
  }
  return provider;
}

export function resolvePaymentStatus(
  current: PaymentTransactionStatus,
  incoming: PaymentTransactionStatus,
): PaymentTransactionStatus {
  return STATUS_RANK[incoming] >= STATUS_RANK[current] ? incoming : current;
}

export function signPaymentWebhookPayload(secret: string, rawBody: Buffer | string): string {
  return createHmac('sha256', secret).update(rawBody).digest('hex');
}

export function verifyPaymentWebhookSignature(
  secret: string,
  rawBody: Buffer | string,
  signatureHex: string | undefined,
): boolean {
  if (!signatureHex) return false;
  const expected = Buffer.from(signPaymentWebhookPayload(secret, rawBody), 'hex');
  const actual = Buffer.from(signatureHex, 'hex');
  return expected.length === actual.length && timingSafeEqual(expected, actual);
}

export function extractPaymentWebhookEvent(body: unknown): PaymentWebhookEvent {
  const payload = body as Record<string, unknown> | null;
  if (!payload || typeof payload !== 'object') {
    throw new HttpsError('invalid-argument', 'Invalid webhook payload.');
  }
  return {
    eventId: requireNonEmptyString(payload.eventId, 'eventId'),
    providerId: requireNonEmptyString(payload.providerId, 'providerId'),
    transactionId: requireNonEmptyString(payload.transactionId, 'transactionId'),
    gatewayTransactionId: optionalString(payload.gatewayTransactionId),
    status: requirePaymentStatus(payload.status),
    reason: optionalString(payload.reason),
    occurredAt: optionalString(payload.occurredAt),
  };
}

export function requirePaymentStatus(value: unknown): PaymentTransactionStatus {
  const status = requireNonEmptyString(value, 'status') as PaymentTransactionStatus;
  if (!Object.prototype.hasOwnProperty.call(STATUS_RANK, status)) {
    throw new HttpsError('invalid-argument', 'Invalid payment status.');
  }
  return status;
}

export function serializeTimestamp(value: unknown): string | undefined {
  const timestamp = value as Timestamp | undefined;
  return typeof timestamp?.toDate === 'function'
    ? timestamp.toDate().toISOString()
    : undefined;
}
