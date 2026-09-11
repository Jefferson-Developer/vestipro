import { Timestamp, type DocumentData } from 'firebase-admin/firestore';
import { optionalString } from '../pricing/calculate-pricing';

/**
 * How a `CustomerCreditProfile` (TASK-212, EPIC-32) reacts once a pedido
 * would push the customer past its limit or the customer already carries an
 * overdue balance — configured per customer by whoever holds
 * `finance.manage` (FINANCE/ADMIN/OWNER, `RolePermissionMatrix`).
 *
 * `none`/`alert` never change `submitOrder`'s outcome (informational only,
 * surfaced to the seller as [CreditEvaluationStatus.nearLimit]); `block` and
 * `requireApproval` are the only two policies that can ever change what
 * `submitOrder` persists — mirrors exactly the two-tier shape
 * `PricingEngineOutput.blocked`/`.approvalRequired` already uses for
 * desconto.
 */
export type CreditBlockPolicy = 'none' | 'alert' | 'require_approval' | 'block';

export interface CustomerCreditOverride {
  active: boolean;
  reason: string | null;
  approvedBy: string | null;
  approvedByName: string | null;
  approvedAt: Timestamp | null;
  expiresAt: Timestamp | null;
}

export interface CustomerCreditManualBlock {
  active: boolean;
  reason: string | null;
  by: string | null;
  at: Timestamp | null;
}

export interface CustomerCreditProfile {
  id: string;
  organizationId: string;
  companyId: string;
  creditLimit: number;
  openBalance: number;
  overdueBalance: number;
  blockPolicy: CreditBlockPolicy;
  financialScore: number | null;
  dataSource: string;
  dataUpdatedAt: Timestamp;
  manualBlock: CustomerCreditManualBlock;
  override: CustomerCreditOverride;
  version: number;
}

/** A profile older than this is flagged `dataStale` (TASK-212's own "dado
 * financeiro desatualizado" alert) — advisory only, it never blocks
 * submission by itself: `submitOrder` always revalidates against whatever
 * is currently in Firestore, stale or not (`tasks.md`'s own "submissão
 * sempre revalida ao sincronizar"). */
export const CREDIT_DATA_STALE_AFTER_DAYS = 30;

/** A projected balance at or above this fraction of the limit is flagged
 * `nearLimit` even when it does not yet exceed [CustomerCreditProfile.creditLimit]
 * — gives the seller/manager a heads-up before the hard boundary is hit. */
export const CREDIT_NEAR_LIMIT_RATIO = 0.9;

export type CreditEvaluationStatus =
  | 'released'
  | 'near_limit'
  | 'blocked'
  | 'approval_required';

export type CreditEvaluationReasonCode =
  | 'ok'
  | 'no_profile'
  | 'manual_block'
  | 'overdue'
  | 'limit_exceeded'
  | 'override_active';

export interface CreditEvaluationResult {
  status: CreditEvaluationStatus;
  blocked: boolean;
  approvalRequired: boolean;
  reasonCode: CreditEvaluationReasonCode;
  dataStale: boolean;
  overrideApplied: boolean;
  /** Approver role required to decide a pedido routed to `under_review` by
   * this evaluation alone (only ever set when [approvalRequired]) — always
   * `SALES_MANAGER`, the one non-FINANCE role `decideOrderApproval`
   * (TASK-103) already lets decide a pedido, so a credit-only approval
   * never needs a change to that Function's own allow-list. */
  approverRole: 'SALES_MANAGER' | null;
}

/**
 * Maps a raw `organizations/{organizationId}/creditProfiles/{customerId}`
 * Firestore document into [CustomerCreditProfile] — mirrors the
 * `mapPriceList`/`mapPaymentTerm` precedent (`calculate-pricing.ts`): plain
 * data mapping, never throws on a missing optional field, always defaults to
 * the safest ("no restriction yet") value.
 */
