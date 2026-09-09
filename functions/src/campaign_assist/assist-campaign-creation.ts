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
  CAMPAIGN_ASSIST_CACHE_TTL_MINUTES,
  CAMPAIGN_ASSIST_MAX_AUDIENCE_LENGTH,
  CAMPAIGN_ASSIST_MAX_PRODUCTS,
  CAMPAIGN_ASSIST_MAX_TONE_LENGTH,
  CAMPAIGN_ASSIST_MIN_RETRY_AFTER_ERROR_MINUTES,
  assertCanAssistCampaignCreation,
  buildCampaignAssistPayload,
  buildCampaignAssistPrompt,
  campaignAssistCacheKey,
  computePayloadHash,
  loadCampaignAssistProductReferences,
  validateGeneratedCampaignAssist,
} from './campaign-assist-shared';

/** `CAMPAIGN_ASSIST_LLM_API_KEY` — never read outside this file; passed only
 * into {@link resolveLlmProviderAdapter}, never logged, never echoed back in
 * any response. Activating a real provider in production requires whoever
 * manages this organization's Cloud Functions secrets to run
 * `firebase functions:secrets:set CAMPAIGN_ASSIST_LLM_API_KEY` — until then
 * this resolves to an empty value and every call gets the disabled adapter's
 * controlled, recoverable failure. Deliberately its own secret/provider-name
 * pair, independent from every other EPIC-28 feature's own
 * (`APPROACH_SUGGESTION_LLM_*`, `REPORT_EXPLANATION_LLM_*`, etc.) — an
 * organization may want a different provider (or none) for each generative
 * feature. */
const campaignAssistLlmApiKey = defineSecret('CAMPAIGN_ASSIST_LLM_API_KEY');

const campaignAssistLlmProvider = defineString('CAMPAIGN_ASSIST_LLM_PROVIDER', {
  default: 'disabled',
});

const campaignAssistLlmModel = defineString('CAMPAIGN_ASSIST_LLM_MODEL', {
  default: '',
});

const CAMPAIGN_ASSIST_NOT_CONFIGURED_MESSAGE =
  'Nenhum provedor de IA generativa está configurado para a criação assistida ' +
  'de campanha. Configure CAMPAIGN_ASSIST_LLM_PROVIDER e o segredo ' +
  'CAMPAIGN_ASSIST_LLM_API_KEY para ativar este recurso.';

const MAX_OUTPUT_TOKENS = 700;

export interface AssistCampaignCreationRequest extends RequestWithMeta {
  organizationId?: string;
  productIds?: unknown;
  audienceDescription?: string;
  tone?: string;
  startAt?: string | null;
  endAt?: string | null;
}

export interface AssistCampaignCreationResponse {
  title: string;
  subtitle: string;
  description: string;
  citedProductIds: string[];
  generatedAt: string;
  expiresAt: string;
  fromCache: boolean;
  correlationId: string;
}

/**
 * Generates (or reuses a cached) editable draft of a `CatalogCampaign`'s
 * (TASK-080) textual structure — title, subtitle/headline, editorial
 * description — from parameters an admin/gestor explicitly supplies
 * (selected product ids, público-alvo, período, tom de comunicação) —
 * TASK-192, EPIC-28.
 *
 * Every product the generated text is allowed to mention comes from this
 * organization's own already-persisted `products` documents
 * ({@link loadCampaignAssistProductReferences}, re-resolved server-side from
 * the caller's own `organizationId` — never a name/category/collection
 * string the client claims directly). The generated text is rejected
 * ({@link validateGeneratedCampaignAssist}) unless it is well-formed JSON
 * within field-length limits, every cited product id is real, at least one
 * cited product's real name is grounded in the text, and no field mentions a
 * discount/price/commercial-commitment term.
 *
 * The response is always a *draft*: nothing about this Function ever creates
 * or publishes a `CatalogCampaign` itself — `tasks.md`/TASK-192: "sempre como
 * rascunho revisável antes de publicar — nunca publicando automaticamente"
 * is enforced simply by this Function having no such side effect to begin
 * with; the admin still goes through the existing `CampaignFormPage`
 * (TASK-080) publish flow to accept (and may further edit) this draft.
 */
