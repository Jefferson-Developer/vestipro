import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { FieldValue, Timestamp, getFirestore, type DocumentData } from 'firebase-admin/firestore';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import {
  loadActiveMembership,
  requireNonEmptyString,
  resolveActorName,
} from '../invites/invite-shared';
import { optionalString } from '../pricing/calculate-pricing';
import { mapCreditProfile, type CreditBlockPolicy } from './credit-shared';

/**
 * Only these roles may ever create/edit a `CustomerCreditProfile` or set/
 * clear its manual block (TASK-212) — mirrors exactly `Capability.financeManage`'s
 * grant list in `lib/core/permissions/role_permission_matrix.dart`
 * (OWNER/ADMIN/FINANCE; never SALES_MANAGER/SALES_REP — crédito é decisão
 * financeira, não comercial). Re-checked here from the caller's real
 * Membership, same "nunca confiar apenas em organizationId... como
 * autorização" rule every other Function in this codebase follows.
 */
const ROLES_ALLOWED_TO_MANAGE_CREDIT: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
  'FINANCE',
]);

const VALID_BLOCK_POLICIES: ReadonlySet<string> = new Set<string>([
  'none',
  'alert',
  'require_approval',
  'block',
]);

export interface UpdateCreditProfileRequest extends RequestWithMeta {
  organizationId?: string;
  companyId?: string;
  customerId?: string;
  creditLimit?: number;
  openBalance?: number;
  overdueBalance?: number;
  blockPolicy?: string;
  financialScore?: number | null;
  dataSource?: string;
  manualBlockActive?: boolean;
  manualBlockReason?: string;
}

export interface UpdateCreditProfileResponse {
  correlationId: string;
  customerId: string;
  updatedAt: string;
}

/**
 * Creates (first call for a customer) or edits (every call after)
 * `organizations/{organizationId}/creditProfiles/{customerId}` — the one and
 * only way that document is ever written from outside the Admin SDK, exactly
 * like `firestore.rules`' `creditProfiles` match block requires
 * (`allow create, update, delete: if false`). Every change is audited with
 * both the previous and new value (TASK-212's own "registrar auditoria de
 * toda alteração manual em limite, bloqueio... ou política" rule) — the
 * audit log entry itself may carry real financial figures (it is not
 * Analytics, `AGENTS.md`'s "sem valores financeiros sensíveis" restriction
 * is about Analytics events only), gated by the same `finance.view`
 * capability any other sensitive audit trail already requires.
 */
export const updateCreditProfile = onCall<
  UpdateCreditProfileRequest,
  Promise<UpdateCreditProfileResponse>
