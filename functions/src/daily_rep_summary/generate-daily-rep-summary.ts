import { defineSecret, defineString } from 'firebase-functions/params';
import { logger } from 'firebase-functions/v2';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import {
  Timestamp,
  getFirestore,
  type DocumentData,
  type DocumentReference,
  type Firestore,
} from 'firebase-admin/firestore';

import { formatDayKey } from '../aggregations/aggregation-shared';
import { createFirestoreAggregationDataSource } from '../aggregations/aggregation-data-source';
import {
  LlmProviderNotConfiguredError,
  resolveLlmProviderAdapter,
} from '../shared/llm-provider-adapter';
import {
  computePayloadHash,
  buildDailyRepSummaryPayload,
  buildDailyRepSummaryPrompt,
  dailyRepSummaryRef,
  isDailyRepSummaryPayloadEmpty,
  resolveDailyRepSummaryReferences,
  validateGeneratedDailyRepSummary,
} from './daily-rep-summary-shared';
import {
  parseDailyRepSummaryPreferences,
  resolveDailyRepSummaryDeliveryTime,
} from './daily-rep-summary-notification';
import type { DailyRepSummaryPayload } from './daily-rep-summary-types';

/** `DAILY_REP_SUMMARY_LLM_API_KEY` — same "own secret/provider-name pair per
 * generative feature" convention as `WALLET_SUMMARY_LLM_API_KEY`/
 * `APPROACH_SUGGESTION_LLM_API_KEY`. Never read outside this file. Activating
 * a real provider in production requires whoever manages this organization's
 * Cloud Functions secrets to run
 * `firebase functions:secrets:set DAILY_REP_SUMMARY_LLM_API_KEY` — until then
 * this resolves to an empty value and every call gets the disabled adapter's
 * controlled, recoverable failure. */
const dailyRepSummaryLlmApiKey = defineSecret('DAILY_REP_SUMMARY_LLM_API_KEY');
const dailyRepSummaryLlmProvider = defineString('DAILY_REP_SUMMARY_LLM_PROVIDER', {
  default: 'disabled',
});
const dailyRepSummaryLlmModel = defineString('DAILY_REP_SUMMARY_LLM_MODEL', { default: '' });

const NOT_CONFIGURED_MESSAGE =
  'Nenhum provedor de IA generativa está configurado para o resumo diário do ' +
  'vendedor. Configure DAILY_REP_SUMMARY_LLM_PROVIDER e o segredo ' +
  'DAILY_REP_SUMMARY_LLM_API_KEY para ativar este recurso.';

const MAX_OUTPUT_TOKENS = 400;
const MAX_INSIGHT_DOCS_PER_COMPANY = 500;
const MAX_REJECTED_ORDER_DOCS_PER_COMPANY = 200;

/**
 * Daily, per-organization/company scheduled generation of TASK-188's "resumo
 * diário do vendedor" (EPIC-28) — mirrors `generateInsightsScheduled`'s own
 * `'every day 05:00'`/`America/Sao_Paulo` fixed-schedule convention (every
 * scheduled Cloud Function in this codebase uses one fixed timezone, not a
 * per-organization one — `tasks.md`'s "por organização/fuso horário" wording
 * is aspirational; no per-organization timezone field exists on
 * `Organization` today, so this follows the same established simplification).
 * Runs after `generateInsightsScheduled` (05:00) so the day's insights are
 * already fresh by the time this reads them.
 */
export const generateDailyRepSummary = onSchedule(
  {
    schedule: 'every day 07:00',
    timeZone: 'America/Sao_Paulo',
    region: 'southamerica-east1',
    secrets: [dailyRepSummaryLlmApiKey],
  },
  async () => {
    await generateDailyRepSummaryScheduledHandler();
  },
);

export async function generateDailyRepSummaryScheduledHandler(now = new Date()): Promise<void> {
  const db = getFirestore();
  const dateKey = formatDayKey(now);
  const aggregationDataSource = createFirestoreAggregationDataSource();
  const organizationsSnapshot = await db.collection('organizations').get();

  for (const organization of organizationsSnapshot.docs) {
    const organizationData = organization.data();
    if (organizationData.status !== 'active' || organizationData.deletedAt != null) {
      continue;
    }

    let companyIds: string[];
    try {
      companyIds = await aggregationDataSource.listActiveCompanyIds(organization.id);
    } catch (error) {
      logger.error('generateDailyRepSummary failed to list active companies', {
        organizationId: organization.id,
        error: error instanceof Error ? error.message : String(error),
      });
      continue;
    }

    for (const companyId of companyIds) {
      await processCompany({
        db,
        organizationId: organization.id,
        companyId,
        dateKey,
        now,
        adapterParams: {
          providerName: dailyRepSummaryLlmProvider.value(),
          apiKey: dailyRepSummaryLlmApiKey.value(),
          model: dailyRepSummaryLlmModel.value(),
        },
      });
    }
  }
}

