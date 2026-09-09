import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';

import type { PaymentTransactionStatus } from './payment-shared';

const ORDER_FINANCIAL_STATUS: Readonly<Record<PaymentTransactionStatus, string>> = {
  pending: 'payment_pending',
  processing: 'payment_pending',
  approved: 'payment_approved',
  declined: 'payment_declined',
  refunded: 'payment_refunded',
  failed: 'payment_failed',
};

export const reconcilePaymentTransactionToOrder = onDocumentWritten(
  'organizations/{organizationId}/paymentTransactions/{transactionId}',
  async (event) => {
    const after = event.data?.after.data();
    if (!after) return;
    const beforeStatus = event.data?.before.data()?.status as string | undefined;
    const status = after.status as PaymentTransactionStatus;
    if (beforeStatus === status) return;
    const financialStatus = ORDER_FINANCIAL_STATUS[status];
    if (!financialStatus) return;
    await getFirestore()
      .collection('organizations')
      .doc(event.params.organizationId)
      .collection('orders')
      .doc(after.orderId as string)
      .set({
        financialStatus,
        paymentTransactionId: event.params.transactionId,
        paymentProviderId: after.providerId,
        paymentUpdatedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        updatedBy: 'payment_reconciliation',
        version: FieldValue.increment(1),
      }, { merge: true });
  },
);