export function mapCreditProfile(id: string, data: DocumentData | undefined): CustomerCreditProfile {
  const manualBlockRaw = (data?.manualBlock ?? {}) as DocumentData;
  const overrideRaw = (data?.override ?? {}) as DocumentData;
  return {
    id,
    organizationId: optionalString(data?.organizationId) ?? '',
    companyId: optionalString(data?.companyId) ?? '',
    creditLimit: asNumber(data?.creditLimit),
    openBalance: asNumber(data?.openBalance),
    overdueBalance: asNumber(data?.overdueBalance),
    blockPolicy: normalizeBlockPolicy(data?.blockPolicy),
    financialScore: typeof data?.financialScore === 'number' ? data.financialScore : null,
    dataSource: optionalString(data?.dataSource) ?? 'manual',
    dataUpdatedAt:
      data?.dataUpdatedAt instanceof Timestamp ? data.dataUpdatedAt : Timestamp.now(),
    manualBlock: {
      active: manualBlockRaw.active === true,
      reason: optionalString(manualBlockRaw.reason) ?? null,
      by: optionalString(manualBlockRaw.by) ?? null,
      at: manualBlockRaw.at instanceof Timestamp ? manualBlockRaw.at : null,
    },
    override: {
      active: overrideRaw.active === true,
      reason: optionalString(overrideRaw.reason) ?? null,
      approvedBy: optionalString(overrideRaw.approvedBy) ?? null,
      approvedByName: optionalString(overrideRaw.approvedByName) ?? null,
      approvedAt: overrideRaw.approvedAt instanceof Timestamp ? overrideRaw.approvedAt : null,
      expiresAt: overrideRaw.expiresAt instanceof Timestamp ? overrideRaw.expiresAt : null,
    },
    version: typeof data?.version === 'number' ? data.version : 1,
  };
}

/**
 * Core, side-effect-free credit rule (TASK-212): decides whether a pedido of
 * [orderTotal] for the customer behind [profile] may go straight to
 * `submitted`, must be `blocked` outright, or must be routed to
 * `under_review` — the exact same three outcomes `submitOrder` already
 * supports for desconto (TASK-103), now driven by inadimplência/limite
 * instead. `profile === null` (customer never got a `CustomerCreditProfile`
 * — most customers today, until FINANCE onboards them) always resolves to
 * `released`: this feature must never retroactively block every pre-existing
 * customer the day it ships.
 *
 * An [CustomerCreditOverride] active and not yet expired always wins over an
 * otherwise-blocking condition (manual block, overdue, over limit) — the one
 * and only bypass, and only ever set by `grantCreditOverride`
 * (finance.manage), never by the seller/customer themselves.
 */
export function evaluateOrderCredit(
  profile: CustomerCreditProfile | null,
  orderTotal: number,
  now: Timestamp,
): CreditEvaluationResult {
  if (!profile) {
    return {
      status: 'released',
      blocked: false,
      approvalRequired: false,
      reasonCode: 'no_profile',
      dataStale: false,
      overrideApplied: false,
      approverRole: null,
    };
  }

  const dataStale = isCreditDataStale(profile, now);
  const overrideActive = isOverrideActive(profile.override, now);

  if (profile.manualBlock.active) {
    if (overrideActive) {
      return released('override_active', dataStale, true);
    }
    return blocked('manual_block', dataStale);
  }

  if (profile.overdueBalance > 0) {
    if (overrideActive) return released('override_active', dataStale, true);
    const outcome = resolveByPolicy(profile.blockPolicy, 'overdue', dataStale);
    if (outcome) return outcome;
  }

  const projectedBalance = profile.openBalance + Math.max(orderTotal, 0);
  if (profile.creditLimit > 0 && projectedBalance > profile.creditLimit) {
    if (overrideActive) return released('override_active', dataStale, true);
    const outcome = resolveByPolicy(profile.blockPolicy, 'limit_exceeded', dataStale);
    if (outcome) return outcome;
  }

  if (
    profile.creditLimit > 0 &&
    projectedBalance > profile.creditLimit * CREDIT_NEAR_LIMIT_RATIO
  ) {
    return {
      status: 'near_limit',
      blocked: false,
      approvalRequired: false,
      reasonCode: 'limit_exceeded',
      dataStale,
      overrideApplied: false,
      approverRole: null,
    };
  }

  return released('ok', dataStale, false);
}