async function processCompany(params: {
  db: Firestore;
  organizationId: string;
  companyId: string;
  dateKey: string;
  now: Date;
  adapterParams: { providerName: string; apiKey: string; model: string };
}): Promise<void> {
  const { db, organizationId, companyId, dateKey, now, adapterParams } = params;
  const organizationRef = db.collection('organizations').doc(organizationId);

  const [insightsSnapshot, rejectedOrdersSnapshot, sellerDailyAggregatesSnapshot] =
    await Promise.all([
      organizationRef
        .collection('insights')
        .where('companyId', '==', companyId)
        .where('status', '==', 'fresh')
        .limit(MAX_INSIGHT_DOCS_PER_COMPANY)
        .get(),
      organizationRef
        .collection('orders')
        .where('companyId', '==', companyId)
        .where('deletedAt', '==', null)
        .where('status', '==', 'rejected')
        .orderBy('createdAt', 'desc')
        .limit(MAX_REJECTED_ORDER_DOCS_PER_COMPANY)
        .get(),
      organizationRef
        .collection('sellerDailyAggregates')
        .where('companyId', '==', companyId)
        .where('periodKey', '==', dateKey)
        .get(),
    ]);

  const companyInsightDocs = insightsSnapshot.docs.map((doc) => ({ id: doc.id, data: doc.data() }));
  const companyRejectedOrderDocs = rejectedOrdersSnapshot.docs.map((doc) => ({
    id: doc.id,
    data: doc.data(),
  }));
  const aggregateBySellerId = new Map<string, DocumentData>(
    sellerDailyAggregatesSnapshot.docs
      .map((doc) => doc.data())
      .filter((data): data is DocumentData => typeof data.scopeId === 'string')
      .map((data) => [data.scopeId as string, data]),
  );

  const sellerIds = new Set<string>();
  for (const doc of companyInsightDocs) {
    if (typeof doc.data.recipientUserId === 'string') sellerIds.add(doc.data.recipientUserId);
    if (doc.data.type === 'sellerBelowTarget' && typeof doc.data.sellerId === 'string') {
      sellerIds.add(doc.data.sellerId);
    }
  }
  for (const doc of companyRejectedOrderDocs) {
    if (typeof doc.data.sellerId === 'string') sellerIds.add(doc.data.sellerId);
  }
  for (const sellerId of aggregateBySellerId.keys()) sellerIds.add(sellerId);

  if (sellerIds.size === 0) return;

  const customerIds = new Set<string>(
    companyRejectedOrderDocs
      .map((doc) => doc.data.customerId)
      .filter((value): value is string => typeof value === 'string'),
  );
  const customerNamesById = await loadCustomerNames(db, organizationRef, customerIds);

  const memberRefs = [...sellerIds].map((sellerId) =>
    organizationRef.collection('members').doc(sellerId),
  );
  const memberSnapshots = memberRefs.length > 0 ? await db.getAll(...memberRefs) : [];

  for (const memberSnapshot of memberSnapshots) {
    const memberData = memberSnapshot.data();
    if (!memberSnapshot.exists || !memberData || memberData.status !== 'active') {
      continue;
    }
    const sellerId = memberSnapshot.id;
    const sellerName = resolveSellerDisplayName(memberData, sellerId);

    const docRef = dailyRepSummaryRef(db, organizationId, sellerId, dateKey);
    const existingSnapshot = await docRef.get();
    // Idempotency (`tasks.md`/TASK-188: "gerado uma vez por vendedor/dia"):
    // any existing entry for this exact (seller, day) — `ready`, `empty` or
    // `error` — means this seller was already processed today; never
    // regenerate, never re-notify.
    if (existingSnapshot.exists) continue;

    const payload = buildDailyRepSummaryPayload({
      organizationId,
      companyId,
      sellerId,
      sellerName,
      dateKey,
      todaysAggregateData: aggregateBySellerId.get(sellerId),
      companyInsightDocs,
      companyRejectedOrderDocs,
      customerNamesById,
    });

    await processSeller({ db, docRef, organizationId, sellerId, payload, now, adapterParams });
  }
}

