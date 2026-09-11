import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import {
  loadActiveMembership,
  requireNonEmptyString,
  resolveActorName,
} from '../invites/invite-shared';
import { optionalString } from '../pricing/calculate-pricing';
import { mapCreditProfile } from './credit-shared';

/**
 * Same financially-authorized scope as `updateCreditProfile` (TASK-212) —
 * mirrors `Capability.financeManage` (OWNER/ADMIN/FINANCE). A liberação
 * excepcional de bloqueio financeiro é, por definição, uma decisão
 * financeira, nunca comercial — `SALES_MANAGER` nunca concede/revoga uma,
 * mesmo podendo decidir um nível de aprovação `require_approval`
 * (`decideOrderApproval`, escopo bem mais estreito).
 */
const ROLES_ALLOWED_TO_GRANT_OVERRIDE: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
  'FINANCE',
]);

export interface GrantCreditOverrideRequest extends RequestWithMeta {
  organizationId?: string;
  companyId?: string;
  customerId?: string;
  action?: 'grant' | 'revoke';
  reason?: string;
  /** ISO 8601 instant — required for `action: 'grant'`, ignored for
   * `'revoke'`. Must be strictly in the future (TASK-212's own "override...
   * exige... validade temporal" rule: an exception with no expiry, or one
   * already expired at grant time, is never accepted). */
  expiresAt?: string;
}

export interface GrantCreditOverrideResponse {
  correlationId: string;
  customerId: string;
  active: boolean;
  expiresAt: string | null;
}

/**
 * Grants or revokes a time-limited exception to an otherwise-blocking
 * `CustomerCreditProfile` (TASK-212) — the only bypass `evaluateOrderCredit`/
 * `submitOrder` ever honor for a `manual_block`/`overdue`/limite-excedido
 * condition. Always requires a [GrantCreditOverrideRequest.reason] and a
 * future [GrantCreditOverrideRequest.expiresAt] to grant (never an
 * indefinite exception) and always writes an audit entry either way —
 * TASK-212's "exige motivo, aprovador autorizado e validade temporal" and
 * "toda exceção financeira fica auditável" rules.
 */
export const grantCreditOverride = onCall<
  GrantCreditOverrideRequest,
  Promise<GrantCreditOverrideResponse>
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
  const action = request.data?.action === 'revoke' ? 'revoke' : 'grant';

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  if (!ROLES_ALLOWED_TO_GRANT_OVERRIDE.has(membership.roleName)) {
    throw new HttpsError(
      'permission-denied',
      'Seu perfil não pode conceder ou revogar exceções de crédito.',
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

  if (action === 'grant') {
    const reason = requireNonEmptyString(request.data?.reason, 'reason');
    const expiresAt = requireFutureTimestamp(request.data?.expiresAt, now);

    await db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(profileRef);
      if (!snapshot.exists) {
        throw new HttpsError(
          'failed-precondition',
          'Este cliente ainda não possui um perfil de crédito configurado.',
        );
      }
      const previous = mapCreditProfile(customerId, snapshot.data());

      transaction.update(profileRef, {
        override: {
          active: true,
          reason,
          approvedBy: uid,
          approvedByName: actorName,
          approvedAt: now,
          expiresAt,
        },
        updatedAt: now,
        updatedBy: uid,
        version: FieldValue.increment(1),
      });

      transaction.set(organizationRef.collection('auditLogs').doc(), {
        organizationId,
        actorUserId: uid,
        actorName,
        action: 'creditProfile.overrideGranted',
        entityType: 'creditProfile',
        entityId: customerId,
        previousValue: { overrideActive: previous.override.active },
        newValue: {
          overrideActive: true,
          reason,
          expiresAt: expiresAt.toDate().toISOString(),
        },
        timestamp: now,
      });
    });

    logger.info('grantCreditOverride granted', {
      correlationId,
      organizationId,
      customerId,
      uid,
      durationMs: Date.now() - startedAt,
    });

    return {
      correlationId,
      customerId,
      active: true,
      expiresAt: expiresAt.toDate().toISOString(),
    };
  }

  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(profileRef);
    if (!snapshot.exists) return;
    const previous = mapCreditProfile(customerId, snapshot.data());
    if (!previous.override.active) return;

    transaction.update(profileRef, {
      override: {
        active: false,
        reason: previous.override.reason,
        approvedBy: previous.override.approvedBy,
        approvedByName: previous.override.approvedByName,
        approvedAt: previous.override.approvedAt,
        expiresAt: previous.override.expiresAt,
      },
      updatedAt: now,
      updatedBy: uid,
      version: FieldValue.increment(1),
    });

    transaction.set(organizationRef.collection('auditLogs').doc(), {
      organizationId,
      actorUserId: uid,
      actorName,
      action: 'creditProfile.overrideRevoked',
      entityType: 'creditProfile',
      entityId: customerId,
      previousValue: { overrideActive: true },
      newValue: { overrideActive: false },
      timestamp: now,
    });
  });

  logger.info('grantCreditOverride revoked', {
    correlationId,
    organizationId,
    customerId,
    uid,
    durationMs: Date.now() - startedAt,
  });

  return {
    correlationId,
    customerId,
    active: false,
    expiresAt: null,
  };
});

function requireFutureTimestamp(value: unknown, now: Timestamp): Timestamp {
  const raw = optionalString(value);
  const parsedMs = raw ? Date.parse(raw) : NaN;
  if (!raw || Number.isNaN(parsedMs)) {
    throw new HttpsError('invalid-argument', 'expiresAt must be a valid ISO 8601 date.');
  }
  if (parsedMs <= now.toMillis()) {
    throw new HttpsError(
      'invalid-argument',
      'expiresAt must be in the future.',
    );
  }
  return Timestamp.fromMillis(parsedMs);
}
