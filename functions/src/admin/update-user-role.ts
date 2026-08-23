import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';
import {
  FieldValue,
  getFirestore,
  Timestamp,
  type DocumentSnapshot,
} from 'firebase-admin/firestore';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import {
  requireNonEmptyString,
  resolveActorName,
  SYSTEM_ROLE_RANK,
} from '../invites/invite-shared';

export interface UpdateUserRoleRequest extends RequestWithMeta {
  organizationId?: string;
  targetUserId?: string;
  roleName?: string;
}

export interface UpdateUserRoleResponse {
  organizationId: string;
  targetUserId: string;
  previousRoleName: string;
  roleName: string;
  updatedAt: string;
  correlationId: string;
}

const ROLES_ALLOWED_TO_CHANGE_USER_ROLE: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
]);

const LAST_ACTIVE_OWNER_MESSAGE =
  'Não é possível alterar este perfil porque ele é o último OWNER ativo da organização.';

interface ActiveMembershipRecord {
  roleName: string;
  status: string;
}

function activeMembershipFromSnapshot(
  snapshot: DocumentSnapshot,
): ActiveMembershipRecord {
  const data = snapshot.data();
  if (!snapshot.exists || !data || data.status !== 'active') {
    throw new HttpsError(
      'permission-denied',
      'É necessário ser um membro ativo desta organização.',
    );
  }
  return { roleName: data.roleName as string, status: data.status as string };
}

function assertCanUpdateUserRole({
  callerRoleName,
  previousRoleName,
  targetRoleName,
  isSelfUpdate,
}: {
  callerRoleName: string;
  previousRoleName: string;
  targetRoleName: string;
  isSelfUpdate: boolean;
}): void {
  if (!ROLES_ALLOWED_TO_CHANGE_USER_ROLE.has(callerRoleName)) {
    throw new HttpsError(
      'permission-denied',
      'Apenas OWNER/ADMIN podem alterar perfis de usuários.',
    );
  }

  const callerRank = SYSTEM_ROLE_RANK[callerRoleName];
  const previousRank = SYSTEM_ROLE_RANK[previousRoleName];
  const targetRank = SYSTEM_ROLE_RANK[targetRoleName];

  if (targetRank === undefined) {
    throw new HttpsError('invalid-argument', 'roleName inválido.');
  }

  if (callerRank === undefined || previousRank === undefined) {
    throw new HttpsError(
      'permission-denied',
      'Não foi possível validar a hierarquia das funções envolvidas.',
    );
  }

  if (isSelfUpdate && targetRank < previousRank) {
    throw new HttpsError(
      'permission-denied',
      'Não é possível promover a própria função para um nível superior.',
    );
  }

  if (previousRank < callerRank) {
    throw new HttpsError(
      'permission-denied',
      'Não é possível alterar um usuário com função mais privilegiada que a sua.',
    );
  }

  if (targetRank < callerRank) {
    throw new HttpsError(
      'permission-denied',
      'Não é possível atribuir uma função com mais privilégios que a sua.',
    );
  }
}

/**
 * Updates one active organization Membership's system role (TASK-043).
 *
 * This callable is the only writer for role changes initiated from
 * `UserRoleEditPage`: it re-validates the caller's real Membership with the
 * Admin SDK, applies the same OWNER/ADMIN + role-rank matrix used by
 * TASK-029/TASK-039, blocks any demotion that would leave the organization
 * without an active OWNER, and writes the Membership update plus exactly one
 * central audit log entry in the same Firestore transaction.
 */
export const updateUserRole = onCall<
  UpdateUserRoleRequest,
  Promise<UpdateUserRoleResponse>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'É necessário estar autenticado para alterar perfis de usuários.',
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
  const roleName = requireNonEmptyString(request.data?.roleName, 'roleName');

  const db = getFirestore();
  const organizationRef = db.collection('organizations').doc(organizationId);
  const callerMembershipRef = organizationRef.collection('members').doc(uid);
  const targetMembershipRef = organizationRef.collection('members').doc(targetUserId);
  const targetRoleRef = organizationRef.collection('roles').doc(roleName);
  const actorName = await resolveActorName(db, uid, request.auth.token);

  const result = await db.runTransaction<{
    previousRoleName: string;
    roleName: string;
    updatedAt: Timestamp;
  }>(async (transaction) => {
    const [
      organizationSnapshot,
      callerMembershipSnapshot,
      targetMembershipSnapshot,
      targetRoleSnapshot,
    ] = await Promise.all([
      transaction.get(organizationRef),
      transaction.get(callerMembershipRef),
      transaction.get(targetMembershipRef),
      transaction.get(targetRoleRef),
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
      throw new HttpsError('not-found', 'Usuário da organização não encontrado.');
    }

    const roleData = targetRoleSnapshot.data();
    if (!targetRoleSnapshot.exists || !roleData || roleData.isSystemRole !== true) {
      throw new HttpsError('invalid-argument', 'roleName inválido.');
    }

    const previousRoleName = targetMembershipData.roleName as string;
    if (previousRoleName === roleName) {
      throw new HttpsError(
        'failed-precondition',
        'Este usuário já possui esta função.',
      );
    }

    assertCanUpdateUserRole({
      callerRoleName: callerMembership.roleName,
      previousRoleName,
      targetRoleName: roleName,
      isSelfUpdate: uid === targetUserId,
    });

    if (
      targetMembershipData.status === 'active' &&
      previousRoleName === 'OWNER' &&
      roleName !== 'OWNER'
    ) {
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
        throw new HttpsError('failed-precondition', LAST_ACTIVE_OWNER_MESSAGE);
      }
    }

    const now = Timestamp.now();
    transaction.update(targetMembershipRef, {
      roleId: roleName,
      roleName,
      version: FieldValue.increment(1),
      updatedAt: now,
      updatedBy: uid,
    });

    transaction.set(organizationRef.collection('auditLogs').doc(), {
      organizationId,
      actorUserId: uid,
      actorName,
      action: 'user.roleUpdated',
      entityType: 'membership',
      entityId: targetUserId,
      targetUserId,
      previousValue: { roleName: previousRoleName },
      newValue: { roleName },
      timestamp: now,
    });

    return { previousRoleName, roleName, updatedAt: now };
  });

  logger.info('updateUserRole succeeded', {
    correlationId,
    uid,
    organizationId,
    targetUserId,
    previousRoleName: result.previousRoleName,
    roleName: result.roleName,
  });

  return {
    organizationId,
    targetUserId,
    previousRoleName: result.previousRoleName,
    roleName: result.roleName,
    updatedAt: result.updatedAt.toDate().toISOString(),
    correlationId,
  };
});