export const assistCampaignCreation = onCall<
  AssistCampaignCreationRequest,
  Promise<AssistCampaignCreationResponse>
>(
  { secrets: [campaignAssistLlmApiKey] },
  async (request) => {
    const correlationId = resolveCorrelationId(request.data?._meta);

    if (!request.auth) {
      throw new HttpsError(
        'unauthenticated',
        'É necessário estar autenticado para gerar uma sugestão de campanha.',
      );
    }
    const uid = request.auth.uid;

    const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
    const audienceDescription = requireNonEmptyString(
      request.data?.audienceDescription,
      'audienceDescription',
    ).slice(0, CAMPAIGN_ASSIST_MAX_AUDIENCE_LENGTH);
    const tone = requireNonEmptyString(request.data?.tone, 'tone').slice(
      0,
      CAMPAIGN_ASSIST_MAX_TONE_LENGTH,
    );
    const startAt = parseOptionalDate(request.data?.startAt, 'startAt');
    const endAt = parseOptionalDate(request.data?.endAt, 'endAt');
    if (startAt && endAt && endAt.getTime() < startAt.getTime()) {
      throw new HttpsError(
        'invalid-argument',
        'A data de término deve ser posterior à data de início.',
      );
    }
    const productIds = parseProductIds(request.data?.productIds);

    const db = getFirestore();
    const membership = await loadActiveMembership(db, organizationId, uid);
    assertCanAssistCampaignCreation(membership.roleName);

    const productReferences = await loadCampaignAssistProductReferences(
      db,
      organizationId,
      productIds,
    );

    const payload = buildCampaignAssistPayload({
      organizationId,
      audienceDescription,
      tone,
      startAt,
      endAt,
      productReferences,
    });
    const payloadHash = computePayloadHash(payload);
    const cacheKey = campaignAssistCacheKey({ requesterUid: uid, payloadHash });

    const cacheRef = db
      .collection('organizations')
      .doc(organizationId)
      .collection('campaignAssistDrafts')
      .doc(cacheKey);
    const cacheSnapshot = await cacheRef.get();
    const cached = cacheSnapshot.data();

    if (cached?.payloadHash === payloadHash) {
      if (cached.status === 'ready') {
        const generatedAtMs = toMillis(cached.generatedAt);
        const isFresh =
          generatedAtMs != null &&
          Date.now() - generatedAtMs < CAMPAIGN_ASSIST_CACHE_TTL_MINUTES * 60 * 1000;
        if (isFresh) {
          return {
            title: cached.title as string,
            subtitle: cached.subtitle as string,
            description: cached.description as string,
            citedProductIds: (cached.citedProductIds as string[]) ?? [],
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
            CAMPAIGN_ASSIST_MIN_RETRY_AFTER_ERROR_MINUTES * 60 * 1000;
        if (stillThrottled) {
          throw new HttpsError(
            'resource-exhausted',
            'Não foi possível gerar uma sugestão de campanha há pouco tempo. Aguarde alguns minutos antes de tentar novamente.',
          );
        }
      }
    }

    const adapter = resolveLlmProviderAdapter({
      providerName: campaignAssistLlmProvider.value(),
      apiKey: campaignAssistLlmApiKey.value(),
      model: campaignAssistLlmModel.value(),
      notConfiguredMessage: CAMPAIGN_ASSIST_NOT_CONFIGURED_MESSAGE,
    });
    const { systemPrompt, userPrompt } = buildCampaignAssistPrompt(payload);

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
        requestedBy: uid,
        payloadHash,
        errorReason: message,
      });
      logger.error('assistCampaignCreation provider call failed', {
        correlationId,
        organizationId,
        error: error instanceof Error ? error.message : String(error),
      });
      throw new HttpsError('unavailable', message);
    }

    let validation = validateGeneratedCampaignAssist(generatedText, payload);
    if (!validation.ok) {
      // One controlled retry with a stricter reminder — never more than
      // this, so a persistently-non-compliant provider fails fast instead
      // of looping (and costing more) indefinitely.
      logger.warn('assistCampaignCreation first validation failed, retrying once', {
        correlationId,
        organizationId,
        reason: validation.reason,
      });
      try {
        generatedText = await adapter.generateText({
          systemPrompt:
            systemPrompt +
            '\nATENÇÃO: sua resposta anterior violou uma regra obrigatória ' +
            '(JSON inválido, campo fora do tamanho permitido, produto citado ' +
            'fora da lista fornecida ou menção a desconto/preço/condição ' +
            'comercial/compromisso). Responda novamente seguindo estritamente ' +
            'as regras, apenas com o objeto JSON pedido.',
          userPrompt,
          maxOutputTokens: MAX_OUTPUT_TOKENS,
        });
      } catch {
        generatedText = '';
      }
      validation = validateGeneratedCampaignAssist(generatedText, payload);
    }

    if (!validation.ok) {
      const errorReason =
        'Não foi possível gerar um rascunho de campanha confiável com base nos dados fornecidos no momento.';
      await persistErrorCache(cacheRef, {
        organizationId,
        requestedBy: uid,
        payloadHash,
        errorReason,
      });
      logger.error('assistCampaignCreation validation failed after retry', {
        correlationId,
        organizationId,
        reason: validation.reason,
        detail: validation.detail,
      });
      throw new HttpsError('failed-precondition', errorReason);
    }

    const now = new Date();
    const generatedAt = Timestamp.fromDate(now);
    const expiresAt = Timestamp.fromMillis(
      now.getTime() + CAMPAIGN_ASSIST_CACHE_TTL_MINUTES * 60 * 1000,
    );

    await cacheRef.set({
      organizationId,
      requestedBy: uid,
      status: 'ready',
      payloadHash,
      title: validation.title,
      subtitle: validation.subtitle,
      description: validation.description,
      citedProductIds: validation.citedProductIds,
      errorReason: null,
      provider: adapter.providerName,
      model: adapter.model,
      generatedAt,
      expiresAt,
      lastAttemptAt: generatedAt,
    });

    logger.info('assistCampaignCreation succeeded', {
      correlationId,
      organizationId,
      provider: adapter.providerName,
    });

    return {
      title: validation.title,
      subtitle: validation.subtitle,
      description: validation.description,
      citedProductIds: validation.citedProductIds,
      generatedAt: generatedAt.toDate().toISOString(),
      expiresAt: expiresAt.toDate().toISOString(),
      fromCache: false,
      correlationId,
    };
  },
);

