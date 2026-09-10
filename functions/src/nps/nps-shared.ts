import { HttpsError } from 'firebase-functions/v2/https';
import {
  Timestamp,
  type DocumentData,
  type DocumentReference,
  type Firestore,
  type Transaction,
} from 'firebase-admin/firestore';

/**
 * The two pós-venda milestones (TASK-201, `postSaleEvents.type`) that ever
 * trigger an NPS survey (TASK-202, EPIC-30, `tasks.md`: "disparada por
 * eventos como entrega confirmada ou resolução de um problema reportado") —
 * every other milestone (`dispatched`/`in_transit`/`problem_reported`/
 * `in_resolution`/`return_requested`/`return_resolved`/`exchange_requested`/
 * `exchange_resolved`) never triggers a pesquisa: asking a customer "how
 * satisfied are you" only makes sense once their pedido actually reached
 * them (`delivered`) or once a problem they reported was actually solved
 * (`resolved`).
 */
export const NPS_TRIGGER_MILESTONES: ReadonlySet<string> = new Set<string>([
  'delivered',
  'resolved',
]);

export const NPS_SURVEY_EXPIRATION_DAYS = 30;
const MS_PER_DAY = 24 * 60 * 60 * 1000;

export type NpsSurveyStatus = 'pending' | 'answered' | 'expired';
export type NpsSurveyOutcome = NpsSurveyStatus | 'notFound';
export type NpsAggregateScope = 'seller' | 'team' | 'organization';
export type NpsScoreCategory = 'promoter' | 'passive' | 'detractor';

/** The base URL every NPS response link is built from — same "hardcoded
 * today, no dedicated config surface yet" precedent already accepted by
 * `CatalogShareSheet.kCatalogShareBaseUrl`
 * (`lib/features/catalog_share/presentation/widgets/catalog_share_sheet.dart`). */
export const NPS_SURVEY_BASE_URL = 'https://app.vestipro.com.br/nps';

/** One pedido/marco pair only ever gets a single `NpsSurveyRequest`
 * (`tasks.md`: "evitar disparo duplicado de pesquisa para o mesmo marco do
 * mesmo pedido") — this is both the idempotency key `triggerNpsSurvey`
 * checks before creating anything and the resulting document id, same
 * "client/caller-independent, order+milestone-derived id" precedent
 * `registerPostSaleEvent`'s own `eventId` establishes for its own
 * idempotency (except here nothing external ever supplies it: it is always
 * derived, never client-provided). */
export function npsSurveyRequestDocId(
  orderId: string,
  milestoneType: string,
): string {
  return `${orderId}_${milestoneType}`;
}

/** `promoter` (9-10), `passive` (7-8) or `detractor` (0-6) — the standard NPS
 * categorization, the single definition every NPS aggregate in this codebase
 * must use (`tasks.md`: "fórmula única e documentada"). */
export function npsCategoryOf(score: number): NpsScoreCategory {
  if (score >= 9) return 'promoter';
  if (score >= 7) return 'passive';
  return 'detractor';
}

/**
 * The one NPS formula every aggregate in this codebase computes with
 * (`tasks.md`: "cálculo de NPS agregado... nunca recalculado ad hoc no
 * cliente... fórmula única e documentada"): `(promoters - detractors) /
 * total * 100`. Returns `null` (never `0`, never `NaN`) when [total] is zero
 * — an empty period has no score to show, not a score of zero.
 */
export function computeNpsScore(
  promoters: number,
  detractors: number,
  total: number,
): number | null {
  if (total <= 0) return null;
  return Math.round(((promoters - detractors) / total) * 1000) / 10;
}

export function requireScore(value: unknown): number {
  if (
    typeof value !== 'number' ||
    !Number.isInteger(value) ||
    value < 0 ||
    value > 10
  ) {
    throw new HttpsError(
      'invalid-argument',
      'score deve ser um número inteiro entre 0 e 10.',
    );
  }
  return value;
}

const MAX_COMMENT_LENGTH = 1000;

export function optionalComment(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  if (trimmed.length === 0) return null;
  if (trimmed.length > MAX_COMMENT_LENGTH) {
    return trimmed.slice(0, MAX_COMMENT_LENGTH);
  }
  return trimmed;
}

export function requireNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new HttpsError('invalid-argument', `${field} is required.`);
  }
  return value.trim();
}

/**
 * Resolves the outcome an already-found `NpsSurveyRequest` document is in
 * *right now* — mirrors `catalog/catalog-share-shared.ts`'s
 * `resolveCatalogShareOutcome`: `'answered'` is always trusted as stored
 * (nothing un-answers a survey), `'expired'` is always computed lazily from
 * `expiresAt` vs. [now] (never from a stored value), anything else is
 * `'pending'`.
 */
export function resolveNpsSurveyOutcome(
  data: DocumentData,
  now: Timestamp,
): NpsSurveyStatus {
  if (data.status === 'answered') return 'answered';
  const expiresAt = data.expiresAt as Timestamp;
  if (expiresAt.toMillis() <= now.toMillis()) return 'expired';
  return 'pending';
}

export function npsSurveyExpiresAt(now: Timestamp): Timestamp {
  return Timestamp.fromMillis(
    now.toMillis() + NPS_SURVEY_EXPIRATION_DAYS * MS_PER_DAY,
  );
}

export interface NpsSurveyLookup {
  ref: DocumentReference;
  organizationRef: DocumentReference;
  data: DocumentData;
}

/**
 * Finds the (at most one) `NpsSurveyRequest` document anywhere in Firestore
 * whose `tokenHash` equals [tokenHash] — same `collectionGroup` shape as
 * `catalog/catalog-share-shared.ts`'s `findCatalogShareByTokenHash`/
 * `invites/invite-shared.ts`'s `findInviteByTokenHash`, for the same reason:
 * the caller (an anonymous customer answering a pesquisa) only ever has the
 * plaintext token, never the `organizationId` a direct lookup would need.
 */
export async function findNpsSurveyByTokenHash(
  db: Firestore,
  tokenHash: string,
  transaction?: Transaction,
): Promise<NpsSurveyLookup | null> {
  const query = db
    .collectionGroup('npsSurveyRequests')
    .where('tokenHash', '==', tokenHash)
    .limit(1);
  const snapshot = transaction ? await transaction.get(query) : await query.get();
  if (snapshot.empty) return null;

  const document = snapshot.docs[0];
  const organizationRef = document.ref.parent.parent;
  if (!organizationRef) {
    throw new HttpsError(
      'internal',
      'NpsSurveyRequest document has no parent organization.',
    );
  }
  return { ref: document.ref, organizationRef, data: document.data() };
}

export function npsAggregateDocId(
  companyId: string,
  scope: NpsAggregateScope,
  scopeId: string,
  periodKey: string,
): string {
  return `${companyId}_${scope}_${scopeId}_${periodKey}`;
}
