import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { getFirestore } from 'firebase-admin/firestore';

import { loadActiveMembership } from '../invites/invite-shared';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { requireNonEmptyString } from './payment-shared';
import { serializePaymentTransaction, type PaymentTransactionResponse } from './create-payment-charge';

export interface GetPaymentStatusRequest extends RequestWithMeta {
  organizationId?: string;
  transactionId?: string;
}

const ROLES_ALLOWED_TO_READ_PAYMENT: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
  'SALES_MANAGER',
  'SALES_REP',
  'FINANCE',
]);

export const getPaymentStatus = onCall<
  GetPaymentStatusRequest,
  Promise<PaymentTransactionResponse>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);
  if (!request.auth) throw new HttpsError('unauthenticated', 'Autenticacao obrigatoria.');
  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const transactionId = requireNonEmptyString(request.data?.transactionId, 'transactionId');
  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, request.auth.uid);
  if (!ROLES_ALLOWED_TO_READ_PAYMENT.has(membership.roleName)) {
    throw new HttpsError('permission-denied', 'Seu perfil nao pode consultar pagamentos.');
  }
  const snapshot = await db
    .collection('organizations')
    .doc(organizationId)
    .collection('paymentTransactions')
    .doc(transactionId)
    .get();
  const data = snapshot.data();
  if (!snapshot.exists || !data) {
    throw new HttpsError('not-found', 'Transacao de pagamento nao encontrada.');
  }
  if (membership.roleName === 'SALES_REP') {
    const order = await db
      .collection('organizations')
      .doc(organizationId)
      .collection('orders')
      .doc(data.orderId as string)
      .get();
    if (order.data()?.sellerId !== request.auth.uid) {
      throw new HttpsError('permission-denied', 'Representante so consulta seus pagamentos.');
    }
  }
  return serializePaymentTransaction(transactionId, data, correlationId);
});
