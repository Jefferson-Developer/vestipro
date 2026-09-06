import { createHash } from 'node:crypto';

import { getAuth, type Auth } from 'firebase-admin/auth';
import {
  FieldValue,
  getFirestore,
  Timestamp,
  type DocumentReference,
  type Firestore,
  type QuerySnapshot,
} from 'firebase-admin/firestore';
import { HttpsError, onCall, type CallableRequest } from 'firebase-functions/v2/https';

import { requireNonEmptyString } from '../invites/invite-shared';

export const ACCOUNT_DELETION_CONFIRMATION = 'EXCLUIR MINHA CONTA';
export const ACCOUNT_DELETION_RECENT_LOGIN_SECONDS = 5 * 60;
export const DELETED_USER_LABEL = 'Vendedor removido';

export interface AccountDeletionRequest {
  organizationId?: unknown;
  confirmation?: unknown;
}

export interface AccountDeletionAuth {
  deleteUser(uid: string): Promise<void>;
  revokeRefreshTokens(uid: string): Promise<void>;
}

function anonymizedSubjectId(userId: string): string {
  return `deleted-${createHash('sha256').update(userId).digest('hex').slice(0, 16)}`;
}

function assertRecentLogin(request: CallableRequest<AccountDeletionRequest>, now: Date): void {
  const authTime = request.auth?.token.auth_time;
  if (typeof authTime !== 'number' || now.getTime() / 1000 - authTime > ACCOUNT_DELETION_RECENT_LOGIN_SECONDS) {
    throw new HttpsError(
      'failed-precondition',
      'Entre novamente na conta antes de confirmar a exclusão.',
    );
  }
}

async function deleteDocuments(snapshot: QuerySnapshot): Promise<number> {
  if (snapshot.empty) return 0;
  await Promise.all(snapshot.docs.map((document) => document.ref.delete()));
  return snapshot.size;
}

async function anonymizeDocuments(
  snapshot: QuerySnapshot,
  fields: Record<string, unknown>,
): Promise<number> {
  if (snapshot.empty) return 0;
  await Promise.all(snapshot.docs.map((document) => document.ref.update(fields)));
  return snapshot.size;
}

async function deleteUserSubcollections(userRef: DocumentReference): Promise<number> {
  let deleted = 0;
  for (const name of ['policyAcceptances', 'consentRecords', 'personalDataExports']) {
    deleted += await deleteDocuments(await userRef.collection(name).get());
  }
  return deleted;
}

