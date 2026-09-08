/**
 * `generateWalletSummary` (TASK-186, EPIC-28) LLM-provider wiring. The
 * adapters themselves (interface + Anthropic/OpenAI/disabled
 * implementations) were extracted to `../shared/llm-provider-adapter.ts` when
 * TASK-187 ("sugestão de abordagem comercial") needed the exact same
 * pluggable-provider boundary — re-exported/re-wrapped from here so this
 * feature's own import path and disabled-adapter message (naming
 * `WALLET_SUMMARY_LLM_PROVIDER`/`WALLET_SUMMARY_LLM_API_KEY` specifically)
 * stay unchanged; `generate-wallet-summary.ts` and its tests never had to
 * change because of this move.
 */

import {
  resolveLlmProviderAdapter as resolveSharedLlmProviderAdapter,
  type LlmProviderAdapter,
  type ResolveLlmProviderAdapterParams as SharedResolveLlmProviderAdapterParams,
} from '../shared/llm-provider-adapter';

export {
  type LlmGenerationRequest,
  type LlmProviderAdapter,
  LlmProviderNotConfiguredError,
} from '../shared/llm-provider-adapter';

const WALLET_SUMMARY_NOT_CONFIGURED_MESSAGE =
  'Nenhum provedor de IA generativa está configurado para o resumo de ' +
  'carteira. Configure WALLET_SUMMARY_LLM_PROVIDER e o segredo ' +
  'WALLET_SUMMARY_LLM_API_KEY para ativar este recurso.';

export type ResolveLlmProviderAdapterParams = Omit<
  SharedResolveLlmProviderAdapterParams,
  'notConfiguredMessage'
>;

export function resolveLlmProviderAdapter(
  params: ResolveLlmProviderAdapterParams,
): LlmProviderAdapter {
  return resolveSharedLlmProviderAdapter({
    ...params,
    notConfiguredMessage: WALLET_SUMMARY_NOT_CONFIGURED_MESSAGE,
  });
}
