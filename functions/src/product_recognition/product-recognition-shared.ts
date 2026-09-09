/**
 * Server-side, shared domain service for EPIC-28's "reconhecimento de
 * produto por imagem" (TASK-191). Every function here is pure (no
 * Firestore, no `firebase-functions`) — same "shared calculation core" shape
 * already established by `../recommendations/recommendation-shared.ts`
 * (TASK-190) and `../demand-forecast/demand-forecast-shared.ts` (TASK-185).
 *
 * ## Modelo (documentação exigida por `tasks.md`/TASK-191)
 *
 * Cada foto de produto já cadastrada (TASK-065/TASK-068) é convertida, no
 * momento do upload, em um vetor de embedding (via
 * `../shared/image-embedding-provider-adapter.ts`) e persistida em
 * `organizations/{organizationId}/productImageEmbeddings/{productId}_{mediaId}`
 * (`index-product-image-embedding.ts`). Uma foto tirada pelo vendedor/cliente
 * passa pelo mesmo provider de embedding e é comparada, por similaridade de
 * cosseno, contra **todo** o índice daquela organização — nunca contra o de
 * outra (`recognize-product-image.ts` só carrega o índice do
 * `organizationId` do chamador).
 *
 * `rankProductRecognitionCandidates` nunca devolve uma única resposta
 * forçada: os candidatos são sempre uma lista ordenada por score, e a lista
 * vem vazia (`belowThreshold: true`) sempre que nem o melhor candidato supera
 * {@link PRODUCT_RECOGNITION_MIN_CONFIDENCE} — "nunca um palpite" é a regra
 * central desta task (`tasks.md`/TASK-191).
 */

/** Minimum cosine similarity (`0..1`) for a candidate to ever be surfaced.
 * Chosen conservatively: below this, the visual match is not reliable enough
 * to show as "provável", and the caller must show an explicit "não foi
 * possível identificar com confiança" instead of a low-quality guess. */
export const PRODUCT_RECOGNITION_MIN_CONFIDENCE = 0.6;

/** Maximum number of candidates ever returned for one recognition attempt —
 * enough for a seller to visually compare a handful of options, never a long
 * list that defeats the purpose of "identificar rapidamente". */
export const PRODUCT_RECOGNITION_MAX_CANDIDATES = 5;

export const PRODUCT_RECOGNITION_MODEL = 'imageEmbeddingCosineV1';
export const PRODUCT_RECOGNITION_MODEL_VERSION = 'cosine-similarity-v1';

/** One product photo already indexed for one organization (never mixed
 * across organizations — every caller of {@link rankProductRecognitionCandidates}
 * must load only entries whose `organizationId` matches the requester's
 * own). */
export interface ProductImageEmbeddingEntry {
  organizationId: string;
  productId: string;
  productName: string;
  mediaId: string;
  thumbnailUrl: string | null;
  embedding: readonly number[];
}

export interface ProductRecognitionCandidate {
  productId: string;
  productName: string;
  thumbnailUrl: string | null;
  /** Cosine similarity (`0..1`) between the query photo and this product's
   * best-matching indexed photo — never an arbitrary/unbounded score. */
  score: number;
}

export interface ProductRecognitionResult {
  candidates: ProductRecognitionCandidate[];
  /** `true` when no candidate reached {@link PRODUCT_RECOGNITION_MIN_CONFIDENCE}
   * (including when the organization's index is empty) — the caller must
   * render this as an explicit "não foi possível identificar com confiança"
   * state, never silently show an empty list. [candidates] is always `[]`
   * when this is `true`. */
  belowThreshold: boolean;
}

/** Cosine similarity between two equal-length vectors, clamped to `[0, 1]`
 * (a `imageEmbedding` from the same model family is never expected to
 * produce a meaningfully negative similarity for two real product photos;
 * clamping only guards against floating-point noise at the boundary, never
 * hides a real negative signal by silently flipping it). Returns `0` for a
 * degenerate (zero-length, all-zero, or mismatched-dimension) vector instead
 * of throwing — a single malformed index entry must never crash the whole
 * ranking. */
export function cosineSimilarity(a: readonly number[], b: readonly number[]): number {
  if (a.length === 0 || b.length === 0 || a.length !== b.length) return 0;

  let dot = 0;
  let normA = 0;
  let normB = 0;
  for (let i = 0; i < a.length; i += 1) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  if (normA === 0 || normB === 0) return 0;

  const similarity = dot / (Math.sqrt(normA) * Math.sqrt(normB));
  if (!Number.isFinite(similarity)) return 0;
  return Math.max(0, Math.min(1, similarity));
}

/**
 * Ranks every indexed photo in [index] against [queryEmbedding], keeping only
 * the best-scoring photo per product (a product with several indexed photos
 * — TASK-068 allows many — must appear at most once in the result, never one
 * row per photo), then applies [minConfidence]/[maxCandidates].
 *
 * The caller (`recognize-product-image.ts`) is the one and only place
 * responsible for pre-filtering [index] to a single organization —
 * this function itself does not re-check `organizationId` per entry (it
 * trusts its input), so it must never be called with an unfiltered,
 * cross-tenant index.
 */
export function rankProductRecognitionCandidates(params: {
  queryEmbedding: readonly number[];
  index: readonly ProductImageEmbeddingEntry[];
  minConfidence?: number;
  maxCandidates?: number;
}): ProductRecognitionResult {
  const minConfidence = params.minConfidence ?? PRODUCT_RECOGNITION_MIN_CONFIDENCE;
  const maxCandidates = params.maxCandidates ?? PRODUCT_RECOGNITION_MAX_CANDIDATES;

  const bestByProduct = new Map<
    string,
    { productName: string; thumbnailUrl: string | null; score: number }
  >();
  for (const entry of params.index) {
    const score = cosineSimilarity(params.queryEmbedding, entry.embedding);
    const current = bestByProduct.get(entry.productId);
    if (!current || score > current.score) {
      bestByProduct.set(entry.productId, {
        productName: entry.productName,
        thumbnailUrl: entry.thumbnailUrl,
        score,
      });
    }
  }

  const ranked = [...bestByProduct.entries()]
    .map(([productId, best]) => ({
      productId,
      productName: best.productName,
      thumbnailUrl: best.thumbnailUrl,
      score: Math.round(best.score * 10000) / 10000,
    }))
    .sort((a, b) => b.score - a.score || a.productId.localeCompare(b.productId));

  const topCandidates = ranked.slice(0, maxCandidates);
  const bestScore = topCandidates[0]?.score ?? 0;

  if (topCandidates.length === 0 || bestScore < minConfidence) {
    return { candidates: [], belowThreshold: true };
  }

  // Only candidates that individually clear the confidence bar are ever
  // shown — a strong #1 match never drags a much weaker #4/#5 into the list
  // just to fill it up.
  const qualifyingCandidates = topCandidates.filter(
    (candidate) => candidate.score >= minConfidence,
  );

  return { candidates: qualifyingCandidates, belowThreshold: false };
}

export function productImageEmbeddingDocumentId(productId: string, mediaId: string): string {
  return `${productId}_${mediaId}`;
}
