import { HttpsError, onCall, type CallableRequest } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';
import { getAuth, type Auth, type UserRecord } from 'firebase-admin/auth';
import {
  FieldValue,
  getFirestore,
  Timestamp,
  type DocumentSnapshot,
  type Firestore,
} from 'firebase-admin/firestore';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import {
  ACCESS_DISABLED_MESSAGE,
  requireNonEmptyString,
  resolveActorName,
  SYSTEM_ROLE_RANK,
} from '../invites/invite-shared';

export interface UpdateUserAccessRequest extends RequestWithMeta {
  organizationId?: string;
  targetUserId?: string;
}

export interface UpdateUserAccessResponse {
  organizationId: string;
  targetUserId: string;
  previousStatus: string;
  status: string;
  updatedAt: string;
  correlationId: string;
}

const ROLES_ALLOWED_TO_CHANGE_USER_ACCESS: ReadonlySet<string> =
  new Set<string>(['OWNER', 'ADMIN']);

const LAST_ACTIVE_OWNER_ACCESS_MESSAGE =
  'Não é possível desativar este usuário porque ele é o último OWNER ativo da organização.';

type TargetStatus = 'active' | 'inactive';
type AccessAction = 'deactivate' | 'reactivate';

interface MembershipRecord {
  roleName: string;
  status: string;
}

function activeMembershipFromSnapshot(
  snapshot: DocumentSnapshot,
): MembershipRecord {
  const data = snapshot.data();
  if (!snapshot.exists || !data || data.status !== 'active') {
    throw new HttpsError(
      'permission-denied',
      'É necessário ser um membro ativo desta organização.',
    );
  }
  return { roleName: data.roleName as string, status: data.status as string };
}

function assertCanChangeUserAccess({
  callerRoleName,
  targetRoleName,
}: {
  callerRoleName: string;
  targetRoleName: string;
}): void {
  if (!ROLES_ALLOWED_TO_CHANGE_USER_ACCESS.has(callerRoleName)) {
    throw new HttpsError(
      'permission-denied',
      'Apenas OWNER/ADMIN podem alterar o acesso de usuários.',
    );
  }

  const callerRank = SYSTEM_ROLE_RANK[callerRoleName];
  const targetRank = SYSTEM_ROLE_RANK[targetRoleName];
  if (callerRank === undefined || targetRank === undefined) {
    throw new HttpsError(
      'permission-denied',
      'Não foi possível validar a hierarquia das funções envolvidas.',
    );
  }

  if (targetRank < callerRank) {
    throw new HttpsError(
      'permission-denied',
      'Não é possível alterar o acesso de um usuário com função mais privilegiada que a sua.',
    );
  }
}

function assertExpectedStatus({
  currentStatus,
  targetStatus,
}: {
  currentStatus: string;
  targetStatus: TargetStatus;
}): void {
  if (currentStatus === targetStatus) {
    throw new HttpsError(
      'failed-precondition',
      targetStatus === 'inactive'
        ? 'Este usuário já está desativado.'
        : 'Este usuário já está ativo.',
    );
  }
}

async function hasAnyActiveMembership(
  db: Firestore,
  targetUserId: string,
): Promise<boolean> {
  const snapshot = await db
    .collectionGroup('members')
    .where('userId', '==', targetUserId)
    .where('status', '==', 'active')
    .limit(1)
    .get();
  return !snapshot.empty;
}

function isAuthUserNotFound(error: unknown): boolean {
  return (
    typeof error === 'object' &&
    error !== null &&
    'code' in error &&
    (error as { code?: unknown }).code === 'auth/user-not-found'
  );
}

async function getUserOrNull(
  auth: Auth,
  targetUserId: string,
): Promise<UserRecord | null> {
  try {
    return await auth.getUser(targetUserId);
  } catch (error) {
    if (isAuthUserNotFound(error)) {
      return null;
    }
    throw error;
  }
}

function withoutVestiProAccessDisabledClaim(
  claims: Record<string, unknown>,
): Record<string, unknown> {
  const remaining = { ...claims };
  delete remaining.vestiproAccessDisabled;
  return remaining;
}

async function applyAuthStateAfterAccessChange({
  db,
  auth,
  targetUserId,
  targetStatus,
}: {
  db: Firestore;
  auth: Auth;
  targetUserId: string;
  targetStatus: TargetStatus;
}): Promise<void> {
  const userRecord = await getUserOrNull(auth, targetUserId);
  if (!userRecord) {
    logger.warn('updateUserAccess skipped Auth state update for missing user', {
      targetUserId,
      targetStatus,
    });
    return;
  }

  const currentClaims = userRecord.customClaims ?? {};
  if (targetStatus === 'inactive') {
    const stillHasActiveMembership = await hasAnyActiveMembership(db, targetUserId);
    if (!stillHasActiveMembership) {
      await auth.setCustomUserClaims(targetUserId, {
        ...currentClaims,
        vestiproAccessDisabled: true,
      });
      await auth.updateUser(targetUserId, { disabled: true });
    }
    await auth.revokeRefreshTokens(targetUserId);
    return;
  }

  if (currentClaims.vestiproAccessDisabled === true) {
    await auth.updateUser(targetUserId, { disabled: false });
    await auth.setCustomUserClaims(
      targetUserId,
      withoutVestiProAccessDisabledClaim(currentClaims),
    );
  }
  await auth.revokeRefreshTokens(targetUserId);
}

