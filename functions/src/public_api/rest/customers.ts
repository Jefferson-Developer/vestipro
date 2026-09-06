import type { Request, Response } from 'express';
import {
  Timestamp,
  getFirestore,
  type DocumentData,
  type DocumentSnapshot,
  type Query,
  type QueryDocumentSnapshot,
} from 'firebase-admin/firestore';

import { decodeCursor, encodeCursor, parsePageSize } from '../api-key-shared';
import { sendApiError } from './middleware';

/**
 * `GET /v1/customers` (TASK-171, `customers:read` scope) — cursor-paginated
 * listing of every non-deleted `Customer` in the resolved API key's own
 * organization, ordered by `(createdAt asc, __name__ asc)` (never an offset
 * over a potentially large collection).
 */
export async function listCustomers(req: Request, res: Response): Promise<void> {
  const { organizationId } = req.apiKey!;
  const db = getFirestore();
  const pageSize = parsePageSize(req.query.limit);
  const cursor = decodeCursor(
    typeof req.query.cursor === 'string' ? req.query.cursor : undefined,
  );

  let query: Query = db
    .collection('organizations')
    .doc(organizationId)
    .collection('customers')
    .where('deletedAt', '==', null)
    .orderBy('createdAt', 'asc')
    .orderBy('__name__', 'asc')
    .limit(pageSize + 1);

  if (cursor) {
    query = query.startAfter(Timestamp.fromMillis(cursor.createdAtMs), cursor.id);
  }

  const snapshot = await query.get();
  const docs = snapshot.docs.slice(0, pageSize);
  const hasMore = snapshot.docs.length > pageSize;
  const last = docs[docs.length - 1];

  res.json({
    data: docs.map(serializeCustomer),
    nextCursor:
      hasMore && last
        ? encodeCursor({
            createdAtMs: toMillis(last.data().createdAt),
            id: last.id,
          })
        : null,
  });
}

/** `GET /v1/customers/:id` (TASK-171, `customers:read` scope). */
export async function getCustomerById(req: Request, res: Response): Promise<void> {
  const { organizationId } = req.apiKey!;
  const db = getFirestore();
  const snapshot = await db
    .collection('organizations')
    .doc(organizationId)
    .collection('customers')
    .doc(req.params.id)
    .get();

  const data = snapshot.data();
  if (
    !snapshot.exists ||
    !data ||
    data.deletedAt !== null ||
    data.organizationId !== organizationId
  ) {
    sendApiError(res, 404, 'not_found', 'Cliente não encontrado.');
    return;
  }

  res.json({ data: serializeCustomer(snapshot) });
}

function serializeCustomer(
  doc: QueryDocumentSnapshot | DocumentSnapshot,
): DocumentData {
  const data = doc.data() ?? {};
  return {
    id: doc.id,
    companyId: data.companyId ?? null,
    document: data.document ?? null,
    legalName: data.legalName ?? null,
    tradeName: data.tradeName ?? null,
    fullName: data.fullName ?? null,
    primaryEmail: data.primaryEmail ?? null,
    primaryPhone: data.primaryPhone ?? null,
    classification: data.classification ?? null,
    segment: data.segment ?? null,
    status: data.status ?? null,
    createdAt: isoOrNull(data.createdAt),
    updatedAt: isoOrNull(data.updatedAt),
  };
}

function toMillis(value: unknown): number {
  return value instanceof Timestamp ? value.toMillis() : 0;
}

function isoOrNull(value: unknown): string | null {
  return value instanceof Timestamp ? value.toDate().toISOString() : null;
}
