/**
 * Pluggable LLM-provider boundary for `generateWalletSummary` (TASK-186,
 * EPIC-28). No concrete provider SDK is a dependency of this codebase today
 * (`functions/package.json` has neither `@anthropic-ai/sdk` nor `openai`) —
 * every adapter below talks to its provider over plain `fetch` (Node 20's
 * built-in global, the same primitive `whatsapp-shared.ts`'s
 * `sendMetaTemplateMessage` already uses for the exact same reason: one
 * fewer third-party dependency to vet/update for a single HTTP call).
 *
 * {@link resolveLlmProviderAdapter} is the single place that decides which
 * concrete adapter answers for a given configuration — never a hardcoded
 * choice, and never a secret literal in source. When no provider is
 * configured (no `providerName`, an unknown one, or a missing API key) it
 * resolves to {@link DisabledLlmProviderAdapter}, which always fails in a
 * clearly-labeled, non-silent way: `generateWalletSummary` is fully
 * implementable and testable end-to-end against this boundary today; only
 * turning it on for real, in production, needs whoever manages this
 * organization's secrets to configure `WALLET_SUMMARY_LLM_PROVIDER`
 * (Cloud Functions runtime env var) and the `WALLET_SUMMARY_LLM_API_KEY`
 * secret (`firebase functions:secrets:set`) for a real provider — this
 * module never calls a real LLM API without that credential in place, and
 * never hardcodes one.
 */

export interface LlmGenerationRequest {
  systemPrompt: string;
  userPrompt: string;
  maxOutputTokens: number;
}

export interface LlmProviderAdapter {
  readonly providerName: string;
  readonly model: string;
  generateText(request: LlmGenerationRequest): Promise<string>;
}

/** Thrown by {@link DisabledLlmProviderAdapter} and by any concrete adapter
 * when the provider itself reports a fatal (non-retryable) configuration
 * problem (e.g. an invalid API key) — `generate-wallet-summary.ts` catches
 * this the same way as any other provider failure (a recoverable error
 * state, never surfaced as a fabricated summary), but keeps it as a distinct
 * class so a future caller could special-case "not configured at all" from
 * "configured but the call itself failed" if that distinction ever becomes
 * useful (logs/alerting).
 */
export class LlmProviderNotConfiguredError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'LlmProviderNotConfiguredError';
  }
}

class DisabledLlmProviderAdapter implements LlmProviderAdapter {
  readonly providerName = 'disabled';
  readonly model = 'none';

  async generateText(): Promise<string> {
    throw new LlmProviderNotConfiguredError(
      'Nenhum provedor de IA generativa está configurado para o resumo de ' +
        'carteira. Configure WALLET_SUMMARY_LLM_PROVIDER e o segredo ' +
        'WALLET_SUMMARY_LLM_API_KEY para ativar este recurso.',
    );
  }
}

const DEFAULT_ANTHROPIC_MODEL = 'claude-3-5-haiku-20241022';
const DEFAULT_OPENAI_MODEL = 'gpt-4o-mini';

/** Reference adapter for Anthropic's Messages API
 * (https://api.anthropic.com/v1/messages). */
class AnthropicLlmProviderAdapter implements LlmProviderAdapter {
  readonly providerName = 'anthropic';

  constructor(
    private readonly apiKey: string,
    readonly model: string = DEFAULT_ANTHROPIC_MODEL,
    private readonly fetcher: typeof fetch = fetch,
  ) {}

  async generateText(request: LlmGenerationRequest): Promise<string> {
    const response = await this.fetcher('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'x-api-key': this.apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        model: this.model,
        max_tokens: request.maxOutputTokens,
        system: request.systemPrompt,
        messages: [{ role: 'user', content: request.userPrompt }],
      }),
    });
    if (!response.ok) {
      throw new Error(
        `Anthropic respondeu ${response.status} ao gerar o resumo de carteira.`,
      );
    }
    const json = (await response.json()) as {
      content?: { type: string; text?: string }[];
    };
    const text = json.content
      ?.filter((block) => block.type === 'text' && typeof block.text === 'string')
      .map((block) => block.text)
      .join('\n')
      .trim();
    if (!text) {
      throw new Error('Anthropic retornou uma resposta vazia.');
    }
    return text;
  }
}

/** Reference adapter for OpenAI's Chat Completions API
 * (https://api.openai.com/v1/chat/completions). */
class OpenAiLlmProviderAdapter implements LlmProviderAdapter {
  readonly providerName = 'openai';

  constructor(
    private readonly apiKey: string,
    readonly model: string = DEFAULT_OPENAI_MODEL,
    private readonly fetcher: typeof fetch = fetch,
  ) {}

  async generateText(request: LlmGenerationRequest): Promise<string> {
    const response = await this.fetcher(
      'https://api.openai.com/v1/chat/completions',
      {
        method: 'POST',
        headers: {
          authorization: `Bearer ${this.apiKey}`,
          'content-type': 'application/json',
        },
        body: JSON.stringify({
          model: this.model,
          max_tokens: request.maxOutputTokens,
          messages: [
            { role: 'system', content: request.systemPrompt },
            { role: 'user', content: request.userPrompt },
          ],
        }),
      },
    );
    if (!response.ok) {
      throw new Error(
        `OpenAI respondeu ${response.status} ao gerar o resumo de carteira.`,
      );
    }
    const json = (await response.json()) as {
      choices?: { message?: { content?: string } }[];
    };
    const text = json.choices?.[0]?.message?.content?.trim();
    if (!text) {
      throw new Error('OpenAI retornou uma resposta vazia.');
    }
    return text;
  }
}

export interface ResolveLlmProviderAdapterParams {
  /** `WALLET_SUMMARY_LLM_PROVIDER` — `'anthropic' | 'openai'`, anything else
   * (including empty/undefined) resolves to the disabled adapter. */
  providerName: string | undefined;
  /** `WALLET_SUMMARY_LLM_API_KEY` secret value. A configured [providerName]
   * without a key still resolves to the disabled adapter — never attempts a
   * call with an empty credential. */
  apiKey: string | undefined;
  /** `WALLET_SUMMARY_LLM_MODEL`, optional — falls back to each adapter's own
   * default model when unset. */
  model: string | undefined;
  /** Injectable for tests — never used with a real network call outside
   * production. */
  fetcher?: typeof fetch;
}

export function resolveLlmProviderAdapter(
  params: ResolveLlmProviderAdapterParams,
): LlmProviderAdapter {
  const provider = (params.providerName ?? '').trim().toLowerCase();
  const apiKey = params.apiKey?.trim();
  if (!provider || provider === 'disabled' || !apiKey) {
    return new DisabledLlmProviderAdapter();
  }
  const model = params.model?.trim() || undefined;
  switch (provider) {
    case 'anthropic':
      return new AnthropicLlmProviderAdapter(apiKey, model ?? DEFAULT_ANTHROPIC_MODEL, params.fetcher);
    case 'openai':
      return new OpenAiLlmProviderAdapter(apiKey, model ?? DEFAULT_OPENAI_MODEL, params.fetcher);
    default:
      return new DisabledLlmProviderAdapter();
  }
}
