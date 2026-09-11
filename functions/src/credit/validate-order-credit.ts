import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { Timestamp, getFirestore } from 'firebase-admin/firestore';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { loadActiveMembership, requireNonEmptyString } from '../invites/invite-shared';
import {
  describeCreditEvaluation,
  evaluateOrderCredit,
  mapCreditProfile,
  type CreditEvaluationReasonCode,
  type CreditEvaluationStatus,
} from './credit-shared';

/**
 * Roles that ever see raw `CustomerCreditProfile` figures (limite, saldo
 * aberto, saldo vencido, score) — mirrors exactly `Capability.financeView`'s
 * grant list in `lib/core/permissions/role_permission_matrix.dart`
 * (OWNER/ADMIN/FINANCE only; `SALES_MANAGER` holds `report.viewSensitive`
 * but not `finance.view`, so it stays masked here too). Every other role
 * (SALES_REP, SALES_ASSISTANT, CUSTOMER_PORTAL...) only ever gets
 * [ValidateOrderCreditResponse.status]/[message] — TASK-212's own "vendedor
 * entende o motivo operacional sem acessar dado financeiro além do
 * permitido" rule.
 */
const ROLES_WITH_FINANCIAL_VISIBILITY: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
  'FINANCE',
]);

export interface ValidateOrderCreditRequest extends RequestWithMeta {
  organizationId?: string;
  companyId?: string;
  customerId?: string;
  orderTotal?: number;
}

export interface ValidateOrderCreditSensitiveDetail {
  creditLimit: number;
  openBalance: number;
  overdueBalance: number;
  financialScore: number | null;
  dataUpdatedAt: string;
}

export interface ValidateOrderCreditResponse {
  correlationId: string;
  status: CreditEvaluationStatus;
  blocked: boolean;
  approvalRequired: boolean;
  reasonCode: CreditEvaluationReasonCode;
  dataStale: boolean;
  message: string;
  sensitive: ValidateOrderCreditSensitiveDetail | null;
}

/**
 * Read-only preview of TASK-212's credit rule, callable by any active member
 * — a seller building a draft (customer 360º/pedido) or a manager/FINANCE
 * checking a customer's current standing. Never mutates anything and never
 * substitutes for `submitOrder`'s own authoritative, transactional
 * revalidation at submission time (same "client-side preview, server-side
 * truth" precedent `calculatePricing` already sets for descontos) — a stale
 * preview here can never let a genuinely blocked pedido through, since
 * `submitOrder` re-reads the very same `CustomerCreditProfile` fresh inside
 * its own transaction.
 */
export const validateOrderCredit = onCall<
  ValidateOrderCreditRequest,
  Promise<ValidateOrderCreditResponse>
>(async (request) => {
  const startedAt = Date.now();
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Autenticação obrigatória.');
  }
  const uid = request.auth.uid;

  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  requireNonEmptyString(request.data?.companyId, 'companyId');
  const customerId = requireNonEmptyString(request.data?.customerId, 'customerId');
  const orderTotal = normalizeOrderTotal(request.data?.orderTotal);

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);

  const profileSnapshot = await db
    .doc(`organizations/${organizationId}/creditProfiles/${customerId}`)
    .get();
  const profile = profileSnapshot.exists
    ? mapCreditProfile(customerId, profileSnapshot.data())
    : null;

  const now = Timestamp.now();
  const evaluation = evaluateOrderCredit(profile, orderTotal, now);
  const message = describeCreditEvaluation(evaluation);

  const sensitive =
    profile && ROLES_WITH_FINANCIAL_VISIBILITY.has(membership.roleName)
      ? {
          creditLimit: profile.creditLimit,
          openBalance: profile.openBalance,
          overdueBalance: profile.overdueBalance,
          financialScore: profile.financialScore,
          dataUpdatedAt: profile.dataUpdatedAt.toDate().toISOString(),
        }
      : null;

  logger.info('validateOrderCredit resolved', {
    correlationId,
    organizationId,
    customerId,
    uid,
    status: evaluation.status,
    durationMs: Date.now() - startedAt,
  });

  return {
    correlationId,
    status: evaluation.status,
    blocked: evaluation.blocked,
    approvalRequired: evaluation.approvalRequired,
    reasonCode: evaluation.reasonCode,
    dataStale: evaluation.dataStale,
    message,
    sensitive,
  };
});

function normalizeOrderTotal(value: unknown): number {
  if (value === undefined || value === null) return 0;
  if (typeof value !== 'number' || Number.isNaN(value) || value < 0) {
    throw new HttpsError('invalid-argument', 'orderTotal must be a non-negative number.');
  }
  return value;
}
