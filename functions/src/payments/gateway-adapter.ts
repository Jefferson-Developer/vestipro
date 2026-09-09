import { HttpsError } from 'firebase-functions/v2/https';

import type { PaymentProvider, PaymentTransactionStatus } from './payment-shared';

export interface PaymentGatewayChargeInput {
  provider: PaymentProvider;
  transactionId: string;
  idempotencyKey: string;
  orderId: string;
  amount: number;
  currency: string;
}

export interface PaymentGatewayChargeResult {
  gatewayTransactionId: string;
  status: PaymentTransactionStatus;
  reason?: string;
}

export async function createGatewayCharge(
  input: PaymentGatewayChargeInput,
): Promise<PaymentGatewayChargeResult> {
  if (input.provider.mockMode === 'unavailable') {
    throw new HttpsError('unavailable', 'Gateway de pagamento indisponivel.');
  }
  if (input.provider.mockMode === 'declined') {
    return {
      gatewayTransactionId: `declined_${input.transactionId}`,
      status: 'declined',
      reason: 'Pagamento recusado pelo gateway.',
    };
  }
  return {
    gatewayTransactionId: `${input.provider.gateway}_${input.transactionId}`,
    status: 'processing',
  };
}
