import { logger } from 'firebase-functions/v2';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import {
  Timestamp,
  getFirestore,
  type DocumentData,
  type Firestore,
} from 'firebase-admin/firestore';

import {
  parseDailyRepSummaryPreferences,
  resolveDailyRepSummaryDeliveryTime,
} from '../daily_rep_summary/daily-rep-summary-notification';
import { classifyReceivableReminder, mapReceivable, type Receivable } from './receivables-shared';

/** Once a `dueSoon` reminder fires for a receivable it never repeats (the
 * window is only `RECEIVABLE_DUE_SOON_WINDOW_DAYS` wide, so a single alert is
 * enough warning); an `overdue` receivable keeps escalating weekly while it
 * remains unpaid — long enough to not spam the vendedor daily, short enough
 * that a título vencido is never silently forgotten for a whole month. */
const DUE_SOON_COOLDOWN_DAYS = 90;
const OVERDUE_COOLDOWN_DAYS = 7;
const MS_PER_DAY = 24 * 60 * 60 * 1000;

/**
 * Daily lembretes de cobrança (TASK-213, EPIC-32/EPIC-19) — the third
 * server-side notification generator in this codebase (after
 * `generateDailyRepSummary`), following the exact same shape: read
 * `communicationPreferences`/`quietHours` for the recipient (the pedido's own
 * `sellerId` — the vendedor responsible for that customer's relationship,
 * same "quem já pode agir sobre este pedido" scope `postSaleEventRegister`'s
 * own capability doc uses) via `daily-rep-summary-notification.ts`'s reusable
 * ports, and only ever writes the `commercial`/`inApp` central de
 * notificações entry when the recipient still allows it — quiet hours delay
 * `deliverAt`, never suppress the notification outright.
 */
export const generateBillingReminders = onSchedule(
  {
    schedule: 'every day 06:30',
    timeZone: 'America/Sao_Paulo',
    region: 'southamerica-east1',
  },
  async () => {
    await generateBillingRemindersScheduledHandler();
  },
);

export async function generateBillingRemindersScheduledHandler(now = new Date()): Promise<void> {
  const db = getFirestore();
  const nowTimestamp = Timestamp.fromDate(now);
  const organizationsSnapshot = await db.collection('organizations').get();

  for (const organization of organizationsSnapshot.docs) {
    const data = organization.data();
    if (data.status !== 'active' || data.deletedAt != null) continue;

    const receivablesSnapshot = await organization.ref
      .collection('receivables')
      .where('status', 'in', ['open', 'overdue', 'partially_paid'])
      .get();

    for (const doc of receivablesSnapshot.docs) {
      const receivable = mapReceivable(doc.id, doc.data());
      if (!receivable.sellerId) continue;

      const classification = classifyReceivableReminder(receivable, nowTimestamp);
      if (classification === 'none') continue;

      await processReceivableReminder({
        db,
        organizationId: organization.id,
        receivable,
        classification,
        now,
      });
    }
  }
}

async function processReceivableReminder(params: {
  db: Firestore;
  organizationId: string;
  receivable: Receivable;
  classification: 'dueSoon' | 'overdue';
  now: Date;
}): Promise<void> {
  const { db, organizationId, receivable, classification, now } = params;
  const organizationRef = db.collection('organizations').doc(organizationId);
  const dispatchRef = organizationRef
    .collection('billingReminderDispatches')
    .doc(`${receivable.id}:${classification}`);

  const dispatchSnapshot = await dispatchRef.get();
  const lastDispatchedAt = (dispatchSnapshot.data()?.dispatchedAt as Timestamp | undefined)?.toDate();
  const cooldownDays = classification === 'overdue' ? OVERDUE_COOLDOWN_DAYS : DUE_SOON_COOLDOWN_DAYS;
  if (lastDispatchedAt && now.getTime() - lastDispatchedAt.getTime() < cooldownDays * MS_PER_DAY) {
    return;
  }

  let preferencesData: DocumentData | undefined;
  try {
    const preferencesSnapshot = await organizationRef
      .collection('communicationPreferences')
      .doc(receivable.sellerId as string)
      .get();
    preferencesData = preferencesSnapshot.data();
  } catch (error) {
    // Fails open — same precedent `generateDailyRepSummary`'s own
    // `tryDispatchNotification` already documents: an unreadable preference
    // must never silently swallow a lembrete de cobrança.
    logger.warn('generateBillingReminders failed to read communication preferences', {
      organizationId,
      receivableId: receivable.id,
      sellerId: receivable.sellerId,
      error: error instanceof Error ? error.message : String(error),
    });
  }

  const { allowsCommercialInApp, quietHours } = parseDailyRepSummaryPreferences(preferencesData);
  if (!allowsCommercialInApp) return;

  const deliverAt = resolveDailyRepSummaryDeliveryTime(quietHours, now);
  const notificationRef = organizationRef.collection('notifications').doc();
  await notificationRef.set({
    organizationId,
    userId: receivable.sellerId,
    category: 'commercial',
    title: classification === 'overdue' ? 'Título vencido em aberto' : 'Título próximo do vencimento',
    body:
      classification === 'overdue'
        ? 'Um título deste cliente está vencido. Priorize o contato de cobrança.'
        : 'Um título deste cliente vence em breve. Antecipe o contato com o cliente.',
    deepLink: `/org/${organizationId}/customers/${receivable.customerId}`,
    createdAt: Timestamp.fromDate(now),
    readAt: null,
    priority: 'informative',
    deliverAt: deliverAt == null ? null : Timestamp.fromDate(deliverAt),
    customerId: receivable.customerId,
  });

  await dispatchRef.set({
    organizationId,
    receivableId: receivable.id,
    classification,
    dispatchedAt: Timestamp.fromDate(now),
  });

  logger.info('generateBillingReminders dispatched', {
    organizationId,
    receivableId: receivable.id,
    sellerId: receivable.sellerId,
    classification,
  });
}
