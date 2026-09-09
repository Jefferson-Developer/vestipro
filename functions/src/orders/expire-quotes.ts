import { logger } from 'firebase-functions/v2';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';

export const expireQuotes = onSchedule('every 60 minutes', async () => {
  const now = Timestamp.now();
  const snapshot = await getFirestore()
    .collectionGroup('quotes')
    .where('status', '==', 'sent')
    .where('expiresAt', '<=', now)
    .limit(500)
    .get();

  if (snapshot.empty) return;
  const batch = getFirestore().batch();
  snapshot.docs.forEach((doc) => {
    batch.set(doc.ref, {
      status: 'expired',
      updatedAt: now,
      updatedBy: 'system',
      version: FieldValue.increment(1),
    }, { merge: true });
  });
  await batch.commit();
  logger.info('expireQuotes marked quotes as expired', { count: snapshot.size });
});
