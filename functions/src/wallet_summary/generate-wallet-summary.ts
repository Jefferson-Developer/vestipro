import { defineSecret, defineString } from 'firebase-functions/params';
import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { Timestamp, getFirestore, type DocumentReference } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { loadActiveMembership, requireNonEmptyString } from '../invites/invite-shared';
import {
  LlmProviderNotConfiguredError,
  resolveLlmProviderAdapter,
} from './llm-provider-adapter';
import {
  WALLET_SUMMARY_CACHE_TTL_MINUTES,
  WALLET_SUMMARY_MIN_RETRY_AFTER_ERROR_MINUTES,
  assertCanAccessSellerWallet,
  buildWalletSummaryPayload,
  buildWalletSummaryPrompt,
  computePayloadHash,
  minutesToMs,
  resolveWalletSummaryReferences,
  validateGeneratedSummary,
  walletSummaryRef,
} from './wallet-summary-shared';
import type { WalletSummaryReference } from './wallet-summary-types';

/** `WALLET_SUMMARY_LLM_API_KEY` — never read outside this file; passed only
 * into {@link resolveLlmProviderAdapter}, never logged, never echoed back in
 * any response. Activating a real provider in production requires whoever
 * manages this organization's Cloud Functions secrets to run
 * `firebase functions:secrets:set WALLET_SUMMARY_LLM_API_KEY` — until then
 * this resolves to an empty value and every call gets the disabled adapter's
 * controlled, recoverable failure (see `llm-provider-adapter.ts`'s own doc
 * comment). */
const walletSummaryLlmApiKey = defineSecret('WALLET_SUMMARY_LLM_API_KEY');

/** `'anthropic' | 'openai'` (or unset/`'disabled'`) — a plain runtime
 * parameter, not a secret, since a provider *name* is not sensitive. Backed
 * by `firebase-functions/params`, resolvable from a `.env`/Remote Config-
 * style deploy-time value without ever hardcoding a provider choice in
 * source. */
const walletSummaryLlmProvider = defineString('WALLET_SUMMARY_LLM_PROVIDER', {
  default: 'disabled',
});

/** Optional model override — falls back to each adapter's own default when
 * unset. */
const walletSummaryLlmModel = defineString('WALLET_SUMMARY_LLM_MODEL', {
  default: '',
});

const MAX_OUTPUT_TOKENS = 700;

export interface GenerateWalletSummaryRequest extends RequestWithMeta {
  organizationId?: string;
  companyId?: string;
  sellerId?: string;
}

export interface GenerateWalletSummaryResponse {
  summaryText: string;
  references: WalletSummaryReference[];
  periodKey: string;
  generatedAt: string;
  expiresAt: string;
  fromCache: boolean;
  correlationId: string;
}

/**
 * Generates (or reuses a cached) natural-language summary of one seller's
 * carteira — highlights, riscos e oportunidades — for TASK-186 (EPIC-28).
 *
 * The payload sent to the configured LLM provider is assembled entirely
 * server-side from already-computed data
 * ({@link buildWalletSummaryPayload}) — never raw orders, never free text a
 * caller supplies. The generated text is rejected
 * ({@link validateGeneratedSummary}) unless every numeric claim traces back
 * to that same payload, and every claim carries a `[refs: ...]` citation the
 * UI can expand — a caller never sees a summary without rastreabilidade, and
 * never sees a fabricated number.
 *
 * A cache entry (`organizations/{organizationId}/walletSummaries/{sellerId}_{periodKey}`)
 * is reused only while both the {@link WALLET_SUMMARY_CACHE_TTL_MINUTES}
 * window is open AND the freshly-rebuilt payload still hashes the same as
 * the one that produced it — a relevant data change (new insight, updated
 * month aggregate) always invalidates it early. A repeated call shortly
 * after a failed attempt for the exact same (unchanged) payload is throttled
 * ({@link WALLET_SUMMARY_MIN_RETRY_AFTER_ERROR_MINUTES}) instead of hitting
 * the provider again.
 */
export const generateWalletSummary = onCall<
  GenerateWalletSummaryRequest,
  Promise<GenerateWalletSummaryResponse>
