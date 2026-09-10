import { logger } from 'firebase-functions/v2';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { Timestamp, getFirestore, type DocumentData, type Firestore } from 'firebase-admin/firestore';

import { npsAggregateDocId, type NpsAggregateScope } from './nps-shared';

export interface AffectedNpsPeriod {
  organizationId: string;
  companyId: string;
  periodKey: string;
}

export interface NpsResponseFact {
  sellerId: string;
  category: 'promoter' | 'passive' | 'detractor';
}

export interface NpsAggregateBucket {
  scope: NpsAggregateScope;
  scopeId: string;
  promoters: number;
  passives: number;
  detractors: number;
}

/**
 * Reads the `organizationId`/`companyId`/`periodKey` an
 * `organizations/{orgId}/npsResponses/{responseId}` write belongs to.
 * Prefers `after` (create — `NpsResponse` documents are otherwise immutable,
 * see `submit-nps-response.ts`); falls back to `before` so a delete still
 * recomputes the period it used to belong to. Returns `null` for malformed
 * documents — nothing to recompute.
 */
export function resolveAffectedNpsPeriod(
  before: DocumentData | undefined,
  after: DocumentData | undefined,
): AffectedNpsPeriod | null {
  const data = after ?? before;
  if (
    !data ||
    typeof data.organizationId !== 'string' ||
    typeof data.companyId !== 'string' ||
    typeof data.periodKey !== 'string'
  ) {
    return null;
  }
  return {
    organizationId: data.organizationId,
    companyId: data.companyId,
    periodKey: data.periodKey,
  };
}

/**
 * Groups every [NpsResponseFact] of one company/month into its three
 * aggregate scopes (`tasks.md`: "cálculo de NPS agregado... por vendedor,
 * equipe e organização") — pure, no Firestore access, so it is exercised by
 * plain unit tests without an emulator (same "pure builder" precedent
 * `aggregations/aggregation-builders.ts` already establishes).
 *
 * `companyId` itself is the `organization`-scope's own `scopeId` — same
 * "company-wide scope has no further sub-scope" convention `salesDaily`
 * (TASK-133) already uses. A seller with no known team (never assigned one,
 * or the membership lookup failed to resolve one) still contributes to the
 * `seller`/`organization` buckets, just never to a `team` bucket.
 */
export function buildNpsAggregateBuckets(
  companyId: string,
  facts: readonly NpsResponseFact[],
  teamIdBySeller: ReadonlyMap<string, string | null>,
): NpsAggregateBucket[] {
  const organizationBucket = emptyBucket('organization', companyId);
  const sellerBuckets = new Map<string, NpsAggregateBucket>();
  const teamBuckets = new Map<string, NpsAggregateBucket>();

  for (const fact of facts) {
    accumulate(organizationBucket, fact.category);

    const sellerBucket =
      sellerBuckets.get(fact.sellerId) ?? emptyBucket('seller', fact.sellerId);
    accumulate(sellerBucket, fact.category);
    sellerBuckets.set(fact.sellerId, sellerBucket);

    const teamId = teamIdBySeller.get(fact.sellerId) ?? null;
    if (teamId) {
      const teamBucket = teamBuckets.get(teamId) ?? emptyBucket('team', teamId);
      accumulate(teamBucket, fact.category);
      teamBuckets.set(teamId, teamBucket);
    }
  }

  return [organizationBucket, ...sellerBuckets.values(), ...teamBuckets.values()];
}

function emptyBucket(scope: NpsAggregateScope, scopeId: string): NpsAggregateBucket {
  return { scope, scopeId, promoters: 0, passives: 0, detractors: 0 };
}

function accumulate(
  bucket: NpsAggregateBucket,
  category: NpsResponseFact['category'],
): void {
  if (category === 'promoter') bucket.promoters += 1;
  else if (category === 'passive') bucket.passives += 1;
  else bucket.detractors += 1;
}