>(async (request) => {
  const startedAt = Date.now();
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Autenticação obrigatória.');
  }
  const uid = request.auth.uid;

  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const companyId = requireNonEmptyString(request.data?.companyId, 'companyId');
  const customerId = requireNonEmptyString(request.data?.customerId, 'customerId');
  const creditLimit = requireNonNegativeNumber(request.data?.creditLimit, 'creditLimit');
  const openBalance = requireNonNegativeNumber(request.data?.openBalance, 'openBalance');
  const overdueBalance = requireNonNegativeNumber(
    request.data?.overdueBalance,
    'overdueBalance',
  );
  const blockPolicy = requireBlockPolicy(request.data?.blockPolicy);
  const financialScore =
    request.data?.financialScore === null || request.data?.financialScore === undefined
      ? null
      : requireNonNegativeNumber(request.data.financialScore, 'financialScore');
  const dataSource = optionalString(request.data?.dataSource) ?? 'manual';
  const manualBlockActive = request.data?.manualBlockActive === true;
  const manualBlockReason = optionalString(request.data?.manualBlockReason);
  if (manualBlockActive && !manualBlockReason) {
    throw new HttpsError(
      'invalid-argument',
      'Informe o motivo do bloqueio manual.',
    );
  }

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  if (!ROLES_ALLOWED_TO_MANAGE_CREDIT.has(membership.roleName)) {
    throw new HttpsError(
      'permission-denied',
      'Seu perfil não pode gerenciar crédito de clientes.',
    );
  }

  const actorName = await resolveActorName(db, uid, request.auth.token);
  const organizationRef = db.collection('organizations').doc(organizationId);
  const customerSnapshot = await organizationRef.collection('customers').doc(customerId).get();
  if (!customerSnapshot.exists || customerSnapshot.data()?.companyId !== companyId) {
    throw new HttpsError('failed-precondition', 'Cliente não encontrado nesta empresa.');
  }

  const profileRef = organizationRef.collection('creditProfiles').doc(customerId);
  const now = Timestamp.now();

  const result = await db.runTransaction<UpdateCreditProfileResponse>(async (transaction) => {
    const existingSnapshot = await transaction.get(profileRef);
    const previous = existingSnapshot.exists
      ? mapCreditProfile(customerId, existingSnapshot.data())
      : null;

    const data: DocumentData = {
      organizationId,
      companyId,
      customerId,
      creditLimit,
      openBalance,
      overdueBalance,
      blockPolicy,
      financialScore,
      dataSource,
      dataUpdatedAt: now,
      manualBlock: {
        active: manualBlockActive,
        reason: manualBlockActive ? manualBlockReason : null,
        by: manualBlockActive ? uid : null,
        at: manualBlockActive ? now : null,
      },
      // Uma exceção concedida (`grantCreditOverride`) nunca é apagada por
      // esta chamada — só `grantCreditOverride` (grant/revoke) decide o
      // campo `override`, para que editar o limite não revogue por acidente
      // uma liberação já aprovada.
      override: previous?.override ?? {
        active: false,
        reason: null,
        approvedBy: null,
        approvedByName: null,
        approvedAt: null,
        expiresAt: null,
      },
      updatedAt: now,
      updatedBy: uid,
      version: FieldValue.increment(1),
      createdAt: previous ? undefined : now,
      createdBy: previous ? undefined : uid,
    };
    // The Admin SDK rejects `undefined` inside a `transaction.set` payload
    // unless `ignoreUndefinedProperties` is enabled (it is not) — merge only
    // applies `createdAt`/`createdBy` on first creation.
    if (previous) {
      delete data.createdAt;
      delete data.createdBy;
    }

    transaction.set(profileRef, data, { merge: true });

    transaction.set(organizationRef.collection('auditLogs').doc(), {
      organizationId,
      actorUserId: uid,
      actorName,
      action: 'creditProfile.updated',
      entityType: 'creditProfile',
      entityId: customerId,
      previousValue: previous
        ? {
            creditLimit: previous.creditLimit,
            openBalance: previous.openBalance,
            overdueBalance: previous.overdueBalance,
            blockPolicy: previous.blockPolicy,
            financialScore: previous.financialScore,
            manualBlockActive: previous.manualBlock.active,
          }
        : null,
      newValue: {
        creditLimit,
        openBalance,
        overdueBalance,
        blockPolicy,
        financialScore,
        manualBlockActive,
        manualBlockReason: manualBlockActive ? manualBlockReason : null,
      },
      timestamp: now,
    });

    return {
      correlationId,
      customerId,
      updatedAt: now.toDate().toISOString(),
    };
  });

  logger.info('updateCreditProfile succeeded', {
    correlationId,
    organizationId,
    customerId,
    uid,
    durationMs: Date.now() - startedAt,
  });

  return result;
});

function requireNonNegativeNumber(value: unknown, field: string): number {
  if (typeof value !== 'number' || Number.isNaN(value) || value < 0) {
    throw new HttpsError('invalid-argument', `${field} must be a non-negative number.`);
  }
  return value;
}

function requireBlockPolicy(value: unknown): CreditBlockPolicy {
  if (typeof value !== 'string' || !VALID_BLOCK_POLICIES.has(value)) {
    throw new HttpsError(
      'invalid-argument',
      'blockPolicy must be one of: none, alert, require_approval, block.',
    );
  }
  return value as CreditBlockPolicy;
}
