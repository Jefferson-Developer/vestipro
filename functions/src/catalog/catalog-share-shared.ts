import { HttpsError } from 'firebase-functions/v2/https';
import {
  Timestamp,
  type DocumentData,
  type DocumentReference,
  type Firestore,
  type Transaction,
} from 'firebase-admin/firestore';

/**
 * The 3 ways a catalog share can scope what it exposes (TASK-081, "produto
 * único, lista de produtos ou coleção").
 */
export const CATALOG_SHARE_SCOPES = ['product', 'selection', 'collection'] as const;
export type CatalogShareScope = (typeof CATALOG_SHARE_SCOPES)[number];

const MAX_ITEMS = 50;
const DEFAULT_EXPIRATION_DAYS = 30;
const MIN_EXPIRATION_DAYS = 1;
const MAX_EXPIRATION_DAYS = 90;
const MS_PER_DAY = 24 * 60 * 60 * 1000;

export function requireNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new HttpsError('invalid-argument', `${field} is required.`);
  }
  return value.trim();
}

function optionalTrimmedString(value: unknown): string | null {
  return typeof value === 'string' && value.trim().length > 0 ? value.trim() : null;
}

export function requireScope(value: unknown): CatalogShareScope {
  if (
    typeof value !== 'string' ||
    !(CATALOG_SHARE_SCOPES as readonly string[]).includes(value)
  ) {
    throw new HttpsError(
      'invalid-argument',
      `scope must be one of ${CATALOG_SHARE_SCOPES.join(', ')}.`,
    );
  }
  return value as CatalogShareScope;
}

export interface CatalogShareItemInput {
  productId: string;
  name: string;
  imageUrl: string | null;
}

/**
 * Validates and normalizes the item snapshots a caller sends when creating a
 * share. Items travel as a lightweight, client-provided snapshot
 * (`productId`/`name`/`imageUrl`) rather than being re-resolved from a
 * server-side product store — the catalog's product repository is still
 * local-first (`SharedPreferencesProductRepository`, same precedent already
 * documented by TASK-080's "Decisões técnicas"), so there is no
 * organization-wide Firestore source of truth for product data this
 * Function could read from yet. The snapshot is exactly what makes the
 * public link work for a recipient with no session/organization context at
 * all: everything it needs to render is embedded in the `CatalogShare`
 * document itself.
 *
 * `scope === 'product'` requires exactly one item — every other scope
 * requires at least one, capped at {@link MAX_ITEMS} to bound document size
 * and abuse.
 */
export function requireItems(
  value: unknown,
  scope: CatalogShareScope,
): CatalogShareItemInput[] {
  if (!Array.isArray(value) || value.length === 0) {
    throw new HttpsError('invalid-argument', 'items must be a non-empty array.');
  }
  if (value.length > MAX_ITEMS) {
    throw new HttpsError(
      'invalid-argument',
      `items cannot contain more than ${MAX_ITEMS} products.`,
    );
  }
  if (scope === 'product' && value.length !== 1) {
    throw new HttpsError(
      'invalid-argument',
      "scope 'product' requires exactly one item.",
    );
  }

  return value.map((raw, index) => {
    if (typeof raw !== 'object' || raw === null) {
      throw new HttpsError('invalid-argument', `items[${index}] is invalid.`);
    }
    const record = raw as Record<string, unknown>;
    const productId = requireNonEmptyString(
      record.productId,
      `items[${index}].productId`,
    );
    const name = requireNonEmptyString(record.name, `items[${index}].name`);
    const imageUrl = optionalTrimmedString(record.imageUrl);
    return { productId, name, imageUrl };
  });
}

/**
 * Resolves how many days from [now] a freshly created share should expire
 * in: [requestedDays] when the caller sent a valid positive integer within
 * [MIN_EXPIRATION_DAYS, MAX_EXPIRATION_DAYS], otherwise
 * {@link DEFAULT_EXPIRATION_DAYS} — same clamp-with-default shape as
 * `invites/invite-shared.ts`'s `resolveInviteExpiration`, but without a
 * per-organization override (no settings UI/requirement exists for catalog
 * shares).
 */
export function resolveExpiration(now: Timestamp, requestedDays: unknown): Timestamp {
  const days =
    typeof requestedDays === 'number' &&
    Number.isInteger(requestedDays) &&
    requestedDays >= MIN_EXPIRATION_DAYS &&
    requestedDays <= MAX_EXPIRATION_DAYS
      ? requestedDays
      : DEFAULT_EXPIRATION_DAYS;
  return Timestamp.fromMillis(now.toMillis() + days * MS_PER_DAY);
}

/**
 * The 3 outcomes an already-found `CatalogShare` document resolves into
 * *right now* — mirrors `invites/invite-shared.ts`'s `resolveInviteOutcome`:
 * `'revoked'` is always trusted as stored (nothing un-revokes a share),
 * `'expired'` is always computed lazily from `expiresAt` vs. [now], never
 * from a stored value (nothing schedules a status flip), and anything else
 * stored as `status: 'active'` and not yet past `expiresAt` is `'valid'`.
 */
export type CatalogShareOutcome = 'valid' | 'expired' | 'revoked';

