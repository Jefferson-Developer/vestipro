import { randomUUID } from 'node:crypto';

import { defineString } from 'firebase-functions/params';
import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { Timestamp, getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { requireNonEmptyString } from '../invites/invite-shared';
import {
  ImageEmbeddingProviderNotConfiguredError,
  resolveImageEmbeddingProviderAdapter,
} from '../shared/image-embedding-provider-adapter';
import {
  PRODUCT_RECOGNITION_MODEL,
  PRODUCT_RECOGNITION_MODEL_VERSION,
  rankProductRecognitionCandidates,
} from './product-recognition-shared';
import { createFirestoreProductRecognitionDataSource } from './product-recognition-data-source';

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

const NOT_CONFIGURED_MESSAGE =
  'Nenhum provedor de reconhecimento de imagem está configurado. Configure ' +
  'RECOGNIZE_PRODUCT_IMAGE_PROVIDER/RECOGNIZE_PRODUCT_IMAGE_GCP_PROJECT_ID/' +
  'RECOGNIZE_PRODUCT_IMAGE_REGION para ativar este recurso.';

const MAX_IMAGE_BYTES = 10 * 1024 * 1024; // mirrors `isValidProductImage` (storage.rules)

/** Matches `StoragePaths.productRecognitionQuery`
 * (`lib/core/storage/storage_paths.dart`):
 * `organizations/{organizationId}/productRecognitionQueries/{userId}/{fileName}`. */
const QUERY_IMAGE_PATH_PATTERN =
  /^organizations\/([^/]+)\/productRecognitionQueries\/([^/]+)\/([^/]+)$/;

export interface RecognizeProductImageRequest extends RequestWithMeta {
  organizationId?: string;
  companyId?: string;
  storagePath?: string;
}

export interface RecognizeProductImageResponseCandidate {
  productId: string;
  productName: string;
  thumbnailUrl: string | null;
  score: number;
}

export interface RecognizeProductImageResponse {
  attemptId: string;
  candidates: RecognizeProductImageResponseCandidate[];
  belowThreshold: boolean;
  generatedAt: string;
  correlationId: string;
}

/**
 * Identifies a catalog product from a photo (TASK-191, EPIC-28). Never
 * returns a single forced answer: the response is always a ranked candidate
 * list (possibly empty, with `belowThreshold: true`) — see
 * `product-recognition-shared.ts`'s own doc comment for the ranking/
 * threshold rule this callable never bypasses.
 *
 * [storagePath] must point at the caller's *own* just-uploaded query photo
 * (`organizations/{organizationId}/productRecognitionQueries/{uid}/{file}` —
 * `storage.rules` already only lets a client write under its own `uid`
 * there), and is independently re-derived/compared here against
 * `request.auth.uid`/[organizationId] — never trusted at face value, exactly
 * like every other tenant-scoped input in this codebase (`AGENTS.md`: "nunca
 * confiar no organizationId enviado pelo cliente como autorização"). The
 * query image itself is deleted from Storage before this callable returns
 * (success or failure) — it is never retained past the single recognition
 * attempt it was uploaded for.
 */
export const recognizeProductImage = onCall<
  RecognizeProductImageRequest,
  Promise<RecognizeProductImageResponse>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'É necessário estar autenticado para identificar um produto por foto.',
    );
  }
  const uid = request.auth.uid;

  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const companyId =
    typeof request.data?.companyId === 'string' && request.data.companyId.trim().length > 0
      ? request.data.companyId.trim()
      : null;
  const storagePath = requireNonEmptyString(request.data?.storagePath, 'storagePath');

  const match = QUERY_IMAGE_PATH_PATTERN.exec(storagePath);
  if (!match || match[1] !== organizationId || match[2] !== uid) {
    // Either a malformed path, or one whose organizationId/uid segments do
    // not match this exact caller — never read/delete a Storage object on
    // another user's/organization's behalf just because the client claims
    // it.
    throw new HttpsError('invalid-argument', 'Caminho de imagem inválido para este usuário.');
  }

  const db = getFirestore();
  const memberSnapshot = await db
    .collection('organizations')
    .doc(organizationId)
    .collection('members')
    .doc(uid)
    .get();
  if (!memberSnapshot.exists || memberSnapshot.data()?.status !== 'active') {
    throw new HttpsError(
      'permission-denied',
      'Você não tem acesso ativo a esta organização.',
    );
  }

  const persistence = createFirestoreProductRecognitionDataSource(db);
  const bucket = getStorage().bucket();
  const file = bucket.file(storagePath);

  try {
    const [metadata] = await file.getMetadata().catch(() => [null]);
    const size = metadata ? Number(metadata.size) : 0;
    if (size <= 0 || size > MAX_IMAGE_BYTES) {
      throw new HttpsError('invalid-argument', 'Imagem inválida ou maior que o limite permitido.');
    }
    const contentType = metadata?.contentType ?? '';
    if (!contentType.startsWith('image/')) {
      throw new HttpsError('invalid-argument', 'O arquivo enviado não é uma imagem.');
    }

    const [bytes] = await file.download();

    const adapter = resolveImageEmbeddingProviderAdapter({
      providerName: recognizeProductImageProvider.value(),
      gcpProjectId: recognizeProductImageGcpProjectId.value(),
      region: recognizeProductImageRegion.value(),
      notConfiguredMessage: NOT_CONFIGURED_MESSAGE,
    });

    let queryEmbedding: number[];
    try {
      queryEmbedding = await adapter.embedImage({
        base64Image: bytes.toString('base64'),
        mimeType: contentType,
      });
    } catch (error) {
      const message =
        error instanceof ImageEmbeddingProviderNotConfiguredError
          ? error.message
          : 'O serviço de reconhecimento de imagem está indisponível no momento. Tente novamente em instantes.';
      logger.error('recognizeProductImage provider call failed', {
        correlationId,
        organizationId,
        error: error instanceof Error ? error.message : String(error),
      });
      throw new HttpsError('unavailable', message);
    }

    const index = await persistence.loadOrganizationIndex(organizationId);
    const result = rankProductRecognitionCandidates({ queryEmbedding, index });

    const attemptId = randomUUID();
    const createdAt = Timestamp.now();
    await persistence.saveAttempt(organizationId, attemptId, {
      organizationId,
      companyId,
      requestedBy: uid,
      candidates: result.candidates.map((candidate) => ({
        productId: candidate.productId,
        productName: candidate.productName,
        score: candidate.score,
      })),
      belowThreshold: result.belowThreshold,
      model: PRODUCT_RECOGNITION_MODEL,
      modelVersion: PRODUCT_RECOGNITION_MODEL_VERSION,
      createdAt,
      feedback: null,
    });

    logger.info('recognizeProductImage succeeded', {
      correlationId,
      organizationId,
      candidateCount: result.candidates.length,
      belowThreshold: result.belowThreshold,
      provider: adapter.providerName,
    });

    return {
      attemptId,
      candidates: result.candidates,
      belowThreshold: result.belowThreshold,
      generatedAt: createdAt.toDate().toISOString(),
      correlationId,
    };
  } finally {
    // Retention policy (`tasks.md`/TASK-191: "imagem capturada... não é
    // retida além do necessário") — deleted regardless of success/failure
    // above. Best-effort: a delete failure (e.g. already gone) never masks
    // the real outcome of the recognition attempt itself.
    await file.delete().catch((error) => {
      logger.warn('recognizeProductImage failed to delete query image', {
        correlationId,
        organizationId,
        error: error instanceof Error ? error.message : String(error),
      });
    });
  }
});