function parseProductIds(raw: unknown): string[] {
  if (!Array.isArray(raw)) return [];
  const ids = raw.filter((item): item is string => typeof item === 'string' && item.trim().length > 0);
  return [...new Set(ids)].slice(0, CAMPAIGN_ASSIST_MAX_PRODUCTS);
}

function parseOptionalDate(raw: unknown, field: string): Date | null {
  if (raw == null) return null;
  if (typeof raw !== 'string' || raw.trim().length === 0) return null;
  const parsed = new Date(raw);
  if (Number.isNaN(parsed.getTime())) {
    throw new HttpsError('invalid-argument', `${field} inválido.`);
  }
  return parsed;
}

async function persistErrorCache(
  cacheRef: DocumentReference,
  params: {
    organizationId: string;
    requestedBy: string;
    payloadHash: string;
    errorReason: string;
  },
): Promise<void> {
  const now = Timestamp.now();
  await cacheRef.set({
    organizationId: params.organizationId,
    requestedBy: params.requestedBy,
    status: 'error',
    payloadHash: params.payloadHash,
    title: null,
    subtitle: null,
    description: null,
    citedProductIds: null,
    errorReason: params.errorReason,
    provider: null,
    model: null,
    generatedAt: null,
    expiresAt: null,
    lastAttemptAt: now,
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
