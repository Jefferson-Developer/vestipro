import {
  ImageEmbeddingProviderNotConfiguredError,
  resolveImageEmbeddingProviderAdapter,
} from '../../src/shared/image-embedding-provider-adapter';

function fakeFetcher(response: { ok: boolean; status?: number; json: () => Promise<unknown> }) {
  return jest.fn(async () => response as unknown as Response);
}

describe('resolveImageEmbeddingProviderAdapter (shared)', () => {
  it('resolves to the disabled adapter when no provider is configured', () => {
    const adapter = resolveImageEmbeddingProviderAdapter({
      providerName: undefined,
      gcpProjectId: undefined,
      region: undefined,
    });
    expect(adapter.providerName).toBe('disabled');
  });

  it('throws with the caller-supplied notConfiguredMessage, never a hardcoded one', async () => {
    const adapter = resolveImageEmbeddingProviderAdapter({
      providerName: undefined,
      gcpProjectId: undefined,
      region: undefined,
      notConfiguredMessage: 'Configure RECOGNIZE_PRODUCT_IMAGE_PROVIDER.',
    });
    await expect(
      adapter.embedImage({ base64Image: 'abc', mimeType: 'image/jpeg' }),
    ).rejects.toThrow('Configure RECOGNIZE_PRODUCT_IMAGE_PROVIDER.');
  });

  it('falls back to a generic message when the caller supplies none', async () => {
    const adapter = resolveImageEmbeddingProviderAdapter({
      providerName: undefined,
      gcpProjectId: undefined,
      region: undefined,
    });
    await expect(
      adapter.embedImage({ base64Image: 'abc', mimeType: 'image/jpeg' }),
    ).rejects.toBeInstanceOf(ImageEmbeddingProviderNotConfiguredError);
  });

  it('resolves to the disabled adapter when provider is vertexAi but gcpProjectId is missing', () => {
    const adapter = resolveImageEmbeddingProviderAdapter({
      providerName: 'vertexAi',
      gcpProjectId: '',
      region: 'us-central1',
    });
    expect(adapter.providerName).toBe('disabled');
  });

  it('resolves to the disabled adapter when provider is vertexAi but region is missing', () => {
    const adapter = resolveImageEmbeddingProviderAdapter({
      providerName: 'vertexAi',
      gcpProjectId: 'my-project',
      region: '',
    });
    expect(adapter.providerName).toBe('disabled');
  });

  it('resolves to the disabled adapter for an unknown provider name', () => {
    const adapter = resolveImageEmbeddingProviderAdapter({
      providerName: 'unknown-provider',
      gcpProjectId: 'my-project',
      region: 'us-central1',
    });
    expect(adapter.providerName).toBe('disabled');
  });

  it('resolves to the Vertex AI adapter and calls the Multimodal Embeddings API shape', async () => {
    const fetcher = fakeFetcher({
      ok: true,
      json: async () => ({ predictions: [{ imageEmbedding: [0.1, 0.2, 0.3] }] }),
    });
    const adapter = resolveImageEmbeddingProviderAdapter({
      providerName: 'vertexAi',
      gcpProjectId: 'my-project',
      region: 'us-central1',
      fetcher: fetcher as unknown as typeof fetch,
      resolveAccessToken: async () => 'fake-token',
    });
    expect(adapter.providerName).toBe('vertexAi');

    const embedding = await adapter.embedImage({ base64Image: 'abc', mimeType: 'image/jpeg' });
    expect(embedding).toEqual([0.1, 0.2, 0.3]);
    expect(fetcher).toHaveBeenCalledWith(
      'https://us-central1-aiplatform.googleapis.com/v1/projects/my-project/locations/us-central1/publishers/google/models/multimodalembedding@001:predict',
      expect.objectContaining({
        method: 'POST',
        headers: expect.objectContaining({ authorization: 'Bearer fake-token' }),
      }),
    );
  });

  it('throws when Vertex AI responds with a non-OK status', async () => {
    const fetcher = fakeFetcher({ ok: false, status: 500, json: async () => ({}) });
    const adapter = resolveImageEmbeddingProviderAdapter({
      providerName: 'vertexAi',
      gcpProjectId: 'my-project',
      region: 'us-central1',
      fetcher: fetcher as unknown as typeof fetch,
      resolveAccessToken: async () => 'fake-token',
    });
    await expect(
      adapter.embedImage({ base64Image: 'abc', mimeType: 'image/jpeg' }),
    ).rejects.toThrow();
  });

  it('throws when Vertex AI returns an empty/invalid embedding instead of fabricating a vector', async () => {
    const fetcher = fakeFetcher({ ok: true, json: async () => ({ predictions: [{}] }) });
    const adapter = resolveImageEmbeddingProviderAdapter({
      providerName: 'vertexAi',
      gcpProjectId: 'my-project',
      region: 'us-central1',
      fetcher: fetcher as unknown as typeof fetch,
      resolveAccessToken: async () => 'fake-token',
    });
    await expect(
      adapter.embedImage({ base64Image: 'abc', mimeType: 'image/jpeg' }),
    ).rejects.toThrow('embedding vazio ou inválido');
  });
});
