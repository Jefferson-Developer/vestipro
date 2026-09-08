import {
  LlmProviderNotConfiguredError,
  resolveLlmProviderAdapter,
} from '../../src/shared/llm-provider-adapter';

function fakeFetcher(response: { ok: boolean; status?: number; json: () => Promise<unknown> }) {
  return jest.fn(async () => response as unknown as Response);
}

describe('resolveLlmProviderAdapter (shared)', () => {
  it('resolves to the disabled adapter when no provider is configured', () => {
    const adapter = resolveLlmProviderAdapter({
      providerName: undefined,
      apiKey: undefined,
      model: undefined,
    });
    expect(adapter.providerName).toBe('disabled');
  });

  it('throws with the caller-supplied notConfiguredMessage, never a hardcoded one', async () => {
    const adapter = resolveLlmProviderAdapter({
      providerName: undefined,
      apiKey: undefined,
      model: undefined,
      notConfiguredMessage: 'Configure APPROACH_SUGGESTION_LLM_PROVIDER.',
    });
    await expect(
      adapter.generateText({ systemPrompt: 's', userPrompt: 'u', maxOutputTokens: 100 }),
    ).rejects.toThrow('Configure APPROACH_SUGGESTION_LLM_PROVIDER.');
  });

  it('falls back to a generic message when the caller supplies none', async () => {
    const adapter = resolveLlmProviderAdapter({
      providerName: undefined,
      apiKey: undefined,
      model: undefined,
    });
    await expect(
      adapter.generateText({ systemPrompt: 's', userPrompt: 'u', maxOutputTokens: 100 }),
    ).rejects.toBeInstanceOf(LlmProviderNotConfiguredError);
  });

  it('resolves to the disabled adapter when the provider is set but no API key is present', () => {
    const adapter = resolveLlmProviderAdapter({
      providerName: 'anthropic',
      apiKey: '',
      model: undefined,
    });
    expect(adapter.providerName).toBe('disabled');
  });

  it('resolves to the disabled adapter for an unknown provider name', () => {
    const adapter = resolveLlmProviderAdapter({
      providerName: 'unknown-provider',
      apiKey: 'some-key',
      model: undefined,
    });
    expect(adapter.providerName).toBe('disabled');
  });

  it('resolves to the Anthropic adapter and calls the Messages API shape', async () => {
    const fetcher = fakeFetcher({
      ok: true,
      json: async () => ({ content: [{ type: 'text', text: 'Texto gerado [refs: a].' }] }),
    });
    const adapter = resolveLlmProviderAdapter({
      providerName: 'anthropic',
      apiKey: 'test-key',
      model: undefined,
      fetcher: fetcher as unknown as typeof fetch,
    });
    expect(adapter.providerName).toBe('anthropic');
    const text = await adapter.generateText({ systemPrompt: 's', userPrompt: 'u', maxOutputTokens: 100 });
    expect(text).toBe('Texto gerado [refs: a].');
    expect(fetcher).toHaveBeenCalledWith(
      'https://api.anthropic.com/v1/messages',
      expect.objectContaining({ method: 'POST' }),
    );
  });

  it('resolves to the OpenAI adapter and calls the Chat Completions API shape', async () => {
    const fetcher = fakeFetcher({
      ok: true,
      json: async () => ({ choices: [{ message: { content: 'Texto gerado [refs: a].' } }] }),
    });
    const adapter = resolveLlmProviderAdapter({
      providerName: 'openai',
      apiKey: 'test-key',
      model: undefined,
      fetcher: fetcher as unknown as typeof fetch,
    });
    expect(adapter.providerName).toBe('openai');
    const text = await adapter.generateText({ systemPrompt: 's', userPrompt: 'u', maxOutputTokens: 100 });
    expect(text).toBe('Texto gerado [refs: a].');
  });

  it('throws when the provider responds with a non-OK status', async () => {
    const fetcher = fakeFetcher({ ok: false, status: 500, json: async () => ({}) });
    const adapter = resolveLlmProviderAdapter({
      providerName: 'anthropic',
      apiKey: 'test-key',
      model: undefined,
      fetcher: fetcher as unknown as typeof fetch,
    });
    await expect(
      adapter.generateText({ systemPrompt: 's', userPrompt: 'u', maxOutputTokens: 100 }),
    ).rejects.toThrow();
  });
});