async function processSeller(params: {
  db: Firestore;
  docRef: DocumentReference;
  organizationId: string;
  sellerId: string;
  payload: DailyRepSummaryPayload;
  now: Date;
  adapterParams: { providerName: string; apiKey: string; model: string };
}): Promise<void> {
  const { db, docRef, organizationId, sellerId, payload, now, adapterParams } = params;
  const payloadHash = computePayloadHash(payload);
  const generatedAt = Timestamp.fromDate(now);

  if (isDailyRepSummaryPayloadEmpty(payload)) {
    await docRef.set({
      organizationId,
      companyId: payload.companyId,
      sellerId,
      dateKey: payload.dateKey,
      status: 'empty',
      payloadHash,
      summaryText: null,
      references: null,
      errorReason: null,
      provider: null,
      model: null,
      generatedAt,
      notificationDispatched: false,
    });
    return;
  }

  const adapter = resolveLlmProviderAdapter({
    providerName: adapterParams.providerName,
    apiKey: adapterParams.apiKey,
    model: adapterParams.model,
    notConfiguredMessage: NOT_CONFIGURED_MESSAGE,
  });
  const { systemPrompt, userPrompt } = buildDailyRepSummaryPrompt(payload);

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
        : 'O provedor de IA generativa está indisponível no momento.';
    await persistErrorCache(docRef, {
      organizationId,
      companyId: payload.companyId,
      sellerId,
      dateKey: payload.dateKey,
      payloadHash,
      errorReason: message,
    });
    logger.error('generateDailyRepSummary provider call failed', {
      organizationId,
      sellerId,
      error: error instanceof Error ? error.message : String(error),
    });
    return;
  }

  let validation = validateGeneratedDailyRepSummary(generatedText, payload);
  if (!validation.ok) {
    logger.warn('generateDailyRepSummary first validation failed, retrying once', {
      organizationId,
      sellerId,
      reason: validation.reason,
    });
    try {
      generatedText = await adapter.generateText({
        systemPrompt:
          systemPrompt +
          '\nATENÇÃO: sua resposta anterior violou uma regra obrigatória ' +
          '(número/fato fora dos dados fornecidos, citação ausente/incorreta ' +
          'ou menção a desconto/preço/condição comercial). Responda ' +
          'novamente seguindo estritamente as regras.',
        userPrompt,
        maxOutputTokens: MAX_OUTPUT_TOKENS,
      });
    } catch {
      generatedText = '';
    }
    validation = validateGeneratedDailyRepSummary(generatedText, payload);
  }

  if (!validation.ok) {
    const errorReason =
      'Não foi possível gerar um resumo diário confiável com base nos dados disponíveis hoje.';
    await persistErrorCache(docRef, {
      organizationId,
      companyId: payload.companyId,
      sellerId,
      dateKey: payload.dateKey,
      payloadHash,
      errorReason,
    });
    logger.error('generateDailyRepSummary validation failed after retry', {
      organizationId,
      sellerId,
      reason: validation.reason,
      detail: validation.detail,
    });
    return;
  }

  const references = resolveDailyRepSummaryReferences(payload, validation.citedDataPointCodes);
  await docRef.set({
    organizationId,
    companyId: payload.companyId,
    sellerId,
    dateKey: payload.dateKey,
    status: 'ready',
    payloadHash,
    summaryText: generatedText,
    references,
    errorReason: null,
    provider: adapter.providerName,
    model: adapter.model,
    generatedAt,
    notificationDispatched: false,
  });

  const notificationDispatched = await tryDispatchNotification({
    db,
    organizationId,
    companyId: payload.companyId,
    sellerId,
    now,
  });
  if (notificationDispatched) {
    await docRef.update({ notificationDispatched: true });
  }

  logger.info('generateDailyRepSummary succeeded', {
    organizationId,
    sellerId,
    provider: adapter.providerName,
    notificationDispatched,
  });
}

