import { defineSecret, defineString } from 'firebase-functions/params';
import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { Timestamp, getFirestore, type DocumentReference } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { requireNonEmptyString } from '../invites/invite-shared';
import {
  LlmProviderNotConfiguredError,
  resolveLlmProviderAdapter,
} from '../shared/llm-provider-adapter';
import { catalogForRole, REPORT_ROLES } from '../reports/report-catalog';
import {
  parsePeriod,
  runReportAggregation,
  type ReportAggregationMember,
} from '../reports/execute-report-query';
import {
  REPORT_EXPLANATION_CACHE_TTL_MINUTES,
  REPORT_EXPLANATION_MIN_RETRY_AFTER_ERROR_MINUTES,
  buildReportExplanationPayload,
  buildReportExplanationPrompt,
  computeDefinitionFingerprint,
  computePayloadHash,
  minutesToMs,
  reportExplanationCacheKey,
  resolveReportExplanationReferences,
  validateGeneratedReportExplanation,
} from './report-explanation-shared';
import type { ReportExplanationReference } from './report-explanation-types';

/** `REPORT_EXPLANATION_LLM_API_KEY` — never read outside this file; passed
 * only into {@link resolveLlmProviderAdapter}, never logged, never echoed
 * back in any response. Activating a real provider in production requires
 * whoever manages this organization's Cloud Functions secrets to run
 * `firebase functions:secrets:set REPORT_EXPLANATION_LLM_API_KEY` — until
 * then this resolves to an empty value and every call gets the disabled
 * adapter's controlled, recoverable failure. Deliberately its own secret/
 * provider-name pair, independent from every other EPIC-28 feature's own
 * (`WALLET_SUMMARY_LLM_*`, `APPROACH_SUGGESTION_LLM_*`) — an organization may
 * want a different provider (or none) for each generative feature. */
const reportExplanationLlmApiKey = defineSecret('REPORT_EXPLANATION_LLM_API_KEY');

const reportExplanationLlmProvider = defineString('REPORT_EXPLANATION_LLM_PROVIDER', {
  default: 'disabled',
});

const reportExplanationLlmModel = defineString('REPORT_EXPLANATION_LLM_MODEL', {
  default: '',
});

const REPORT_EXPLANATION_NOT_CONFIGURED_MESSAGE =
  'Nenhum provedor de IA generativa está configurado para a explicação de ' +
  'relatórios. Configure REPORT_EXPLANATION_LLM_PROVIDER e o segredo ' +
  'REPORT_EXPLANATION_LLM_API_KEY para ativar este recurso.';

const MAX_OUTPUT_TOKENS = 600;

export interface ExplainReportRequest extends RequestWithMeta {
  organizationId?: string;
  companyId?: string;
  /** When explaining a `SavedReport` (TASK-145), its id — used only to key
   * the cache more stably than a definition fingerprint; ownership/sharing
   * of the saved report is never itself trusted as an authorization
   * shortcut, [dimensions]/[metrics]/[filters]/etc. below are always
   * independently re-validated by `runReportAggregation`. `null`/omitted for
   * an ad-hoc report still being built in the construtor. */
  savedReportId?: string | null;
  dimensions?: unknown;
  metrics?: unknown;
  filters?: unknown;
  groupBy?: unknown;
  sortBy?: unknown;
  comparisonPeriod?: unknown;
}

export interface ExplainReportResponse {
  explanationText: string;
  references: ReportExplanationReference[];
  periodKey: string;
  generatedAt: string;
  expiresAt: string;
  fromCache: boolean;
  correlationId: string;
}

/**
 * Generates (or reuses a cached) natural-language explanation of one
 * already-executed report/dashboard — TASK-189, EPIC-28.
 *
 * Never accepts a `ReportQueryResult` handed back by the client: exactly
 * like `exportReportToCsv` (TASK-146), this callable re-runs
 * {@link runReportAggregation} itself, under the caller's own role/tenant
 * scope, and only ever narrates *that* server-derived result
 * ({@link buildReportExplanationPayload}) — so a caller can never make the
 * LLM describe numbers it never independently computed/validated. The
 * generated text is rejected
 * ({@link validateGeneratedReportExplanation}) unless every numeric claim
 * traces back to that same payload and carries a `[refs: ...]` citation the
 * UI can expand.
 */