export function resolveCatalogShareOutcome(
  data: DocumentData,
  now: Timestamp,
): CatalogShareOutcome {
  if (data.status === 'revoked') return 'revoked';
  const expiresAt = data.expiresAt as Timestamp;
  if (expiresAt.toMillis() <= now.toMillis()) return 'expired';
  return 'valid';
}

export interface CatalogShareLookup {
  ref: DocumentReference;
  organizationRef: DocumentReference;
  data: DocumentData;
}

/**
 * Finds the (at most one) `CatalogShare` document anywhere in Firestore
 * whose `tokenHash` equals [tokenHash] — same `collectionGroup` shape as
 * `invites/invite-shared.ts`'s `findInviteByTokenHash`, for the same reason:
 * the caller (an anonymous recipient) only ever has the plaintext token, not
 * the `organizationId` a direct lookup would need.
 */
export async function findCatalogShareByTokenHash(
  db: Firestore,
  tokenHash: string,
  transaction?: Transaction,
): Promise<CatalogShareLookup | null> {
  const query = db
    .collectionGroup('catalogShares')
    .where('tokenHash', '==', tokenHash)
    .limit(1);
  const snapshot = transaction ? await transaction.get(query) : await query.get();

  if (snapshot.empty) return null;

  const document = snapshot.docs[0];
  const organizationRef = document.ref.parent.parent;
  if (!organizationRef) {
    throw new HttpsError(
      'internal',
      'CatalogShare document has no parent organization.',
    );
  }
  return { ref: document.ref, organizationRef, data: document.data() };
}

export interface CatalogShareItemResponse {
  productId: string;
  name: string;
  imageUrl: string | null;
}

export interface CatalogShareResponse {
  id: string;
  organizationId: string;
  scope: CatalogShareScope;
  items: CatalogShareItemResponse[];
  collectionId: string | null;
  collectionName: string | null;
  status: 'active' | 'revoked';
  openCount: number;
  firstOpenedAt: string | null;
  lastOpenedAt: string | null;
  expiresAt: string;
  createdBy: string;
  createdByName: string;
  createdAt: string;
  updatedAt: string;
}

function serializeItems(data: DocumentData): CatalogShareItemResponse[] {
  const items = (data.items as DocumentData[] | undefined) ?? [];
  return items.map((item) => ({
    productId: item.productId as string,
    name: item.name as string,
    imageUrl: (item.imageUrl as string | null | undefined) ?? null,
  }));
}

/**
 * Serializes a `CatalogShare` document for its **creator** (or an
 * OWNER/ADMIN auditing it) — the response `createCatalogShareLink`/
 * `revokeCatalogShareLink` return. Never called for the public/anonymous
 * side of this feature (`getCatalogShareLink`), which uses
 * {@link serializeCatalogSharePreview} instead and never exposes
 * `createdBy`/`id`/`organizationId`.
 */
export function serializeCatalogShare(
  id: string,
  data: DocumentData,
): CatalogShareResponse {
  const expiresAt = data.expiresAt as Timestamp;
  const createdAt = data.createdAt as Timestamp;
  const updatedAt = data.updatedAt as Timestamp;
  const firstOpenedAt = data.firstOpenedAt as Timestamp | null | undefined;
  const lastOpenedAt = data.lastOpenedAt as Timestamp | null | undefined;
  return {
    id,
    organizationId: data.organizationId as string,
    scope: data.scope as CatalogShareScope,
    items: serializeItems(data),
    collectionId: (data.collectionId as string | null | undefined) ?? null,
    collectionName: (data.collectionName as string | null | undefined) ?? null,
    status: data.status as 'active' | 'revoked',
    openCount: (data.openCount as number | undefined) ?? 0,
    firstOpenedAt: firstOpenedAt ? firstOpenedAt.toDate().toISOString() : null,
    lastOpenedAt: lastOpenedAt ? lastOpenedAt.toDate().toISOString() : null,
    expiresAt: expiresAt.toDate().toISOString(),
    createdBy: data.createdBy as string,
    createdByName: data.createdByName as string,
    createdAt: createdAt.toDate().toISOString(),
    updatedAt: updatedAt.toDate().toISOString(),
  };
}

export interface CatalogSharePreviewResponse {
  outcome: CatalogShareOutcome | 'notFound';
  organizationName: string | null;
  scope: CatalogShareScope | null;
  items: CatalogShareItemResponse[];
  collectionName: string | null;
  expiresAt: string | null;
}

/**
 * Serializes a `CatalogShare` for the **public, unauthenticated** recipient
 * (`getCatalogShareLink`) — deliberately never includes `id`,
 * `organizationId`, `createdBy`/`createdByName`, `tokenHash`, `status`
 * (only the computed [outcome]) or open-count/timestamps: a visitor who was
 * only ever handed a link must never learn anything about the organization
 * or the vendor beyond the organization's display name and the shared
 * items themselves (TASK-081: "nunca expõe... informações internas da
 * organização além do escopo definido").
 */
export function serializeCatalogSharePreview(
  outcome: CatalogShareOutcome,
  organizationName: string | null,
  data: DocumentData,
): CatalogSharePreviewResponse {
  const expiresAt = data.expiresAt as Timestamp;
  return {
    outcome,
    organizationName,
    scope: data.scope as CatalogShareScope,
    items: serializeItems(data),
    collectionName: (data.collectionName as string | null | undefined) ?? null,
    expiresAt: expiresAt.toDate().toISOString(),
  };
}
