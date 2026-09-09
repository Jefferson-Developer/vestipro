import { logger } from 'firebase-functions/v2';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { getFirestore } from 'firebase-admin/firestore';

import { isCommissionableOrderStatus, isReversalOrderStatus } from './commission-shared';
import { calculateOrderCommissionTransaction } from './calculate-order-commission';

export const calculateOrderCommissionOnWrite = onDocumentWritten(
  'organizations/{organizationId}/orders/{orderId}',
  async (event) => {
    const organizationId = event.params.organizationId;
    const orderId = event.params.orderId;
    const after = event.data?.after.data();
    if (!after) return;
    const beforeStatus = event.data?.before.data()?.status;
    const afterStatus = typeof after.status === 'string' ? after.status : '';
    if (beforeStatus === afterStatus && event.data?.before.exists) return;
    if (!isCommissionableOrderStatus(afterStatus) && !isReversalOrderStatus(afterStatus)) return;

    await calculateOrderCommissionTransaction(getFirestore(), {
      organizationId,
      orderId,
      actorId: 'system',
      actorName: 'Sistema',
      sourceEventId: event.id,
    });
    logger.info('Order commission trigger processed', { organizationId, orderId, afterStatus });
  },
);