export const explainReport = onCall<ExplainReportRequest, Promise<ExplainReportResponse>>(
  { secrets: [reportExplanationLlmApiKey] },
  async (request) => {
    const correlationId = resolveCorrelationId(request.data?._meta);

    if (!request.auth) {
      throw new HttpsError(
        'unauthenticated',
        'É necessário estar autenticado para explicar um relatório.',
      );
    }
    const uid = request.auth.uid;

    const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
    const companyId = requireNonEmptyString(request.data?.companyId, 'companyId');
    const savedReportId =
      typeof request.data?.savedReportId === 'string' && request.data.savedReportId.trim().length > 0
        ? request.data.savedReportId.trim()
        : null;

    const db = getFirestore();
    const memberSnapshot = await db
      .collection('organizations')
      .doc(organizationId)
      .collection('members')
      .doc(uid)
      .get();
    const member = memberSnapshot.data();
    if (!memberSnapshot.exists || member?.status !== 'active' || !REPORT_ROLES.has(member.roleName as string)) {
      throw new HttpsError('permission-denied', 'Seu perfil não pode explicar relatórios.');
    }
    const company = await db
      .collection('organizations')
      .doc(organizationId)
      .collection('companies')
      .doc(companyId)
      .get();
    if (!company.exists) {
      throw new HttpsError('not-found', 'Empresa não encontrada nesta organização.');
    }

    const periodKey = parsePeriod(request.data?.filters);
    const comparisonPeriod = parseComparisonPeriod(request.data?.comparisonPeriod);
    const dimensions = stringArray(request.data?.dimensions);
    const metrics = stringArray(request.data?.metrics);

    const { rows } = await runReportAggregation({
      db,
      organizationId,
      companyId,
      member: member as ReportAggregationMember,
      authUid: uid,
      data: request.data,
    });
    if (rows.length === 0) {
      throw new HttpsError(
        'failed-precondition',
        'Não há dados suficientes neste relatório para gerar uma explicação.',
      );
    }

    const catalog = catalogForRole(member.roleName as string);
    const payload = buildReportExplanationPayload({
      organizationId,
      companyId,
      rows,
      dimensions,
      metrics,
      catalog,
      periodKey,
      comparisonPeriod,
    });
    const payloadHash = computePayloadHash(payload);

    const definitionFingerprint = computeDefinitionFingerprint({
      dimensions,
      metrics,
      filters: request.data?.filters,
      groupBy: stringArray(request.data?.groupBy),
      sortBy: request.data?.sortBy,
      comparisonPeriod,
    });
    const cacheKey = reportExplanationCacheKey({
      requesterUid: uid,
      savedReportId,
      definitionFingerprint,
    });
    const cacheRef = db
      .collection('organizations')
      .doc(organizationId)
      .collection('reportExplanations')
      .doc(cacheKey);
    const cacheSnapshot = await cacheRef.get();
    const cached = cacheSnapshot.data();

    if (cached?.payloadHash === payloadHash) {
      if (cached.status === 'ready') {
        const generatedAtMs = toMillis(cached.generatedAt);
        const isFresh =
          generatedAtMs != null &&
          Date.now() - generatedAtMs < minutesToMs(REPORT_EXPLANATION_CACHE_TTL_MINUTES);
        if (isFresh) {
          return {
            explanationText: cached.explanationText as string,
            references: (cached.references as ReportExplanationReference[]) ?? [],
            periodKey,
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
          Date.now() - lastAttemptMs < minutesToMs(REPORT_EXPLANATION_MIN_RETRY_AFTER_ERROR_MINUTES);
        if (stillThrottled) {
          throw new HttpsError(
            'resource-exhausted',
            'Não foi possível gerar uma explicação há pouco tempo. Aguarde alguns minutos antes de tentar novamente.',
          );
        }
      }
    }

    const adapter = resolveLlmProviderAdapter({
      providerName: reportExplanationLlmProvider.value(),
      apiKey: reportExplanationLlmApiKey.value(),
      model: reportExplanationLlmModel.value(),
      notConfiguredMessage: REPORT_EXPLANATION_NOT_CONFIGURED_MESSAGE,
    });
    const { systemPrompt, userPrompt } = buildReportExplanationPrompt(payload);

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
        requestedBy: uid,
        savedReportId,
        payloadHash,
        errorReason: message,
      });
      logger.error('explainReport provider call failed', {
        correlationId,
        organizationId,
        error: error instanceof Error ? error.message : String(error),
      });
      throw new HttpsError('unavailable', message);
    }

    let validation = validateGeneratedReportExplanation(generatedText, payload);
    if (!validation.ok) {
      // One controlled retry with a stricter reminder — never more than
      // this, so a persistently-hallucinating provider fails fast instead of
      // looping (and costing more) indefinitely.
      logger.warn('explainReport first validation failed, retrying once', {
        correlationId,
        organizationId,
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
      validation = validateGeneratedReportExplanation(generatedText, payload);
    }

    if (!validation.ok) {
      const errorReason =
        'Não foi possível gerar uma explicação confiável com base nos dados deste relatório no momento.';
      await persistErrorCache(cacheRef, {
        organizationId,
        companyId,
        requestedBy: uid,
        savedReportId,
        payloadHash,
        errorReason,
      });
      logger.error('explainReport validation failed after retry', {
        correlationId,
        organizationId,
        reason: validation.reason,
        detail: validation.detail,
      });
      throw new HttpsError('failed-precondition', errorReason);
    }

    const references = resolveReportExplanationReferences(payload, validation.citedDataPointCodes);
    const now = new Date();
    const generatedAt = Timestamp.fromDate(now);
    const expiresAt = Timestamp.fromMillis(
      now.getTime() + minutesToMs(REPORT_EXPLANATION_CACHE_TTL_MINUTES),
    );

    await cacheRef.set({
      organizationId,
      companyId,
      requestedBy: uid,
      savedReportId,
      status: 'ready',
      payloadHash,
      explanationText: generatedText,
      references,
      errorReason: null,
      provider: adapter.providerName,
      model: adapter.model,
      generatedAt,
      expiresAt,
      lastAttemptAt: generatedAt,
    });

    logger.info('explainReport succeeded', {
      correlationId,
      organizationId,
      provider: adapter.providerName,
    });

    return {
      explanationText: generatedText,
      references,
      periodKey,
      generatedAt: generatedAt.toDate().toISOString(),
      expiresAt: expiresAt.toDate().toISOString(),
      fromCache: false,
      correlationId,
    };
  },
);

function parseComparisonPeriod(raw: unknown): 'none' | 'previousPeriod' | 'previousYear' {
  if (raw == null || raw === 'none') return 'none';
  if (raw === 'previousPeriod' || raw === 'previousYear') return raw;
  throw new HttpsError('invalid-argument', 'Comparação de período inválida.');
}

function stringArray(raw: unknown): string[] {
  if (!Array.isArray(raw)) return [];
  return raw.filter((item): item is string => typeof item === 'string');
}

async function persistErrorCache(
  cacheRef: DocumentReference,
  params: {
    organizationId: string;
    companyId: string;
    requestedBy: string;
    savedReportId: string | null;
    payloadHash: string;
    errorReason: string;
  },
): Promise<void> {
  const now = Timestamp.now();
  await cacheRef.set({
    organizationId: params.organizationId,
    companyId: params.companyId,
    requestedBy: params.requestedBy,
    savedReportId: params.savedReportId,
    status: 'error',
    payloadHash: params.payloadHash,
    explanationText: null,
    references: null,
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
