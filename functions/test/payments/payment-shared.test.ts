import { HttpsError } from 'firebase-functions/v2/https';

import {
  computePaymentIdempotencyKey,
  computePaymentTransactionId,
  extractPaymentWebhookEvent,
  mapPaymentProvider,
  resolvePaymentStatus,
  selectPaymentProvider,
  signPaymentWebhookPayload,
  verifyPaymentWebhookSignature,
} from '../../src/payments/payment-shared';
import { createGatewayCharge } from '../../src/payments/gateway-adapter';

describe('payment gateway shared rules', () => {
  it('derives a mandatory idempotency key from order and attempt', () => {
    expect(computePaymentIdempotencyKey('order-1', 2)).toBe('order-1:2');
    expect(computePaymentTransactionId('order-1:2')).toHaveLength(64);
    expect(() => computePaymentIdempotencyKey('order-1', 0)).toThrow(HttpsError);
  });

  it('selects the active provider by company, country and currency', () => {
    const provider = selectPaymentProvider([
      mapPaymentProvider('global-brl', {
        gateway: 'generic',
        status: 'active',
        country: 'BR',
        supportedCurrencies: ['BRL'],
        credentialsSecretName: 'projects/demo/secrets/global-brl',
      }),
      mapPaymentProvider('company-brl', {
        gateway: 'generic',
        status: 'active',
        companyId: 'company-1',
        country: 'BR',
        supportedCurrencies: ['BRL'],
        credentialsSecretName: 'projects/demo/secrets/company-brl',
      }),
    ], {
      companyId: 'company-1',
      country: 'br',
      currency: 'brl',
    });

    expect(provider.id).toBe('company-brl');
  });

  it('does not regress payment status for duplicate or out-of-order webhooks', () => {
    expect(resolvePaymentStatus('approved', 'processing')).toBe('approved');
    expect(resolvePaymentStatus('approved', 'refunded')).toBe('refunded');
    expect(resolvePaymentStatus('declined', 'failed')).toBe('declined');
  });

  it('verifies webhook signatures against the raw payload', () => {
    const rawBody = Buffer.from(JSON.stringify({ eventId: 'evt-1' }));
    const signature = signPaymentWebhookPayload('secret', rawBody);

    expect(verifyPaymentWebhookSignature('secret', rawBody, signature)).toBe(true);
    expect(verifyPaymentWebhookSignature('secret', rawBody, 'bad')).toBe(false);
  });

  it('extracts normalized webhook events and rejects invalid statuses', () => {
    expect(extractPaymentWebhookEvent({
      eventId: 'evt-1',
      providerId: 'provider-1',
      transactionId: 'tx-1',
      status: 'approved',
      reason: 'ok',
    })).toMatchObject({
      eventId: 'evt-1',
      providerId: 'provider-1',
      transactionId: 'tx-1',
      status: 'approved',
    });

    expect(() => extractPaymentWebhookEvent({
      eventId: 'evt-2',
      providerId: 'provider-1',
      transactionId: 'tx-1',
      status: 'paid',
    })).toThrow(HttpsError);
  });

  it('maps gateway unavailability and declined responses without exposing credentials', async () => {
    await expect(createGatewayCharge({
      provider: mapPaymentProvider('provider-1', {
        gateway: 'generic',
        status: 'active',
        country: 'BR',
        supportedCurrencies: ['BRL'],
        credentialsSecretName: 'projects/demo/secrets/provider-1',
        mockMode: 'unavailable',
      }),
      transactionId: 'tx-1',
      idempotencyKey: 'order-1:1',
      orderId: 'order-1',
      amount: 100,
      currency: 'BRL',
    })).rejects.toMatchObject({ code: 'unavailable' });

    await expect(createGatewayCharge({
      provider: mapPaymentProvider('provider-1', {
        gateway: 'generic',
        status: 'active',
        country: 'BR',
        supportedCurrencies: ['BRL'],
        credentialsSecretName: 'projects/demo/secrets/provider-1',
        mockMode: 'declined',
      }),
      transactionId: 'tx-1',
      idempotencyKey: 'order-1:1',
      orderId: 'order-1',
      amount: 100,
      currency: 'BRL',
    })).resolves.toMatchObject({ status: 'declined' });
  });
});
