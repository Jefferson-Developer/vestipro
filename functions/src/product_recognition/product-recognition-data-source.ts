import {
  FieldValue,
  Timestamp,
  getFirestore,
  type Firestore,
} from 'firebase-admin/firestore';

import type { ProductImageEmbeddingEntry } from './product-recognition-shared';

/**
 * Injectable persistence port for TASK-191's "reconhecimento de produto por
 * imagem" — same "port + Firestore adapter" shape already used by
 * `../recommendations/recommendation-data-source.ts` (TASK-190), so
 * `recognize-product-image.ts`/`index-product-image-embedding.ts` never talk
 * to `firebase-admin/firestore` directly.
 */
export interface ProductRecognitionAttemptFeedback {
  outcome: 'matched' | 'noneMatched';
  matchedProductId: string | null;
  respondedAt: Timestamp;
}

export interface ProductRecognitionAttemptRecord {
  organizationId: string;
  companyId: string | null;
  requestedBy: string;
  candidates: { productId: string; productName: string; score: number }[];
  belowThreshold: boolean;
  model: string;
  modelVersion: string;
  createdAt: Timestamp;
  feedback: ProductRecognitionAttemptFeedback | null;
}

export interface ProductRecognitionPersistence {
  /** Every indexed photo for [organizationId] — the *only* place in this
   * feature that reads the embedding index, so tenant isolation is enforced
   * exactly once, here. */
  loadOrganizationIndex(organizationId: string): Promise<ProductImageEmbeddingEntry[]>;
  saveEmbedding(
    organizationId: string,
    documentId: string,
    entry: ProductImageEmbeddingEntry,
  ): Promise<void>;
  deleteEmbedding(organizationId: string, documentId: string): Promise<void>;
  saveAttempt(
    organizationId: string,
    attemptId: string,
    record: ProductRecognitionAttemptRecord,
  ): Promise<void>;
  loadAttempt(
    organizationId: string,
    attemptId: string,
  ): Promise<ProductRecognitionAttemptRecord | null>;
  saveAttemptFeedback(
    organizationId: string,
    attemptId: string,
    feedback: ProductRecognitionAttemptFeedback,
  ): Promise<void>;
}

export function createFirestoreProductRecognitionDataSource(
  db: Firestore = getFirestore(),
): ProductRecognitionPersistence {
  return {
    async loadOrganizationIndex(organizationId) {
      const snapshot = await db
        .collection('organizations')
        .doc(organizationId)
        .collection('productImageEmbeddings')
        .get();
      return snapshot.docs.map((doc) => doc.data() as ProductImageEmbeddingEntry);
    },

    async saveEmbedding(organizationId, documentId, entry) {
      await db
        .collection('organizations')
        .doc(organizationId)
        .collection('productImageEmbeddings')
        .doc(documentId)
        .set({ ...entry, updatedAt: FieldValue.serverTimestamp() });
    },

    async deleteEmbedding(organizationId, documentId) {
      await db
        .collection('organizations')
        .doc(organizationId)
        .collection('productImageEmbeddings')
        .doc(documentId)
        .delete();
    },

    async saveAttempt(organizationId, attemptId, record) {
      await db
        .collection('organizations')
        .doc(organizationId)
        .collection('productRecognitionAttempts')
        .doc(attemptId)
        .set(record);
    },

    async loadAttempt(organizationId, attemptId) {
      const snapshot = await db
        .collection('organizations')
        .doc(organizationId)
        .collection('productRecognitionAttempts')
        .doc(attemptId)
        .get();
      if (!snapshot.exists) return null;
      return snapshot.data() as ProductRecognitionAttemptRecord;
    },

    async saveAttemptFeedback(organizationId, attemptId, feedback) {
      await db
        .collection('organizations')
        .doc(organizationId)
        .collection('productRecognitionAttempts')
        .doc(attemptId)
        .update({ feedback });
    },
  };
}
