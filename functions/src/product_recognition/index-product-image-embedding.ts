import { defineString } from 'firebase-functions/params';
import { logger } from 'firebase-functions/v2';
import { onObjectDeleted, onObjectFinalized } from 'firebase-functions/v2/storage';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage as getAdminStorage } from 'firebase-admin/storage';

import {
  resolveImageEmbeddingProviderAdapter,
} from '../shared/image-embedding-provider-adapter';
import {
  productImageEmbeddingDocumentId,
  type ProductImageEmbeddingEntry,
} from './product-recognition-shared';
import { createFirestoreProductRecognitionDataSource } from './product-recognition-data-source';

/** Same env vars `recognize-product-image.ts` reads — a single provider
 * configuration shared by both the indexing job and the recognition callable
 * (they must always agree on which model produced every vector, otherwise
 * cosine similarity between a query embedding and an index entry would be
 * meaningless). */
const recognizeProductImageProvider = defineString('RECOGNIZE_PRODUCT_IMAGE_PROVIDER', {
  default: 'disabled',
});
const recognizeProductImageGcpProjectId = defineString(
  'RECOGNIZE_PRODUCT_IMAGE_GCP_PROJECT_ID',
  { default: '' },
);
const recognizeProductImageRegion = defineString('RECOGNIZE_PRODUCT_IMAGE_REGION', {
  default: 'us-central1',
});

/** Matches `StoragePaths.productFile` (`lib/core/storage/storage_paths.dart`)
 * exactly — `organizations/{organizationId}/products/{productId}/{fileName}`.
 * A path that does not match (e.g. an order attachment, avatar, or anything
 * outside this one convention) is silently ignored: this trigger only ever
 * reacts to product photos, never any other upload type in the bucket. */
const PRODUCT_FILE_PATH_PATTERN =
  /^organizations\/([^/]+)\/products\/([^/]+)\/([^/]+)$/;

const MAX_IMAGE_BYTES = 10 * 1024 * 1024; // mirrors `isValidProductImage` (storage.rules)

/**
 * Indexes (or re-indexes) one product photo's embedding as soon as it
 * finishes uploading (TASK-191, EPIC-28) — the "job de indexação... trigger
 * no upload de imagem de produto" `tasks.md` asks for. Best-effort: any
 * failure here (unsupported content type, provider not configured/
 * unavailable, product doc missing) is logged and swallowed, never thrown —
 * a photo upload (TASK-068) must never be blocked or rolled back because
 * this background indexing step failed. A product photo simply stays
 * unindexed (never surfaced as a recognition candidate) until the next
 * successful upload/retry of the same file name.
 */
export const indexProductImageEmbedding = onObjectFinalized(async (event) => {
  try {
    await handleProductImageFinalized(event.data.name, event.data.contentType, event.data.size);
  } catch (error) {
    logger.error('indexProductImageEmbedding failed', {
      objectName: event.data.name,
      error: error instanceof Error ? error.message : String(error),
    });
  }
});

async function handleProductImageFinalized(
  objectName: string | undefined,
  contentType: string | undefined,
  size: string | number | undefined,
): Promise<void> {
  if (!objectName) return;
  const match = PRODUCT_FILE_PATH_PATTERN.exec(objectName);
  if (!match) return;

  const [, organizationId, productId, fileName] = match;
  const mediaId = fileName;

  if (!contentType || !contentType.startsWith('image/')) {
    // Videos and thumbnail renditions of a product's media are both real
    // objects under this same path — only the full-resolution photo itself
    // is ever indexed, never a video and never a thumbnail (a thumbnail's
    // `id` never matches a `ProductMedia.id`, so it would not be found in
    // `product.media` below anyway, but the content-type check short-circuits
    // before that lookup for the common "video" case).
    return;
  }
  const numericSize = typeof size === 'string' ? Number(size) : size;
  if (typeof numericSize === 'number' && numericSize > MAX_IMAGE_BYTES) {
    logger.warn('indexProductImageEmbedding skipped oversized object', {
      organizationId,
      productId,
      mediaId,
      size: numericSize,
    });
    return;
  }

  const db = getFirestore();
  const productSnapshot = await db
    .collection('organizations')
    .doc(organizationId)
    .collection('products')
    .doc(productId)
    .get();
  if (!productSnapshot.exists) return;
  const product = productSnapshot.data();
  if (!product || product.organizationId !== organizationId) return;

  const mediaEntries = Array.isArray(product.media) ? product.media : [];
  const mediaEntry = mediaEntries.find(
    (entry: unknown) =>
      typeof entry === 'object' &&
      entry !== null &&
      (entry as { id?: unknown; type?: unknown }).id === mediaId &&
      (entry as { type?: unknown }).type === 'photo',
  ) as { thumbnailUrl?: unknown } | undefined;
  // A stray upload whose file name is not (yet, or anymore) referenced by
  // `product.media` is never indexed — this trigger only indexes photos the
  // product form itself already persisted as real media, never an
  // in-flight/orphaned upload.
  if (!mediaEntry) return;

  const adapter = resolveImageEmbeddingProviderAdapter({
    providerName: recognizeProductImageProvider.value(),
    gcpProjectId: recognizeProductImageGcpProjectId.value(),
    region: recognizeProductImageRegion.value(),
  });

  const bucket = getAdminStorage().bucket();
  const [bytes] = await bucket.file(objectName).download();
  if (bytes.byteLength > MAX_IMAGE_BYTES) return;

  const embedding = await adapter.embedImage({
    base64Image: bytes.toString('base64'),
    mimeType: contentType,
  });

  const entry: ProductImageEmbeddingEntry = {
    organizationId,
    productId,
    productName: typeof product.name === 'string' ? product.name : productId,
    mediaId,
    thumbnailUrl:
      typeof mediaEntry.thumbnailUrl === 'string' ? mediaEntry.thumbnailUrl : null,
    embedding,
  };

  const persistence = createFirestoreProductRecognitionDataSource(db);
  await persistence.saveEmbedding(
    organizationId,
    productImageEmbeddingDocumentId(productId, mediaId),
    entry,
  );

  logger.info('indexProductImageEmbedding indexed product photo', {
    organizationId,
    productId,
    mediaId,
    provider: adapter.providerName,
  });
}

/**
 * Keeps the embedding index consistent when a product photo is removed
 * (`ProductMediaBloc._onRemoved` deletes the Storage object) — best-effort,
 * same swallow-and-log contract as {@link indexProductImageEmbedding}: a
 * failed cleanup here never blocks the photo removal itself, it just leaves
 * one stale index entry to be overwritten the next time that same file name
 * is ever reused (extremely unlikely, since every upload uses a fresh
 * `Uuid.v4()` file name) or manually purged.
 */
export const removeProductImageEmbeddingOnDelete = onObjectDeleted(async (event) => {
  try {
    const match = PRODUCT_FILE_PATH_PATTERN.exec(event.data.name ?? '');
    if (!match) return;
    const [, organizationId, productId, fileName] = match;
    const persistence = createFirestoreProductRecognitionDataSource();
    await persistence.deleteEmbedding(
      organizationId,
      productImageEmbeddingDocumentId(productId, fileName),
    );
  } catch (error) {
    logger.error('removeProductImageEmbeddingOnDelete failed', {
      objectName: event.data.name,
      error: error instanceof Error ? error.message : String(error),
    });
  }
});
