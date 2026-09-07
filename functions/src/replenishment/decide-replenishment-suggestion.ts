import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';
import { Timestamp, getFirestore } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import {
  loadActiveMembership,
  requireNonEmptyString,
  resolveActorName,
} from '../invites/invite-shared';
import {
  FROZEN_REPLENISHMENT_STATUSES,
  type ReplenishmentSuggestionStatus,
} from './replenishment-calculation-shared';

export type ReplenishmentDecisionAction = 'accept' | 'adjust' | 'discard';

export interface DecideReplenishmentSuggestionRequest extends RequestWithMeta {
  organizationId?: string;
  suggestionId?: string;
  action?: string;
  adjustedQuantity?: number;
  note?: string;
}

export interface DecideReplenishmentSuggestionResponse {
  organizationId: string;
  suggestionId: string;
  status: ReplenishmentSuggestionStatus;
  finalQuantity: number | null;
  draftOrderId: string | null;
  correlationId: string;
}

/**
 * Same allowlist as `../inventory/recompute-stock-turnover-metrics.ts`
 * (TASK-094): a purchasing/replenishment decision is a gestor-level action,
 * never delegated to `SALES_REP`/`SALES_ASSISTANT`/`FINANCE`/`READ_ONLY`.
 */
const ROLES_ALLOWED_TO_DECIDE: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
  'SALES_MANAGER',
]);

/**
 * Human decision (aceitar/ajustar/descartar) over one `ReplenishmentSuggestion`
 * (TASK-184, EPIC-27) — the *only* way a suggestion's `status` can ever
 * leave `'suggested'`/`'insufficientData'`. `tasks.md`/TASK-184: "Nenhuma
 * sugestão vira pedido real sem ação humana explícita de aceite" — this
 * callable is that explicit act, always requiring an authenticated,
 * re-validated (never client-trusted) OWNER/ADMIN/SALES_MANAGER Membership.
 *
 * `'accept'`/`'adjust'` both also create a `ReplenishmentDraftOrder` — see
 * this function's own inline comment on why that is a brand-new, minimal
 * aggregate rather than a reuse of `Order`/`OrderItem` (EPIC-13).
 */
export const decideReplenishmentSuggestion = onCall<
  DecideReplenishmentSuggestionRequest,
  Promise<DecideReplenishmentSuggestionResponse>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'É necessário estar autenticado para decidir uma sugestão de reposição.',
    );
  }

  const organizationId = requireNonEmptyString(
    request.data?.organizationId,
    'organizationId',
  );
  const suggestionId = requireNonEmptyString(
    request.data?.suggestionId,
    'suggestionId',
  );
  const action = parseAction(request.data?.action);
  const note = normalizeNote(request.data?.note);
  const adjustedQuantity =
    action === 'adjust' ? parseAdjustedQuantity(request.data?.adjustedQuantity) : null;

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, request.auth.uid);
  if (!ROLES_ALLOWED_TO_DECIDE.has(membership.roleName)) {
    throw new HttpsError(
      'permission-denied',
      'Apenas OWNER/ADMIN/SALES_MANAGER podem decidir sugestões de reposição.',
    );
  }

  const actorName = await resolveActorName(db, request.auth.uid, request.auth.token);
  const organizationRef = db.collection('organizations').doc(organizationId);
  const suggestionRef = organizationRef
    .collection('replenishmentSuggestions')
    .doc(suggestionId);

  const result = await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(suggestionRef);
    const data = snapshot.data();
    if (!snapshot.exists || !data || data.organizationId !== organizationId) {
      throw new HttpsError('not-found', 'Sugestão de reposição não encontrada.');
    }

    const currentStatus = data.status as ReplenishmentSuggestionStatus;
    if (FROZEN_REPLENISHMENT_STATUSES.has(currentStatus)) {
      throw new HttpsError(
        'failed-precondition',
        'Esta sugestão já foi decidida e não pode ser alterada.',
      );
    }

    const now = Timestamp.now();
    const newStatus: ReplenishmentSuggestionStatus =
      action === 'accept' ? 'accepted' : action === 'adjust' ? 'adjusted' : 'discarded';
    const finalQuantity =
      action === 'discard'
        ? null
        : action === 'adjust'
          ? adjustedQuantity
          : (data.suggestedQuantity as number);

    const existingAudit = Array.isArray(data.decisionAudit) ? data.decisionAudit : [];
    const auditEntry = {
      action,
      actorId: request.auth!.uid,
      actorName,
      at: now,
      note,
    };

    transaction.update(suggestionRef, {
      status: newStatus,
      finalQuantity,
      decidedBy: request.auth!.uid,
      decidedByName: actorName,
      decidedAt: now,
      decisionAudit: [...existingAudit, auditEntry],
      updatedAt: now,
      updatedBy: request.auth!.uid,
    });

    let draftOrderId: string | null = null;
    if (action === 'accept' || action === 'adjust') {
      // Deliberately a brand-new, minimal aggregate
      // (`organizations/{organizationId}/replenishmentDraftOrders/{id}`) —
      // never a reuse of `Order`/`OrderItem` (EPIC-13, TASK-096). A real
      // customer `Order` requires `customerId`/`deliveryAddress`/
      // `billingAddress`/`priceListId`/`paymentTermId` (see
      // `lib/features/orders/domain/entities/order.dart`), none of which
      // make sense for an internal warehouse/factory replenishment: there
      // is no customer, no delivery address and no price list involved.
      // Forcing this into `Order` would mean either relaxing that entity's
      // required fields for a case that has nothing to do with a sale, or
      // faking placeholder values — both worse than a small, explicit
      // aggregate of its own. See TASK-184's own CONCLUIDA doc, "Decisões
      // técnicas", for the full rationale.
      const draftRef = organizationRef.collection('replenishmentDraftOrders').doc();
      draftOrderId = draftRef.id;
      transaction.set(draftRef, {
        id: draftOrderId,
        organizationId,
        companyId: data.companyId,
        warehouseId: data.warehouseId,
        items: [
          {
            variantId: data.variantId,
            productId: data.productId,
            quantity: finalQuantity,
          },
        ],
        sourceSuggestionIds: [suggestionId],
        originType: 'replenishment',
        status: 'draft',
        createdAt: now,
        createdBy: request.auth!.uid,
        updatedAt: now,
        updatedBy: request.auth!.uid,
        version: 1,
      });
    }

    return { status: newStatus, finalQuantity, draftOrderId };
  });

  logger.info('decideReplenishmentSuggestion completed', {
    correlationId,
    organizationId,
    suggestionId,
    action,
    status: result.status,
    draftOrderId: result.draftOrderId,
  });

  return {
    organizationId,
    suggestionId,
    status: result.status,
    finalQuantity: result.finalQuantity,
    draftOrderId: result.draftOrderId,
    correlationId,
  };
});

function parseAction(value: unknown): ReplenishmentDecisionAction {
  if (value === 'accept' || value === 'adjust' || value === 'discard') {
    return value;
  }
  throw new HttpsError(
    'invalid-argument',
    "action deve ser 'accept', 'adjust' ou 'discard'.",
  );
}

function parseAdjustedQuantity(value: unknown): number {
  if (typeof value !== 'number' || !Number.isInteger(value) || value < 0) {
    throw new HttpsError(
      'invalid-argument',
      'adjustedQuantity deve ser um inteiro maior ou igual a zero quando action é "adjust".',
    );
  }
  return value;
}

function normalizeNote(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  return trimmed.length === 0 ? null : trimmed;
}