function resolveByPolicy(
  policy: CreditBlockPolicy,
  reasonCode: 'overdue' | 'limit_exceeded',
  dataStale: boolean,
): CreditEvaluationResult | null {
  switch (policy) {
    case 'block':
      return blocked(reasonCode, dataStale);
    case 'require_approval':
      return {
        status: 'approval_required',
        blocked: false,
        approvalRequired: true,
        reasonCode,
        dataStale,
        overrideApplied: false,
        approverRole: 'SALES_MANAGER',
      };
    case 'alert':
      return {
        status: 'near_limit',
        blocked: false,
        approvalRequired: false,
        reasonCode,
        dataStale,
        overrideApplied: false,
        approverRole: null,
      };
    case 'none':
      return null;
  }
}

function released(
  reasonCode: CreditEvaluationReasonCode,
  dataStale: boolean,
  overrideApplied: boolean,
): CreditEvaluationResult {
  return {
    status: 'released',
    blocked: false,
    approvalRequired: false,
    reasonCode,
    dataStale,
    overrideApplied,
    approverRole: null,
  };
}

function blocked(
  reasonCode: CreditEvaluationReasonCode,
  dataStale: boolean,
): CreditEvaluationResult {
  return {
    status: 'blocked',
    blocked: true,
    approvalRequired: false,
    reasonCode,
    dataStale,
    overrideApplied: false,
    approverRole: null,
  };
}

export function isOverrideActive(override: CustomerCreditOverride, now: Timestamp): boolean {
  if (!override.active || !override.expiresAt) return false;
  return override.expiresAt.toMillis() > now.toMillis();
}

export function isCreditDataStale(profile: CustomerCreditProfile, now: Timestamp): boolean {
  const thresholdMs = CREDIT_DATA_STALE_AFTER_DAYS * 24 * 60 * 60 * 1000;
  return now.toMillis() - profile.dataUpdatedAt.toMillis() > thresholdMs;
}

/**
 * Client-safe (never a raw dollar figure — `tasks.md`'s own "vendedor
 * entende o motivo operacional sem acessar dado financeiro além do
 * permitido") message for [result], ready to render as-is in the seller's
 * pendencies panel/alert.
 */
export function describeCreditEvaluation(result: CreditEvaluationResult): string {
  const staleSuffix = result.dataStale
    ? ' O dado financeiro deste cliente está desatualizado.'
    : '';
  switch (result.status) {
    case 'released':
      return result.overrideApplied
        ? `Liberado por exceção comercial aprovada.${staleSuffix}`
        : `Crédito liberado para este pedido.${staleSuffix}`;
    case 'near_limit':
      return `Este cliente está próximo do limite de crédito. Avalie antes de aumentar o pedido.${staleSuffix}`;
    case 'blocked':
      return result.reasonCode === 'manual_block'
        ? `Este cliente está bloqueado por pendência financeira. Contate o financeiro para liberar.${staleSuffix}`
        : result.reasonCode === 'overdue'
          ? `Este cliente possui títulos vencidos que impedem novos pedidos. Regularize com o financeiro.${staleSuffix}`
          : `Este pedido excede o limite de crédito do cliente e não pode ser enviado.${staleSuffix}`;
    case 'approval_required':
      return `Este pedido será enviado para aprovação por pendência financeira do cliente (${
        result.reasonCode === 'overdue' ? 'títulos vencidos' : 'limite de crédito'
      }).${staleSuffix}`;
  }
}

function normalizeBlockPolicy(value: unknown): CreditBlockPolicy {
  return value === 'alert' || value === 'require_approval' || value === 'block'
    ? value
    : 'none';
}

function asNumber(value: unknown): number {
  return typeof value === 'number' && !Number.isNaN(value) ? value : 0;
}
