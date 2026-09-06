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

/** `GET /v1/products` (TASK-171, `products:read` scope) — cursor-paginated
 * listing of every non-deleted `Product` in the resolved API key's own
 * organization. */
export async function listProducts(req: Request, res: Response): Promise<void> {
  const { organizationId } = req.apiKey!;
  const db = getFirestore();
  const pageSize = parsePageSize(req.query.limit);
  const cursor = decodeCursor(
    typeof req.query.cursor === 'string' ? req.query.cursor : undefined,
  );

  let query: Query = db
    .collection('organizations')
    .doc(organizationId)
    .collection('products')
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
    data: docs.map(serializeProduct),
    nextCursor:
      hasMore && last
        ? encodeCursor({
            createdAtMs: toMillis(last.data().createdAt),
            id: last.id,
          })
        : null,
  });
}

/** `GET /v1/products/:id` (TASK-171, `products:read` scope). */
export async function getProductById(req: Request, res: Response): Promise<void> {
  const { organizationId } = req.apiKey!;
  const db = getFirestore();
  const snapshot = await db
    .collection('organizations')
    .doc(organizationId)
    .collection('products')
    .doc(req.params.id)
    .get();

  const data = snapshot.data();
  if (
    !snapshot.exists ||
    !data ||
    data.deletedAt !== null ||
    data.organizationId !== organizationId
  ) {
    sendApiError(res, 404, 'not_found', 'Produto não encontrado.');
    return;
  }

  res.json({ data: serializeProduct(snapshot) });
}

function serializeProduct(
  doc: QueryDocumentSnapshot | DocumentSnapshot,
): DocumentData {
  const data = doc.data() ?? {};
  return {
    id: doc.id,
    companyId: data.companyId ?? null,
    sku: data.sku ?? null,
    reference: data.reference ?? null,
    name: data.name ?? null,
    brand: data.brand ?? null,
    collectionId: data.collectionId ?? null,
    categoryId: data.categoryId ?? null,
    subcategoryId: data.subcategoryId ?? null,
    status: data.status ?? null,
    ean: data.ean ?? null,
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
