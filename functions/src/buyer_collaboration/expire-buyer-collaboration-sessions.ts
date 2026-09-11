import { logger } from 'firebase-functions/v2';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';

const NON_TERMINAL_STATUSES = ['seller_draft', 'buyer_review', 'changes_requested', 'buyer_approved'];

/**
 * Lazily-computed expiry (`effectiveStatus` in `buyer-collaboration-shared`)
 * already keeps every read correct even before this runs; this scheduled
 * job (mirrors `expireQuotes`) just persists `status: 'expired'` so listings
 * that query by `status` (e.g. a seller's "sessões pendentes" screen) do not
 * have to also re-derive expiry client-side.
 */
export const expireBuyerCollaborationSessions = onSchedule('every 60 minutes', async () => {
  const now = Timestamp.now();
  const db = getFirestore();
  let totalExpired = 0;
  for (const status of NON_TERMINAL_STATUSES) {
    const snapshot = await db
      .collectionGroup('buyerCollaborationSessions')
      .where('status', '==', status)
      .where('expiresAt', '<=', now)
      .limit(500)
      .get();
    if (snapshot.empty) continue;
    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.set(doc.ref, {
        status: 'expired',
        updatedAt: now,
        updatedBy: 'system',
        version: FieldValue.increment(1),
      }, { merge: true });
    });
    await batch.commit();
    totalExpired += snapshot.size;
  }
  logger.info('expireBuyerCollaborationSessions marked sessions as expired', { count: totalExpired });
});
