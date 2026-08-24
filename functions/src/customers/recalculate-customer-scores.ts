import { logger } from 'firebase-functions/v2';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import {
  Timestamp,
  getFirestore,
  type DocumentData,
  type Firestore,
  type QueryDocumentSnapshot,
  type UpdateData,
} from 'firebase-admin/firestore';
import {
  calculateCustomerScore,
  type CustomerScoringActivitySignal,
  type CustomerScoringCustomer,
  type CustomerScoringResult,
} from './customer-scoring-service';

export const CUSTOMER_SCORE_SCHEDULE_DESCRIPTION =
  'Daily at 03:00 America/Sao_Paulo';

export interface CustomerScoreRecalculationSummary {
  organizationsProcessed: number;
  customersScored: number;
  customersSkipped: number;
}

export const recalculateCustomerScores = onSchedule(
  {
    schedule: '0 3 * * *',
    timeZone: 'America/Sao_Paulo',
    region: 'southamerica-east1',
  },
  async () => {
    const summary = await recalculateCustomerScoresForAllOrganizations(
      getFirestore(),
      new Date(),
    );
    logger.info('Customer score recalculation finished', summary);
  },
);

export async function recalculateCustomerScoresForAllOrganizations(
  db: Firestore,
  now: Date,
): Promise<CustomerScoreRecalculationSummary> {
  const organizationsSnapshot = await db.collection('organizations').get();
  let organizationsProcessed = 0;
  let customersScored = 0;
  let customersSkipped = 0;

  for (const organizationDoc of organizationsSnapshot.docs) {
    const data = organizationDoc.data();
    if (data.deletedAt != null || data.status === 'inactive') {
      continue;
    }
    const summary = await recalculateCustomerScoresForOrganization(
      db,
      organizationDoc.id,
      now,
    );
    organizationsProcessed += 1;
    customersScored += summary.customersScored;
    customersSkipped += summary.customersSkipped;
  }

  return { organizationsProcessed, customersScored, customersSkipped };
}

export async function recalculateCustomerScoresForOrganization(
  db: Firestore,
  organizationId: string,
  now: Date,
): Promise<Omit<CustomerScoreRecalculationSummary, 'organizationsProcessed'>> {
  const organizationRef = db.collection('organizations').doc(organizationId);
  const [customersSnapshot, activitiesSnapshot] = await Promise.all([
    organizationRef.collection('customers').get(),
    organizationRef.collection('crmActivities').get(),
  ]);
  const activitiesByCustomer = groupActivitiesByCustomer(
    organizationId,
    activitiesSnapshot.docs,
  );
  let batch = db.batch();
  let pendingWrites = 0;
  let customersScored = 0;
  let customersSkipped = 0;

  const commitIfNeeded = async (force = false): Promise<void> => {
    if (pendingWrites === 0 || (!force && pendingWrites < 450)) {
      return;
    }
    await batch.commit();
    batch = db.batch();
    pendingWrites = 0;
  };

  for (const customerDoc of customersSnapshot.docs) {
    const customer = customerFromSnapshot(organizationId, customerDoc);
    if (!customer) {
      customersSkipped += 1;
      continue;
    }

    const data = customerDoc.data();
    const result = calculateCustomerScore({
      customer,
      now,
      crmActivities: activitiesByCustomer.get(customer.id) ?? [],
      purchaseCountLast12Months: numberOrUndefined(
        data.purchaseCountLast12Months,
      ),
      revenueLast12Months: numberOrUndefined(data.revenueLast12Months),
      currentPeriodRevenue: numberOrUndefined(data.currentPeriodRevenue),
      previousPeriodRevenue: numberOrUndefined(data.previousPeriodRevenue),
      overdueFollowUps: numberOrUndefined(data.overdueFollowUps) ?? 0,
    });

    batch.update(customerDoc.ref, buildCustomerScoreUpdate(result));
    pendingWrites += 1;
    customersScored += 1;
    await commitIfNeeded();
  }

  await commitIfNeeded(true);
  return { customersScored, customersSkipped };
}

export function buildCustomerScoreUpdate(
  result: CustomerScoringResult,
): UpdateData<DocumentData> {
  return {
    commercialScore: result.commercialScore,
    healthScore: result.healthScore,
    healthScoreBand: result.healthScoreBand,
    scoreUpdatedAt: Timestamp.fromDate(result.scoreUpdatedAt),
    scoreFormulaVersion: result.scoreFormulaVersion,
    scoreDataCoverage: result.scoreDataCoverage,
  };
}

function customerFromSnapshot(
  organizationId: string,
  snapshot: QueryDocumentSnapshot<DocumentData>,
): CustomerScoringCustomer | null {
  const data = snapshot.data();
  if (data.organizationId !== organizationId) {
    return null;
  }
  const registeredAt = dateFromFirestore(data.registeredAt);
  if (!registeredAt) {
    return null;
  }
  return {
    id: snapshot.id,
    organizationId,
    registeredAt,
    lastPurchaseAt: dateFromFirestore(data.lastPurchaseAt),
    potential: stringOrNull(data.potential),
    status: stringOrNull(data.status),
  };
}

function groupActivitiesByCustomer(
  organizationId: string,
  snapshots: Array<QueryDocumentSnapshot<DocumentData>>,
): Map<string, CustomerScoringActivitySignal[]> {
  const grouped = new Map<string, CustomerScoringActivitySignal[]>();
  snapshots.forEach((snapshot) => {
    const data = snapshot.data();
    if (data.organizationId !== organizationId) {
      return;
    }
    const customerId = stringOrNull(data.customerId);
    const occurredAt = dateFromFirestore(data.occurredAt);
    if (!customerId || !occurredAt) {
      return;
    }
    const current = grouped.get(customerId) ?? [];
    current.push({ organizationId, customerId, occurredAt });
    grouped.set(customerId, current);
  });
  return grouped;
}

function dateFromFirestore(value: unknown): Date | undefined {
  if (value instanceof Timestamp) {
    return value.toDate();
  }
  if (value instanceof Date) {
    return value;
  }
  if (typeof value === 'string') {
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? undefined : parsed;
  }
  return undefined;
}

function numberOrUndefined(value: unknown): number | undefined {
  return typeof value === 'number' && Number.isFinite(value) ? value : undefined;
}

function stringOrNull(value: unknown): string | null {
  return typeof value === 'string' ? value : null;
}