async function persistErrorCache(
  docRef: DocumentReference,
  params: {
    organizationId: string;
    companyId: string;
    sellerId: string;
    dateKey: string;
    payloadHash: string;
    errorReason: string;
  },
): Promise<void> {
  await docRef.set({
    organizationId: params.organizationId,
    companyId: params.companyId,
    sellerId: params.sellerId,
    dateKey: params.dateKey,
    status: 'error',
    payloadHash: params.payloadHash,
    summaryText: null,
    references: null,
    errorReason: params.errorReason,
    provider: null,
    model: null,
    generatedAt: Timestamp.now(),
    notificationDispatched: false,
  });
}

/**
 * Writes the `commercial`/`inApp` internal notification
 * (`organizations/{organizationId}/notifications/{id}`, TASK-151) for a
 * freshly-generated `ready` summary — the first Cloud Function in this
 * codebase to write that collection directly (every existing generator runs
 * client-side); the document shape below matches `NotificationDto.toJson()`
 * exactly. Returns `false` (no notification written) when the recipient's
 * own `communicationPreferences` disable `commercial`/`inApp` — quiet hours
 * alone never suppress the notification outright, only its `deliverAt`
 * (`tasks.md`/TASK-188: "Respeitar preferências de comunicação e quiet
 * hours").
 */
async function tryDispatchNotification(params: {
  db: Firestore;
  organizationId: string;
  companyId: string;
  sellerId: string;
  now: Date;
}): Promise<boolean> {
  const { db, organizationId, companyId, sellerId, now } = params;
  const organizationRef = db.collection('organizations').doc(organizationId);

  let preferencesData: DocumentData | undefined;
  try {
    const preferencesSnapshot = await organizationRef
      .collection('communicationPreferences')
      .doc(sellerId)
      .get();
    preferencesData = preferencesSnapshot.data();
  } catch (error) {
    // Fails open — same "an unreadable preference must never silently
    // swallow a notification" precedent `ShouldDispatchNotificationUseCase`
    // already documents.
    logger.warn('generateDailyRepSummary failed to read communication preferences', {
      organizationId,
      sellerId,
      error: error instanceof Error ? error.message : String(error),
    });
  }

  const { allowsCommercialInApp, quietHours } = parseDailyRepSummaryPreferences(preferencesData);
  if (!allowsCommercialInApp) return false;

  const deliverAt = resolveDailyRepSummaryDeliveryTime(quietHours, now);
  const notificationRef = organizationRef.collection('notifications').doc();
  await notificationRef.set({
    organizationId,
    userId: sellerId,
    category: 'commercial',
    title: 'Seu resumo do dia está pronto',
    body: 'Confira seu desempenho, pendências e insights de hoje.',
    // Mirrors `RepresentativeDashboardRoute.location` (`lib/core/navigation/app_route_paths.dart`)
    // — the card lives at the top of that page. Kept as a plain literal
    // (this Cloud Function cannot import Dart route classes); update both
    // if that route's `pathPattern` ever changes.
    deepLink: `/org/${organizationId}/companies/${companyId}/dashboards/representatives/${sellerId}`,
    createdAt: Timestamp.fromDate(now),
    readAt: null,
    priority: 'informative',
    deliverAt: deliverAt == null ? null : Timestamp.fromDate(deliverAt),
    customerId: null,
  });
  return true;
}

async function loadCustomerNames(
  db: Firestore,
  organizationRef: DocumentReference,
  customerIds: ReadonlySet<string>,
): Promise<Map<string, string>> {
  const names = new Map<string, string>();
  if (customerIds.size === 0) return names;
  const refs = [...customerIds].map((customerId) =>
    organizationRef.collection('customers').doc(customerId),
  );
  const snapshots = await db.getAll(...refs);
  for (const snapshot of snapshots) {
    const data = snapshot.data();
    if (!snapshot.exists || !data) continue;
    names.set(snapshot.id, resolveCustomerDisplayName(data, snapshot.id));
  }
  return names;
}

function resolveCustomerDisplayName(data: DocumentData, fallback: string): string {
  const tradeName = typeof data.tradeName === 'string' ? data.tradeName.trim() : '';
  if (tradeName) return tradeName;
  const legalName = typeof data.legalName === 'string' ? data.legalName.trim() : '';
  if (legalName) return legalName;
  const fullName = typeof data.fullName === 'string' ? data.fullName.trim() : '';
  if (fullName) return fullName;
  return fallback;
}

function resolveSellerDisplayName(data: DocumentData, fallback: string): string {
  const name = typeof data.name === 'string' ? data.name.trim() : '';
  return name || fallback;
}
