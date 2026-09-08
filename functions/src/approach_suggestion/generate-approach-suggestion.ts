import { defineSecret, defineString } from 'firebase-functions/params';
import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { Timestamp, getFirestore, type DocumentReference } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { loadActiveMembership, requireNonEmptyString } from '../invites/invite-shared';
import {
  LlmProviderNotConfiguredError,
  resolveLlmProviderAdapter,
} from '../shared/llm-provider-adapter';
import {
  APPROACH_SUGGESTION_CACHE_TTL_MINUTES,
  APPROACH_SUGGESTION_MIN_RETRY_AFTER_ERROR_MINUTES,
  approachSuggestionRef,
  assertCanAccessCustomer,
  buildApproachSuggestionPayload,
  buildApproachSuggestionPrompt,
  computePayloadHash,
  minutesToMs,
  resolveApproachSuggestionReferences,
  validateGeneratedApproachSuggestion,
} from './approach-suggestion-shared';
import type { ApproachSuggestionReference } from './approach-suggestion-types';

/** `APPROACH_SUGGESTION_LLM_API_KEY` — never read outside this file; passed
 * only into {@link resolveLlmProviderAdapter}, never logged, never echoed
 * back in any response. Activating a real provider in production requires
 * whoever manages this organization's Cloud Functions secrets to run
 * `firebase functions:secrets:set APPROACH_SUGGESTION_LLM_API_KEY` — until
 * then this resolves to an empty value and every call gets the disabled
 * adapter's controlled, recoverable failure (see
 * `../shared/llm-provider-adapter.ts`'s own doc comment). Deliberately its
 * own secret/provider-name pair, independent from
 * `WALLET_SUMMARY_LLM_PROVIDER`/`WALLET_SUMMARY_LLM_API_KEY` — an
 * organization may want a different provider (or none) for each generative
 * feature. */
const approachSuggestionLlmApiKey = defineSecret('APPROACH_SUGGESTION_LLM_API_KEY');

/** `'anthropic' | 'openai'` (or unset/`'disabled'`) — a plain runtime
 * parameter, not a secret, since a provider *name* is not sensitive. */
const approachSuggestionLlmProvider = defineString('APPROACH_SUGGESTION_LLM_PROVIDER', {
  default: 'disabled',
});

/** Optional model override — falls back to each adapter's own default when
 * unset. */
const approachSuggestionLlmModel = defineString('APPROACH_SUGGESTION_LLM_MODEL', {
  default: '',
});

const APPROACH_SUGGESTION_NOT_CONFIGURED_MESSAGE =
  'Nenhum provedor de IA generativa está configurado para a sugestão de ' +
  'abordagem. Configure APPROACH_SUGGESTION_LLM_PROVIDER e o segredo ' +
  'APPROACH_SUGGESTION_LLM_API_KEY para ativar este recurso.';

const MAX_OUTPUT_TOKENS = 500;

export interface SuggestApproachRequest extends RequestWithMeta {
  organizationId?: string;
  companyId?: string;
  customerId?: string;
}

export interface SuggestApproachResponse {
  suggestedText: string;
  references: ApproachSuggestionReference[];
  generatedAt: string;
  expiresAt: string;
  fromCache: boolean;
  correlationId: string;
}

/**
 * Generates (or reuses a cached) short, editable commercial-approach draft
 * for one customer — TASK-187, EPIC-28.
 *
 * The payload sent to the configured LLM provider is assembled entirely
 * server-side from already-persisted, real data
 * ({@link buildApproachSuggestionPayload} — recent orders, recent CRM
 * activities, active insights) — never free text a caller supplies. The
 * generated text is rejected
 * ({@link validateGeneratedApproachSuggestion}) unless every numeric claim
 * traces back to that same payload, every claim carries a `[refs: ...]`
 * citation, and the text names no discount/price/contractual-promise term —
 * a caller never sees a suggestion without rastreabilidade, a fabricated
 * number, or a commercial commitment this Function never authorized.
 *
 * The response is always a *draft*: nothing about this Function ever sends
 * a message, creates a CRM activity, or otherwise contacts the customer —
 * `tasks.md`/TASK-187: "A sugestão é sempre um rascunho editável; nunca
 * dispara mensagem ou ação automaticamente" is enforced simply by this
 * Function having no such side effect to begin with.
 */
