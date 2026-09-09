import {
  cosineSimilarity,
  PRODUCT_RECOGNITION_MAX_CANDIDATES,
  PRODUCT_RECOGNITION_MIN_CONFIDENCE,
  productImageEmbeddingDocumentId,
  rankProductRecognitionCandidates,
  type ProductImageEmbeddingEntry,
} from '../../src/product_recognition/product-recognition-shared';

function entry(params: {
  productId: string;
  productName?: string;
  mediaId?: string;
  thumbnailUrl?: string | null;
  embedding: number[];
}): ProductImageEmbeddingEntry {
  return {
    organizationId: 'org-1',
    productId: params.productId,
    productName: params.productName ?? params.productId,
    mediaId: params.mediaId ?? 'media-1',
    thumbnailUrl: params.thumbnailUrl ?? null,
    embedding: params.embedding,
  };
}

describe('cosineSimilarity', () => {
  it('returns 1 for identical vectors', () => {
    expect(cosineSimilarity([1, 0, 0], [1, 0, 0])).toBeCloseTo(1);
  });

  it('returns 0 for orthogonal vectors', () => {
    expect(cosineSimilarity([1, 0], [0, 1])).toBeCloseTo(0);
  });

  it('clamps a negative similarity to 0 instead of returning it as-is', () => {
    expect(cosineSimilarity([1, 0], [-1, 0])).toBe(0);
  });

  it('returns 0 for mismatched-dimension vectors instead of throwing', () => {
    expect(cosineSimilarity([1, 2, 3], [1, 2])).toBe(0);
  });

  it('returns 0 for empty vectors instead of throwing', () => {
    expect(cosineSimilarity([], [])).toBe(0);
  });

  it('returns 0 for an all-zero vector instead of dividing by zero', () => {
    expect(cosineSimilarity([0, 0, 0], [1, 2, 3])).toBe(0);
  });
});

describe('rankProductRecognitionCandidates', () => {
  it('returns the clear-match candidate with a high score when the query is near-identical', () => {
    const result = rankProductRecognitionCandidates({
      queryEmbedding: [1, 0, 0],
      index: [
        entry({ productId: 'product-1', embedding: [1, 0, 0] }),
        entry({ productId: 'product-2', embedding: [0, 1, 0] }),
      ],
    });

    expect(result.belowThreshold).toBe(false);
    expect(result.candidates).toHaveLength(1);
    expect(result.candidates[0].productId).toBe('product-1');
    expect(result.candidates[0].score).toBeCloseTo(1);
  });

  it('returns every qualifying candidate, ranked by score, for an ambiguous match', () => {
    const result = rankProductRecognitionCandidates({
      queryEmbedding: [1, 1, 0],
      index: [
        entry({ productId: 'product-1', embedding: [1, 0, 0] }),
        entry({ productId: 'product-2', embedding: [0, 1, 0] }),
        entry({ productId: 'product-3', embedding: [0, 0, 1] }),
      ],
      minConfidence: 0.5,
    });

    expect(result.belowThreshold).toBe(false);
    expect(result.candidates.map((candidate) => candidate.productId)).toEqual([
      'product-1',
      'product-2',
    ]);
    // Both near-45°-angle candidates score identically — deterministic tie
    // break by productId (never an arbitrary/unstable order).
    expect(result.candidates[0].score).toBeCloseTo(result.candidates[1].score);
  });

  it('never forces a guess: returns belowThreshold when every candidate is under the confidence bar', () => {
    const result = rankProductRecognitionCandidates({
      queryEmbedding: [1, 0, 0],
      index: [entry({ productId: 'product-1', embedding: [0, 1, 0] })],
    });

    expect(result.belowThreshold).toBe(true);
    expect(result.candidates).toEqual([]);
  });

  it('returns belowThreshold for an empty index (nothing indexed yet) instead of throwing', () => {
    const result = rankProductRecognitionCandidates({
      queryEmbedding: [1, 0, 0],
      index: [],
    });

    expect(result.belowThreshold).toBe(true);
    expect(result.candidates).toEqual([]);
  });

  it('collapses multiple indexed photos of the same product into a single best-scoring candidate', () => {
    const result = rankProductRecognitionCandidates({
      queryEmbedding: [1, 0, 0],
      index: [
        entry({ productId: 'product-1', mediaId: 'media-a', embedding: [0.9, 0.1, 0] }),
        entry({ productId: 'product-1', mediaId: 'media-b', embedding: [1, 0, 0] }),
      ],
    });

    expect(result.candidates).toHaveLength(1);
    expect(result.candidates[0].score).toBeCloseTo(1);
  });

  it('never returns more than the configured maximum number of candidates', () => {
    const index: ProductImageEmbeddingEntry[] = [];
    for (let i = 0; i < PRODUCT_RECOGNITION_MAX_CANDIDATES + 5; i += 1) {
      index.push(entry({ productId: `product-${i}`, embedding: [1, 0, 0] }));
    }

    const result = rankProductRecognitionCandidates({
      queryEmbedding: [1, 0, 0],
      index,
    });

    expect(result.candidates.length).toBeLessThanOrEqual(PRODUCT_RECOGNITION_MAX_CANDIDATES);
  });

  it('respects an explicit minConfidence override', () => {
    const result = rankProductRecognitionCandidates({
      queryEmbedding: [1, 0, 0],
      index: [entry({ productId: 'product-1', embedding: [0.8, 0.6, 0] })],
      minConfidence: PRODUCT_RECOGNITION_MIN_CONFIDENCE + 0.3,
    });

    expect(result.belowThreshold).toBe(true);
  });

  it('never mixes candidates across a manually mixed-tenant index (caller contract, not enforced here) — cosine ranking itself is tenant-agnostic', () => {
    // This test documents the contract explicitly: `rankProductRecognitionCandidates`
    // trusts its `index` input completely — it is `recognize-product-image.ts`'s
    // `loadOrganizationIndex(organizationId)` that is the single tenant-isolation
    // boundary (see that module's own doc comment).
    const result = rankProductRecognitionCandidates({
      queryEmbedding: [1, 0, 0],
      index: [
        { ...entry({ productId: 'product-1', embedding: [1, 0, 0] }), organizationId: 'org-1' },
        { ...entry({ productId: 'product-2', embedding: [1, 0, 0] }), organizationId: 'org-2' },
      ],
    });

    expect(result.candidates.map((candidate) => candidate.productId).sort()).toEqual([
      'product-1',
      'product-2',
    ]);
  });
});

describe('productImageEmbeddingDocumentId', () => {
  it('joins productId and mediaId deterministically', () => {
    expect(productImageEmbeddingDocumentId('product-1', 'media-1')).toBe('product-1_media-1');
  });
});