export async function executeAccountDeletion(params: {
  db: Firestore;
  auth: AccountDeletionAuth;
  organizationId: string;
  userId: string;
  now?: Date;
}): Promise<{ anonymizedRecords: number; deletedRecords: number }> {
  const { db, auth, organizationId, userId } = params;
  const now = Timestamp.fromDate(params.now ?? new Date());
  const activeMemberships = await db
    .collectionGroup('members')
    .where('userId', '==', userId)
    .where('status', '==', 'active')
    .get();
  const requestedMembership = activeMemberships.docs.find(
    (document) => document.ref.parent.parent?.id === organizationId,
  );
  if (!requestedMembership) {
    throw new HttpsError('permission-denied', 'Vínculo ativo não encontrado.');
  }

  // Account deletion is global. Validate every active OWNER membership
  // before mutating anything so a secondary organization is never orphaned.
  for (const membership of activeMemberships.docs) {
    if (membership.data().roleName !== 'OWNER') continue;
    const organization = membership.ref.parent.parent!;
    const owners = await organization
      .collection('members')
      .where('roleName', '==', 'OWNER')
      .where('status', '==', 'active')
      .get();
    if (owners.docs.filter((document) => document.data().deletedAt == null).length <= 1) {
      throw new HttpsError(
        'failed-precondition',
        'Transfira a titularidade antes de excluir a conta do único OWNER.',
      );
    }
  }

  const subjectId = anonymizedSubjectId(userId);
  let deletedRecords = 0;
  let anonymizedRecords = 0;
  for (const membership of activeMemberships.docs) {
    const organization = membership.ref.parent.parent!;
    const currentOrganizationId = organization.id;
    const [pushDevices, notifications, preferences, orders, opportunities, activities, teamsAsMember, teamsAsManager] =
      await Promise.all([
        organization.collection('pushDevices').where('userId', '==', userId).get(),
        organization.collection('notifications').where('userId', '==', userId).get(),
        organization.collection('communicationPreferences').where('userId', '==', userId).get(),
        organization.collection('orders').where('sellerId', '==', userId).get(),
        organization.collection('opportunities').where('responsibleUserId', '==', userId).get(),
        organization.collection('crmActivities').where('userId', '==', userId).get(),
        organization.collection('teams').where('memberIds', 'array-contains', userId).get(),
        organization.collection('teams').where('managerId', '==', userId).get(),
      ]);

    deletedRecords += await deleteDocuments(notifications);
    deletedRecords += await deleteDocuments(pushDevices);
    deletedRecords += await deleteDocuments(preferences);
    anonymizedRecords += await anonymizeDocuments(orders, {
      sellerId: subjectId, sellerName: DELETED_USER_LABEL, updatedAt: now,
    });
    anonymizedRecords += await anonymizeDocuments(opportunities, {
      responsibleUserId: subjectId, responsibleName: DELETED_USER_LABEL, updatedAt: now,
    });
    anonymizedRecords += await anonymizeDocuments(activities, {
      userId: subjectId, createdBy: subjectId, userName: DELETED_USER_LABEL, updatedAt: now,
    });
    const teamUpdates = new Map<string, Record<string, unknown>>();
    for (const team of teamsAsMember.docs) {
      teamUpdates.set(team.ref.path, {
        memberIds: FieldValue.arrayRemove(userId),
        updatedAt: now,
      });
    }
    for (const team of teamsAsManager.docs) {
      teamUpdates.set(team.ref.path, {
        ...teamUpdates.get(team.ref.path),
        managerId: FieldValue.delete(),
        managerName: DELETED_USER_LABEL,
        updatedAt: now,
      });
    }
    await Promise.all(
      [...teamUpdates.entries()].map(([path, fields]) => db.doc(path).update(fields)),
    );
    anonymizedRecords += teamUpdates.size;
    await membership.ref.update({
      status: 'deleted', roleId: FieldValue.delete(), roleName: FieldValue.delete(),
      teamIds: [], companyIds: [], name: DELETED_USER_LABEL,
      displayName: DELETED_USER_LABEL, email: FieldValue.delete(), phone: FieldValue.delete(),
      deletedAt: now, updatedAt: now,
    });
    anonymizedRecords++;

    await organization.collection('auditLogs').doc().set({
      organizationId: currentOrganizationId,
      actorUserId: subjectId,
      actorName: DELETED_USER_LABEL,
      action: 'privacy.accountDeletionCompleted',
      entityType: 'accountDeletion',
      entityId: subjectId,
      timestamp: now,
      metadata: {
        anonymizedRecords,
        deletedRecords,
        retained: [
          'pedidos e documentos fiscais: obrigação legal/contratual (LGPD art. 7º, II), 5 anos após o fato gerador ou término contratual',
          'trilha de auditoria: exercício regular de direitos (LGPD art. 7º, VI), 5 anos após o evento',
        ],
        cascadeDeletion: false,
      },
    });
  }

  deletedRecords += await deleteUserSubcollections(db.collection('users').doc(userId));

  await db.collection('users').doc(userId).set({
    uid: subjectId,
    status: 'deleted',
    name: DELETED_USER_LABEL,
    displayName: DELETED_USER_LABEL,
    email: FieldValue.delete(),
    phone: FieldValue.delete(),
    photoUrl: FieldValue.delete(),
    deletedAt: now,
  }, { merge: true });
  anonymizedRecords++;

  await auth.revokeRefreshTokens(userId);
  await auth.deleteUser(userId);
  return { anonymizedRecords, deletedRecords };
}

async function handleRequestAccountDeletion(
  request: CallableRequest<AccountDeletionRequest>,
  dependencies: { db: Firestore; auth: AccountDeletionAuth; now: Date },
) {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Autenticação obrigatória.');
  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const confirmation = requireNonEmptyString(request.data?.confirmation, 'confirmation');
  if (confirmation !== ACCOUNT_DELETION_CONFIRMATION) {
    throw new HttpsError('invalid-argument', 'Confirmação de exclusão inválida.');
  }
  assertRecentLogin(request, dependencies.now);
  return executeAccountDeletion({
    db: dependencies.db,
    auth: dependencies.auth,
    organizationId,
    userId: request.auth.uid,
    now: dependencies.now,
  });
}

export const requestAccountDeletionHandler = (
  request: CallableRequest<AccountDeletionRequest>,
  dependencies: { db: Firestore; auth: AccountDeletionAuth; now: Date } = {
    db: getFirestore(),
    auth: getAuth() as Auth,
    now: new Date(),
  },
) => handleRequestAccountDeletion(request, dependencies);

export const requestAccountDeletion = onCall<AccountDeletionRequest>(
  (request) => requestAccountDeletionHandler(request),
);