async function updateUserAccess(
  request: CallableRequest<UpdateUserAccessRequest>,
  action: AccessAction,
): Promise<UpdateUserAccessResponse> {
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'E necessario estar autenticado para alterar o acesso de usuarios.',
    );
  }
  const uid = request.auth.uid;

  const organizationId = requireNonEmptyString(
    request.data?.organizationId,
    'organizationId',
  );
  const targetUserId = requireNonEmptyString(
    request.data?.targetUserId,
    'targetUserId',
  );
  const targetStatus: TargetStatus =
    action === 'deactivate' ? 'inactive' : 'active';

  const db = getFirestore();
  const organizationRef = db.collection('organizations').doc(organizationId);
  const callerMembershipRef = organizationRef.collection('members').doc(uid);
  const targetMembershipRef = organizationRef.collection('members').doc(targetUserId);
  const actorName = await resolveActorName(db, uid, request.auth.token);

  const result = await db.runTransaction<{
    previousStatus: string;
    status: TargetStatus;
    updatedAt: Timestamp;
  }>(async (transaction) => {
    const [
      organizationSnapshot,
      callerMembershipSnapshot,
      targetMembershipSnapshot,
    ] = await Promise.all([
      transaction.get(organizationRef),
      transaction.get(callerMembershipRef),
      transaction.get(targetMembershipRef),
    ]);

    if (!organizationSnapshot.exists) {
      throw new HttpsError('not-found', 'Organization not found.');
    }

    const callerMembership = activeMembershipFromSnapshot(callerMembershipSnapshot);
    const targetMembershipData = targetMembershipSnapshot.data();
    if (
      !targetMembershipSnapshot.exists ||
      !targetMembershipData ||
      targetMembershipData.deletedAt != null
    ) {
      throw new HttpsError('not-found', 'Usuario da organizacao nao encontrado.');
    }

    const previousStatus = targetMembershipData.status as string;
    const targetRoleName = targetMembershipData.roleName as string;
    assertCanChangeUserAccess({
      callerRoleName: callerMembership.roleName,
      targetRoleName,
    });
    assertExpectedStatus({ currentStatus: previousStatus, targetStatus });

    if (action === 'deactivate' && targetRoleName === 'OWNER') {
      const activeOwnersSnapshot = await transaction.get(
        organizationRef
          .collection('members')
          .where('roleName', '==', 'OWNER')
          .where('status', '==', 'active'),
      );
      const activeOwnerCount = activeOwnersSnapshot.docs.filter(
        (document) => document.data().deletedAt == null,
      ).length;

      if (activeOwnerCount <= 1) {
        throw new HttpsError(
          'failed-precondition',
          LAST_ACTIVE_OWNER_ACCESS_MESSAGE,
        );
      }
    }

    const now = Timestamp.now();
    transaction.update(targetMembershipRef, {
      status: targetStatus,
      version: FieldValue.increment(1),
      updatedAt: now,
      updatedBy: uid,
    });

    transaction.set(organizationRef.collection('auditLogs').doc(), {
      organizationId,
      actorUserId: uid,
      actorName,
      action: action === 'deactivate' ? 'user.deactivated' : 'user.reactivated',
      entityType: 'membership',
      entityId: targetUserId,
      targetUserId,
      previousValue: { status: previousStatus, roleName: targetRoleName },
      newValue: { status: targetStatus, roleName: targetRoleName },
      message:
        action === 'deactivate'
          ? 'Historico preservado; nenhum registro associado foi removido.'
          : null,
      timestamp: now,
    });

    return { previousStatus, status: targetStatus, updatedAt: now };
  });

  await applyAuthStateAfterAccessChange({
    db,
    auth: getAuth(),
    targetUserId,
    targetStatus,
  });

  logger.info('updateUserAccess succeeded', {
    correlationId,
    uid,
    organizationId,
    targetUserId,
    previousStatus: result.previousStatus,
    status: result.status,
  });

  return {
    organizationId,
    targetUserId,
    previousStatus: result.previousStatus,
    status: result.status,
    updatedAt: result.updatedAt.toDate().toISOString(),
    correlationId,
  };
}

export const deactivateUser = onCall<
  UpdateUserAccessRequest,
  Promise<UpdateUserAccessResponse>
>((request) => updateUserAccess(request, 'deactivate'));

export const reactivateUser = onCall<
  UpdateUserAccessRequest,
  Promise<UpdateUserAccessResponse>
>((request) => updateUserAccess(request, 'reactivate'));

export { ACCESS_DISABLED_MESSAGE };