>(
  { secrets: [walletSummaryLlmApiKey] },
  async (request) => {
    const correlationId = resolveCorrelationId(request.data?._meta);

    if (!request.auth) {
      throw new HttpsError(
        'unauthenticated',
        'É necessário estar autenticado para gerar o resumo da carteira.',
      );
    }
    const uid = request.auth.uid;

    const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
    const companyId = requireNonEmptyString(request.data?.companyId, 'companyId');
    const sellerId = requireNonEmptyString(request.data?.sellerId, 'sellerId');

    const db = getFirestore();
    const membership = await loadActiveMembership(db, organizationId, uid);
    await assertCanAccessSellerWallet({
      db,
      organizationId,
      requesterUid: uid,
      requesterRoleName: membership.roleName,
      sellerId,
    });

    const sellerSnapshot = await db
      .collection('organizations')
      .doc(organizationId)
      .collection('members')
      .doc(sellerId)
      .get();
    if (!sellerSnapshot.exists) {
      throw new HttpsError('not-found', 'Vendedor não encontrado nesta organização.');
    }
    const sellerName = (sellerSnapshot.data()?.name as string | undefined)?.trim() || sellerId;

    const now = new Date();
    const payload = await buildWalletSummaryPayload({
      db,
      organizationId,
      companyId,
      sellerId,
      sellerName,
      now,
    });
    const payloadHash = computePayloadHash(payload);

    const cacheRef = walletSummaryRef(db, organizationId, sellerId, payload.periodKey);
    const cacheSnapshot = await cacheRef.get();
    const cached = cacheSnapshot.data();

    if (cached?.payloadHash === payloadHash) {
      if (cached.status === 'ready') {
        const generatedAtMs = toMillis(cached.generatedAt);
        const isFresh =
          generatedAtMs != null &&
          Date.now() - generatedAtMs < minutesToMs(WALLET_SUMMARY_CACHE_TTL_MINUTES);
        if (isFresh) {
          return {
            summaryText: cached.summaryText as string,
            references: (cached.references as WalletSummaryReference[]) ?? [],
            periodKey: payload.periodKey,
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
            minutesToMs(WALLET_SUMMARY_MIN_RETRY_AFTER_ERROR_MINUTES);
        if (stillThrottled) {
          throw new HttpsError(
            'resource-exhausted',
            'Não foi possível gerar o resumo há pouco tempo. Aguarde alguns minutos antes de tentar novamente.',
          );
        }
      }
    }

    const adapter = resolveLlmProviderAdapter({
      providerName: walletSummaryLlmProvider.value(),
      apiKey: walletSummaryLlmApiKey.value(),
      model: walletSummaryLlmModel.value(),
    });
    const { systemPrompt, userPrompt } = buildWalletSummaryPrompt(payload);

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
        sellerId,
        periodKey: payload.periodKey,
        payloadHash,
        errorReason: message,
        requestedBy: uid,
      });
      logger.error('generateWalletSummary provider call failed', {
        correlationId,
        organizationId,
        sellerId,
        error: error instanceof Error ? error.message : String(error),
      });
      throw new HttpsError('unavailable', message);
    }

    let validation = validateGeneratedSummary(generatedText, payload);
    if (!validation.ok) {
      // One controlled retry with a stricter reminder — never more than
      // this, so a persistently-hallucinating provider fails fast instead of
      // looping (and costing more) indefinitely.
      logger.warn('generateWalletSummary first validation failed, retrying once', {
        correlationId,
        organizationId,
        sellerId,
        reason: validation.reason,
      });
      try {
        generatedText = await adapter.generateText({
          systemPrompt:
            systemPrompt +
            '\nATENÇÃO: sua resposta anterior violou uma regra obrigatória ' +
            '(número fora dos dados fornecidos ou citação ausente/incorreta). ' +
            'Responda novamente seguindo estritamente as regras.',
          userPrompt,
          maxOutputTokens: MAX_OUTPUT_TOKENS,
        });
      } catch {
        generatedText = '';
      }
      validation = validateGeneratedSummary(generatedText, payload);
    }

    if (!validation.ok) {
      const errorReason =
        'Não foi possível gerar um resumo confiável com base nos dados disponíveis no momento.';
      await persistErrorCache(cacheRef, {
        organizationId,
        companyId,
        sellerId,
        periodKey: payload.periodKey,
        payloadHash,
        errorReason,
        requestedBy: uid,
      });
      logger.error('generateWalletSummary validation failed after retry', {
        correlationId,
        organizationId,
        sellerId,
        reason: validation.reason,
        detail: validation.detail,
      });
      throw new HttpsError('failed-precondition', errorReason);
    }

    const references = resolveWalletSummaryReferences(payload, validation.citedDataPointCodes);
    const generatedAt = Timestamp.fromDate(now);
    const expiresAt = Timestamp.fromMillis(
      now.getTime() + minutesToMs(WALLET_SUMMARY_CACHE_TTL_MINUTES),
    );

    await cacheRef.set({
      organizationId,
      companyId,
      sellerId,
      periodKey: payload.periodKey,
      status: 'ready',
      payloadHash,
      summaryText: generatedText,
      references,
      errorReason: null,
      provider: adapter.providerName,
      model: adapter.model,
      generatedAt,
      expiresAt,
      lastAttemptAt: generatedAt,
      requestedBy: uid,
    });

    logger.info('generateWalletSummary succeeded', {
      correlationId,
      organizationId,
      sellerId,
      periodKey: payload.periodKey,
      provider: adapter.providerName,
    });

    return {
      summaryText: generatedText,
      references,
      periodKey: payload.periodKey,
      generatedAt: generatedAt.toDate().toISOString(),
      expiresAt: expiresAt.toDate().toISOString(),
      fromCache: false,
      correlationId,
    };
  },
);

async function persistErrorCache(
  cacheRef: DocumentReference,
  params: {
    organizationId: string;
    companyId: string;
    sellerId: string;
    periodKey: string;
    payloadHash: string;
    errorReason: string;
    requestedBy: string;
  },
): Promise<void> {
  const now = Timestamp.now();
  await cacheRef.set({
    organizationId: params.organizationId,
    companyId: params.companyId,
    sellerId: params.sellerId,
    periodKey: params.periodKey,
    status: 'error',
    payloadHash: params.payloadHash,
    summaryText: null,
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
