import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';
import { HttpsError, onRequest } from 'firebase-functions/v2/https';

import {
  extractPaymentWebhookEvent,
  requireNonEmptyString,
  resolvePaymentStatus,
  verifyPaymentWebhookSignature,
} from './payment-shared';

export const handlePaymentWebhook = onRequest(async (request, response) => {
  if (request.method !== 'POST') {
    response.sendStatus(405);
    return;
  }
  const organizationId = requireQueryString(request.query.organizationId, 'organizationId');
  const providerId = requireQueryString(request.query.providerId, 'providerId');
  const db = getFirestore();
  const orgRef = db.collection('organizations').doc(organizationId);
  const secretSnapshot = await orgRef.collection('paymentWebhookSecrets').doc(providerId).get();
  const webhookSecret = requireNonEmptyString(secretSnapshot.data()?.webhookSecret, 'webhookSecret');
  if (!verifyPaymentWebhookSignature(webhookSecret, request.rawBody, request.header('x-vestipro-payment-signature'))) {
    response.sendStatus(403);
    return;
  }

  try {
    const event = extractPaymentWebhookEvent(request.body);
    if (event.providerId !== providerId) {
      throw new HttpsError('invalid-argument', 'providerId mismatch.');
    }
    await db.runTransaction(async (transaction) => {
      const eventRef = orgRef.collection('paymentWebhookEvents').doc(event.eventId);
      const eventSnapshot = await transaction.get(eventRef);
      if (eventSnapshot.exists) return;
      const txRef = orgRef.collection('paymentTransactions').doc(event.transactionId);
      const txSnapshot = await transaction.get(txRef);
      const txData = txSnapshot.data();
      if (!txSnapshot.exists || !txData) {
        throw new HttpsError('not-found', 'Payment transaction not found.');
      }
      const nextStatus = resolvePaymentStatus(txData.status, event.status);
      const now = Timestamp.now();
      transaction.set(eventRef, {
        ...event,
        organizationId,
        receivedAt: now,
      });
      transaction.set(txRef, {
        status: nextStatus,
        gatewayTransactionId: event.gatewayTransactionId ?? txData.gatewayTransactionId ?? null,
        reason: event.reason ?? txData.reason ?? null,
        history: FieldValue.arrayUnion({
          type: 'gateway_webhook',
          eventId: event.eventId,
          status: event.status,
          resolvedStatus: nextStatus,
          reason: event.reason ?? null,
          at: now,
        }),
        updatedAt: now,
        updatedBy: 'payment_webhook',
        version: FieldValue.increment(1),
      }, { merge: true });
    });
    response.sendStatus(200);
  } catch {
    response.sendStatus(400);
  }
});

function requireQueryString(value: unknown, field: string): string {
  const raw = Array.isArray(value) ? value[0] : value;
  return requireNonEmptyString(raw, field);
}