export const suggestApproach = onCall<
  SuggestApproachRequest,
  Promise<SuggestApproachResponse>
>(
  { secrets: [approachSuggestionLlmApiKey] },
  async (request) => {
    const correlationId = resolveCorrelationId(request.data?._meta);

    if (!request.auth) {
      throw new HttpsError(
        'unauthenticated',
        'É necessário estar autenticado para gerar uma sugestão de abordagem.',
      );
    }
    const uid = request.auth.uid;

    const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
    const companyId = requireNonEmptyString(request.data?.companyId, 'companyId');
    const customerId = requireNonEmptyString(request.data?.customerId, 'customerId');

    const db = getFirestore();
    const membership = await loadActiveMembership(db, organizationId, uid);
    await assertCanAccessCustomer({
      db,
      organizationId,
      requesterUid: uid,
      requesterRoleName: membership.roleName,
      customerId,
    });

    const customerSnapshot = await db
      .collection('organizations')
      .doc(organizationId)
      .collection('customers')
      .doc(customerId)
      .get();
    if (!customerSnapshot.exists) {
      throw new HttpsError('not-found', 'Cliente não encontrado nesta organização.');
    }
    const customerData = customerSnapshot.data() ?? {};
    const customerName = resolveCustomerDisplayName(customerData, customerId);
    const customerSegment =
      typeof customerData.segment === 'string' && customerData.segment.trim().length > 0
        ? customerData.segment.trim()
        : null;
    const customerPotential =
      typeof customerData.potential === 'string' && customerData.potential.trim().length > 0
        ? customerData.potential.trim()
        : null;

    const payload = await buildApproachSuggestionPayload({
      db,
      organizationId,
      companyId,
      customerId,
      customerName,
      customerSegment,
      customerPotential,
    });
    const payloadHash = computePayloadHash(payload);

    const cacheRef = approachSuggestionRef(db, organizationId, customerId);
    const cacheSnapshot = await cacheRef.get();
    const cached = cacheSnapshot.data();

    if (cached?.payloadHash === payloadHash) {
      if (cached.status === 'ready') {
        const generatedAtMs = toMillis(cached.generatedAt);
        const isFresh =
          generatedAtMs != null &&
          Date.now() - generatedAtMs < minutesToMs(APPROACH_SUGGESTION_CACHE_TTL_MINUTES);
        if (isFresh) {
          return {
            suggestedText: cached.suggestedText as string,
            references: (cached.references as ApproachSuggestionReference[]) ?? [],
            generatedAt: toIso(cached.generatedAt),
            expiresAt: toIso(cached.expiresAt),
            fromCache: true,
            correlationId,
          };
        }
      } else if (cached.status === 'error') {
        const lastAttemptMs = toMillis(cached.lastAttemptAt);
        const stillThrottled =
          lastAttemptMs != null &&
          Date.now() - lastAttemptMs <
            minutesToMs(APPROACH_SUGGESTION_MIN_RETRY_AFTER_ERROR_MINUTES);
        if (stillThrottled) {
          throw new HttpsError(
            'resource-exhausted',
            'Não foi possível gerar uma sugestão há pouco tempo. Aguarde alguns minutos antes de tentar novamente.',
          );
        }
      }
    }

    const adapter = resolveLlmProviderAdapter({
      providerName: approachSuggestionLlmProvider.value(),
      apiKey: approachSuggestionLlmApiKey.value(),
      model: approachSuggestionLlmModel.value(),
      notConfiguredMessage: APPROACH_SUGGESTION_NOT_CONFIGURED_MESSAGE,
    });
    const { systemPrompt, userPrompt } = buildApproachSuggestionPrompt(payload);

    let generatedText: string;
    try {
      generatedText = await adapter.generateText({
        systemPrompt,
        userPrompt,
        maxOutputTokens: MAX_OUTPUT_TOKENS,
      });
    } catch (error) {
      const message =
        error instanceof LlmProviderNotConfiguredError
          ? error.message
          : 'O provedor de IA generativa está indisponível no momento. Tente novamente em instantes.';
      await persistErrorCache(cacheRef, {
        organizationId,
        companyId,
        customerId,
        payloadHash,
        errorReason: message,
        requestedBy: uid,
      });
      logger.error('suggestApproach provider call failed', {
        correlationId,
        organizationId,
        customerId,
        error: error instanceof Error ? error.message : String(error),
      });
      throw new HttpsError('unavailable', message);
    }

    let validation = validateGeneratedApproachSuggestion(generatedText, payload);
    if (!validation.ok) {
      // One controlled retry with a stricter reminder — never more than
      // this, so a persistently-hallucinating/non-compliant provider fails
      // fast instead of looping (and costing more) indefinitely.
      logger.warn('suggestApproach first validation failed, retrying once', {
        correlationId,
        organizationId,
        customerId,
        reason: validation.reason,
      });
      try {
        generatedText = await adapter.generateText({
          systemPrompt:
            systemPrompt +
            '\nATENÇÃO: sua resposta anterior violou uma regra obrigatória ' +
            '(número/fato fora dos dados fornecidos, citação ausente/incorreta ' +
            'ou menção a desconto/preço/condição comercial/compromisso). ' +
            'Responda novamente seguindo estritamente as regras.',
          userPrompt,
          maxOutputTokens: MAX_OUTPUT_TOKENS,
        });
      } catch {
        generatedText = '';
      }
      validation = validateGeneratedApproachSuggestion(generatedText, payload);
    }

    if (!validation.ok) {
      const errorReason =
        'Não foi possível gerar uma sugestão de abordagem confiável com base nos dados disponíveis no momento.';
      await persistErrorCache(cacheRef, {
        organizationId,
        companyId,
        customerId,
        payloadHash,
        errorReason,
        requestedBy: uid,
      });
      logger.error('suggestApproach validation failed after retry', {
        correlationId,
        organizationId,
        customerId,
        reason: validation.reason,
        detail: validation.detail,
      });
      throw new HttpsError('failed-precondition', errorReason);
    }

    const references = resolveApproachSuggestionReferences(payload, validation.citedDataPointCodes);
    const now = new Date();
    const generatedAt = Timestamp.fromDate(now);
    const expiresAt = Timestamp.fromMillis(
      now.getTime() + minutesToMs(APPROACH_SUGGESTION_CACHE_TTL_MINUTES),
    );

    await cacheRef.set({
      organizationId,
      companyId,
      customerId,
      status: 'ready',
      payloadHash,
      suggestedText: generatedText,
      references,
      errorReason: null,
      provider: adapter.providerName,
      model: adapter.model,
      generatedAt,
      expiresAt,
      lastAttemptAt: generatedAt,
      requestedBy: uid,
    });

    logger.info('suggestApproach succeeded', {
      correlationId,
      organizationId,
      customerId,
      provider: adapter.providerName,
    });

    return {
      suggestedText: generatedText,
      references,
      generatedAt: generatedAt.toDate().toISOString(),
      expiresAt: expiresAt.toDate().toISOString(),
      fromCache: false,
      correlationId,
    };
  },
);

