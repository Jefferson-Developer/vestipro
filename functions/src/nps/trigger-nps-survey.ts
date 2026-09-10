import { logger } from 'firebase-functions/v2';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { Timestamp, getFirestore, type DocumentData, type Firestore } from 'firebase-admin/firestore';

import { generateSecureToken } from '../shared/secure-token';
import {
  NPS_SURVEY_BASE_URL,
  NPS_TRIGGER_MILESTONES,
  npsSurveyExpiresAt,
  npsSurveyRequestDocId,
} from './nps-shared';

export interface NpsSurveyTriggerInput {
  organizationId: string;
  companyId: string;
  orderId: string;
  orderNumber: string | null;
  customerId: string;
  sellerId: string;
  milestoneType: string;
}

/**
 * Reads a freshly created `postSaleEvents` document (TASK-201) and resolves
 * whether it should ever trigger an NPS survey — `null` for every milestone
 * outside {@link NPS_TRIGGER_MILESTONES} or for a malformed/incomplete
 * document (defensive: this function only reads what `appendPostSaleEvent`
 * itself always writes).
 */
export function resolveNpsSurveyTrigger(
  data: DocumentData | undefined,
): NpsSurveyTriggerInput | null {
  if (!data) return null;
  if (
    typeof data.type !== 'string' ||
    !NPS_TRIGGER_MILESTONES.has(data.type) ||
    typeof data.organizationId !== 'string' ||
    typeof data.companyId !== 'string' ||
    typeof data.orderId !== 'string' ||
    typeof data.customerId !== 'string' ||
    typeof data.sellerId !== 'string'
  ) {
    return null;
  }
  return {
    organizationId: data.organizationId,
    companyId: data.companyId,
    orderId: data.orderId,
    orderNumber: typeof data.orderNumber === 'string' ? data.orderNumber : null,
    customerId: data.customerId,
    sellerId: data.sellerId,
    milestoneType: data.type,
  };
}

export type NpsSurveyCreationOutcome =
  | { created: true }
  | { created: false; reason: 'duplicate' | 'noOptIn' };

/**
 * Creates an `NpsSurveyRequest` for [input] when — and only when — no
 * pesquisa was ever created before for this exact pedido+marco (`tasks.md`:
 * "evitar disparo duplicado... uma solicitação por marco relevante") and the
 * customer has an active WhatsApp opt-in (TASK-183, `whatsappOptIns`,
 * `tasks.md`: "respeita opt-in/consentimento de comunicação do cliente") —
 * without either, this Function must never send anything and must never
 * create a document (`tasks.md` test requirement: "marco sem opt-in — não
 * envia").
 *
 * Reads-then-writes inside a single transaction so two near-simultaneous
 * pós-venda events for the very same pedido+marco (which should not happen —
 * `postSaleEvents` events are themselves append-only — but is cheap to guard
 * against) can never race into two surveys.
 *
 * The token is generated exactly like `createCatalogShareLink`'s own
 * (TASK-081) — only its SHA-256 hash is ever persisted onto
 * `NpsSurveyRequest.tokenHash`. Since nobody is synchronously waiting for a
 * callable response here (this is a background trigger, not a human action),
 * the *plaintext* link is instead embedded once, into the internal
 * notification (TASK-151) addressed to the pedido's own vendedor — the only
 * person who can ever read that notification (`firestore.rules`:
 * `notifications` are only readable by their own `userId`) — so the
 * vendedor has a real, working way to retrieve and manually forward the link
 * (see this module's own package doc for why the hand-off stops there,
 * mirroring TASK-201's own documented WhatsApp-template gap).
 */
export async function createNpsSurveyIfEligible(
  input: NpsSurveyTriggerInput,
  db: Firestore,
  now: Timestamp = Timestamp.now(),
): Promise<NpsSurveyCreationOutcome> {
  const organizationRef = db.collection('organizations').doc(input.organizationId);
  const surveyId = npsSurveyRequestDocId(input.orderId, input.milestoneType);
  const surveyRef = organizationRef.collection('npsSurveyRequests').doc(surveyId);

  const optInSnapshot = await organizationRef
    .collection('whatsappOptIns')
    .doc(input.customerId)
    .get();
  if (optInSnapshot.data()?.status !== 'accepted') {
    return { created: false, reason: 'noOptIn' };
  }

  const { token, tokenHash } = generateSecureToken();
  const expiresAt = npsSurveyExpiresAt(now);
  const link = `${NPS_SURVEY_BASE_URL}/${token}`;

  return db.runTransaction<NpsSurveyCreationOutcome>(async (transaction) => {
    const existing = await transaction.get(surveyRef);
    if (existing.exists) {
      return { created: false, reason: 'duplicate' };
    }

    transaction.set(surveyRef, {
      organizationId: input.organizationId,
      companyId: input.companyId,
      orderId: input.orderId,
      orderNumber: input.orderNumber,
      customerId: input.customerId,
      sellerId: input.sellerId,
      milestoneType: input.milestoneType,
      tokenHash,
      status: 'pending',
      createdAt: now,
      expiresAt,
      respondedAt: null,
    });

    transaction.set(organizationRef.collection('notifications').doc(), {
      organizationId: input.organizationId,
      userId: input.sellerId,
      category: 'commercial',
      title: 'Pesquisa de satisfação (NPS) disponível',
      body:
        `${input.orderNumber ? `Pedido ${input.orderNumber}` : 'O pedido'}: ` +
        `envie o link abaixo ao cliente para responder a pesquisa de ` +
        `satisfação. Link: ${link}`,
      // Mirrors `OrderHistoryRoute.location`
      // (`lib/core/navigation/app_route_paths.dart`) — same deep-link target
      // `appendPostSaleEvent` (`after_sales/after-sales-shared.ts`) already
      // uses for a pós-venda milestone notification.
      deepLink:
        `/org/${input.organizationId}/companies/${input.companyId}` +
        `/orders/${input.orderId}/history`,
      metadata: {
        companyId: input.companyId,
        orderId: input.orderId,
        orderNumber: input.orderNumber,
        npsSurveyId: surveyId,
        npsSurveyLink: link,
      },
      readAt: null,
      deliverAt: now,
      createdAt: now,
      createdBy: 'system',
    });

    return { created: true };
  });
}

export const triggerNpsSurvey = onDocumentCreated(
  'organizations/{organizationId}/postSaleEvents/{postSaleEventId}',
  async (event) => {
    const input = resolveNpsSurveyTrigger(event.data?.data());
    if (!input) return;

    const startedAt = Date.now();
    try {
      const outcome = await createNpsSurveyIfEligible(input, getFirestore());
      logger.info('triggerNpsSurvey completed', {
        organizationId: input.organizationId,
        orderId: input.orderId,
        milestoneType: input.milestoneType,
        created: outcome.created,
        reason: outcome.created ? undefined : outcome.reason,
        durationMs: Date.now() - startedAt,
      });
    } catch (error) {
      // A failure here must never block the pós-venda event write itself
      // (already committed) — logged and swallowed, same isolation-by-job
      // guarantee `tasks.md`/TASK-133 already requires for every background
      // aggregation/trigger job in this codebase.
      logger.error('triggerNpsSurvey failed', {
        organizationId: input.organizationId,
        orderId: input.orderId,
        milestoneType: input.milestoneType,
        durationMs: Date.now() - startedAt,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  },
);