/**
 * Batch strategy (documented trade-off, mirrors TASK-133's own
 * `recomputeSalesDailyForOrderChange`): on every write to an `NpsResponse`,
 * fully recompute — never incrementally patch — every `npsMonthlyAggregates`
 * bucket for the affected company/month. A targeted, single-period recompute
 * is cheap (an NPS survey is a low-volume event compared to orders) and
 * self-healing/idempotent (re-running it for the same period always
 * reproduces the exact same counts from the responses that exist right now).
 */
export async function recomputeNpsAggregatesForPeriod(
  affected: AffectedNpsPeriod,
  db: Firestore,
  generatedAt: Timestamp = Timestamp.now(),
): Promise<{ generatedSnapshots: number }> {
  const organizationRef = db.collection('organizations').doc(affected.organizationId);
  const responseSnapshot = await organizationRef
    .collection('npsResponses')
    .where('companyId', '==', affected.companyId)
    .where('periodKey', '==', affected.periodKey)
    .get();

  const facts: NpsResponseFact[] = responseSnapshot.docs
    .map((doc) => doc.data())
    .filter(
      (data): data is DocumentData =>
        typeof data.sellerId === 'string' && typeof data.category === 'string',
    )
    .map((data) => ({
      sellerId: data.sellerId as string,
      category: data.category as NpsResponseFact['category'],
    }));

  const sellerIds = [...new Set(facts.map((fact) => fact.sellerId))];
  const memberSnapshots = await Promise.all(
    sellerIds.map((sellerId) => organizationRef.collection('members').doc(sellerId).get()),
  );
  const teamIdBySeller = new Map<string, string | null>(
    sellerIds.map((sellerId, index) => {
      const teamIds = memberSnapshots[index].data()?.teamIds;
      const firstTeamId =
        Array.isArray(teamIds) && typeof teamIds[0] === 'string' ? (teamIds[0] as string) : null;
      return [sellerId, firstTeamId];
    }),
  );

  const buckets = buildNpsAggregateBuckets(affected.companyId, facts, teamIdBySeller);

  await Promise.all(
    buckets.map((bucket) => {
      const total = bucket.promoters + bucket.passives + bucket.detractors;
      const npsScore =
        total > 0 ? Math.round(((bucket.promoters - bucket.detractors) / total) * 1000) / 10 : null;
      const docId = npsAggregateDocId(
        affected.companyId,
        bucket.scope,
        bucket.scopeId,
        affected.periodKey,
      );
      return organizationRef.collection('npsMonthlyAggregates').doc(docId).set({
        organizationId: affected.organizationId,
        companyId: affected.companyId,
        scope: bucket.scope,
        scopeId: bucket.scopeId,
        periodKey: affected.periodKey,
        promoters: bucket.promoters,
        passives: bucket.passives,
        detractors: bucket.detractors,
        totalResponses: total,
        npsScore,
        generatedAt,
        version: 1,
      });
    }),
  );

  return { generatedSnapshots: buckets.length };
}

export const recomputeNpsMonthlyAggregates = onDocumentWritten(
  'organizations/{organizationId}/npsResponses/{responseId}',
  async (event) => {
    const affected = resolveAffectedNpsPeriod(
      event.data?.before.data(),
      event.data?.after.data(),
    );
    if (!affected) return;

    const startedAt = Date.now();
    try {
      const result = await recomputeNpsAggregatesForPeriod(affected, getFirestore());
      logger.info('recomputeNpsMonthlyAggregates completed', {
        organizationId: affected.organizationId,
        companyId: affected.companyId,
        periodKey: affected.periodKey,
        generatedSnapshots: result.generatedSnapshots,
        durationMs: Date.now() - startedAt,
      });
    } catch (error) {
      // Isolation by job — a failure recomputing NPS must never block the
      // response write itself nor any other aggregation pipeline (same
      // guarantee TASK-133 already requires of every aggregation trigger).
      logger.error('recomputeNpsMonthlyAggregates failed', {
        organizationId: affected.organizationId,
        companyId: affected.companyId,
        periodKey: affected.periodKey,
        durationMs: Date.now() - startedAt,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  },
);