function resolveCustomerDisplayName(
  data: FirebaseFirestore.DocumentData,
  fallback: string,
): string {
  const tradeName = typeof data.tradeName === 'string' ? data.tradeName.trim() : '';
  if (tradeName) return tradeName;
  const legalName = typeof data.legalName === 'string' ? data.legalName.trim() : '';
  if (legalName) return legalName;
  const fullName = typeof data.fullName === 'string' ? data.fullName.trim() : '';
  if (fullName) return fullName;
  return fallback;
}

async function persistErrorCache(
  cacheRef: DocumentReference,
  params: {
    organizationId: string;
    companyId: string;
    customerId: string;
    payloadHash: string;
    errorReason: string;
    requestedBy: string;
  },
): Promise<void> {
  const now = Timestamp.now();
  await cacheRef.set({
    organizationId: params.organizationId,
    companyId: params.companyId,
    customerId: params.customerId,
    status: 'error',
    payloadHash: params.payloadHash,
    suggestedText: null,
    references: null,
    errorReason: params.errorReason,
    provider: null,
    model: null,
    generatedAt: null,
    expiresAt: null,
    lastAttemptAt: now,
    requestedBy: params.requestedBy,
  });
}

function toMillis(value: unknown): number | null {
  if (value instanceof Timestamp) return value.toMillis();
  return null;
}

function toIso(value: unknown): string {
  if (value instanceof Timestamp) return value.toDate().toISOString();
  return new Date(0).toISOString();
}
