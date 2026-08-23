import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';
import {
  getFirestore,
  Timestamp,
  type DocumentData,
  type DocumentReference,
} from 'firebase-admin/firestore';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';

/**
 * The 7 built-in roles every Organization is seeded with, mirroring
 * `lib/features/organizations/domain/value_objects/system_role_name.dart`
 * (TASK-028). Kept in perfect sync manually — same trade-off already
 * accepted for `firestore.rules`' `roleHasCapability` (TASK-030).
 */
const SYSTEM_ROLE_NAMES = [
  'OWNER',
  'ADMIN',
  'SALES_MANAGER',
  'SALES_REP',
  'SALES_ASSISTANT',
  'FINANCE',
  'READ_ONLY',
] as const;

export interface CreateOrganizationRequest extends RequestWithMeta {
  /**
   * Generated once by the caller (Flutter's `CreateOrganizationUseCase`,
   * TASK-037) and kept stable across retries. Only used as the id for a
   * brand-new Organization: once this uid already owns one (tracked by
   * `organizationOwners/{uid}`, checked before anything else below), the
   * existing Organization is returned unchanged and this field is ignored,
   * so a retry that generated a *different* id after losing local state
   * still cannot create a second Organization for the same owner.
   */
  organizationId?: string;
  name?: string;
  slug?: string;
  currency?: string;
  country?: string;
  defaultLanguage?: string;
}

interface OrganizationSettingsResponse {
  currency: string;
  country: string;
  defaultLanguage: string;
}

interface OrganizationResponse {
  id: string;
  name: string;
  slug: string;
  settings: OrganizationSettingsResponse;
  status: 'active';
  createdAt: string;
  createdBy: string;
  updatedAt: string;
  updatedBy: string;
}

export interface CreateOrganizationResponse {
  organization: OrganizationResponse;
  alreadyExisted: boolean;
  correlationId: string;
}

function requireNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new HttpsError('invalid-argument', `${field} is required.`);
  }
  return value.trim();
}

function serializeOrganization(
  id: string,
  data: DocumentData,
): OrganizationResponse {
  const createdAt = data.createdAt as Timestamp;
  const updatedAt = data.updatedAt as Timestamp;
  return {
    id,
    name: data.name as string,
    slug: data.slug as string,
    settings: data.settings as OrganizationSettingsResponse,
    status: data.status as 'active',
    createdAt: createdAt.toDate().toISOString(),
    createdBy: data.createdBy as string,
    updatedAt: updatedAt.toDate().toISOString(),
    updatedBy: data.updatedBy as string,
  };
}

interface TransactionResult {
  alreadyExisted: boolean;
  organizationId: string;
  organizationData: DocumentData;
}

/**
 * Creates the first Organization for the authenticated caller, granting
 * them the `OWNER` Membership, as a single idempotent Firestore transaction
 * (TASK-037, `tasks.md` seção 3.1/3.3).
 *
 * Replaces the 3 client-side "bootstrap windows" `firestore.rules` used to
 * allow before this task (creating the Organization itself, seeding its 7
 * system roles, and self-granting the OWNER Membership) — those are now
 * removed from the rules entirely: this Function, running with the Admin
 * SDK, is the only writer of `organizations/{organizationId}`,
 * `.../roles/{roleId}` (system roles) and `.../members/{uid}` (the first
 * Membership) from now on.
 *
 * Idempotency does not rely on the client resending the same
 * [CreateOrganizationRequest.organizationId]: the very first thing this
 * transaction reads is `organizationOwners/{uid}` — a marker written in the
 * very same transaction that creates an Organization. If it already exists,
 * the Organization it points to is returned unchanged (no new write at
 * all), regardless of what `organizationId` the retried request carries.
 * This is also how a network-drop-mid-call retry is handled: either the
 * previous attempt's transaction never committed (nothing exists yet, so
 * this attempt creates everything from scratch) or it did commit (the
 * marker exists, so this attempt is a no-op that just re-reads the result).
 *
 * There is no state where an Organization exists without an `OWNER`
 * Membership, nor one where the Membership exists without its 7 system
 * roles: everything is staged in one `runTransaction` call, so either every
 * write commits or none does — a thrown error at any point (including the
 * defensive consistency checks below) rolls back every staged write.
 */
export const createOrganization = onCall<
  CreateOrganizationRequest,
  Promise<CreateOrganizationResponse>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'É necessário estar autenticado para criar uma organização.',
    );
  }
  const uid = request.auth.uid;

  const organizationId = requireNonEmptyString(
    request.data?.organizationId,
    'organizationId',
  );
  const name = requireNonEmptyString(request.data?.name, 'name');
  const slug = requireNonEmptyString(request.data?.slug, 'slug');
  const currency = requireNonEmptyString(request.data?.currency, 'currency');
  const country = requireNonEmptyString(request.data?.country, 'country');
  const defaultLanguage = requireNonEmptyString(
    request.data?.defaultLanguage,
    'defaultLanguage',
  );

  const db = getFirestore();
  const ownerMarkerRef = db.collection('organizationOwners').doc(uid);
  const requestedOrganizationRef = db.collection('organizations').doc(organizationId);

  const result = await db.runTransaction<TransactionResult>(async (transaction) => {
    // ---- reads (Firestore transactions require every read before any
    // write is staged) ------------------------------------------------------
    const ownerMarkerSnapshot = await transaction.get(ownerMarkerRef);

    if (ownerMarkerSnapshot.exists) {
      const existingOrganizationId = ownerMarkerSnapshot.data()?.organizationId as
        | string
        | undefined;
      if (!existingOrganizationId) {
        throw new HttpsError(
          'internal',
          'Corrupted organization owner marker: missing organizationId.',
        );
      }

      const existingOrganizationSnapshot = await transaction.get(
        db.collection('organizations').doc(existingOrganizationId),
      );
      if (!existingOrganizationSnapshot.exists) {
        // Should be impossible: the marker is only ever written in the same
        // transaction that creates the Organization it points to. Failing
        // loudly here is safer than silently creating a second Organization
        // for an owner who is supposed to have exactly one.
        throw new HttpsError(
          'internal',
          'Organization owner marker points to a missing organization.',
        );
      }

      return {
        alreadyExisted: true,
        organizationId: existingOrganizationId,
        organizationData: existingOrganizationSnapshot.data() as DocumentData,
      };
    }

    const requestedOrganizationSnapshot = await transaction.get(requestedOrganizationRef);
    if (requestedOrganizationSnapshot.exists) {
      // This uid has no owner marker yet, but `organizationId` is already
      // taken by someone else's document — a genuine id collision, not a
      // retry. Reject instead of overwriting another tenant.
      throw new HttpsError('already-exists', 'organizationId already in use.');
    }

    const roleRefs = SYSTEM_ROLE_NAMES.map((roleName) =>
      requestedOrganizationRef.collection('roles').doc(roleName),
    );
    const roleSnapshots = await Promise.all(
      roleRefs.map((roleRef) => transaction.get(roleRef)),
    );
    const preExistingRole = roleSnapshots.find((snapshot) => snapshot.exists);
    if (preExistingRole) {
      // Defensive consistency guard, not an expected real-world path: a
      // brand-new Organization (just confirmed above) should never already
      // have a role subdocument. Throwing here — before any write is
      // staged — rolls back the transaction with nothing persisted, which
      // is exactly what this task's "simulated failure mid-transaction"
      // test exercises.
      throw new HttpsError(
        'internal',
        `Unexpected pre-existing role document for a brand-new organization: ${preExistingRole.id}.`,
      );
    }

    const profileSnapshot = await transaction.get(db.collection('users').doc(uid));

    // ---- writes -------------------------------------------------------
    const now = Timestamp.now();
    const organizationData: DocumentData = {
      name,
      slug,
      settings: { currency, country, defaultLanguage },
      status: 'active',
      createdAt: now,
      createdBy: uid,
      updatedAt: now,
      updatedBy: uid,
      deletedAt: null,
    };
    transaction.set(requestedOrganizationRef, organizationData);

    roleRefs.forEach((roleRef: DocumentReference) => {
      transaction.set(roleRef, {
        organizationId,
        name: roleRef.id,
        isSystemRole: true,
        version: 1,
        createdAt: now,
        createdBy: uid,
        updatedAt: now,
        updatedBy: uid,
        deletedAt: null,
      });
    });

    const membershipRef = requestedOrganizationRef.collection('members').doc(uid);
    transaction.set(membershipRef, {
      organizationId,
      userId: uid,
      roleId: 'OWNER',
      roleName: 'OWNER',
      teamIds: [],
      status: 'active',
      version: 1,
      createdAt: now,
      createdBy: uid,
      updatedAt: now,
      updatedBy: uid,
      deletedAt: null,
    });

    transaction.set(ownerMarkerRef, {
      organizationId,
      createdAt: now,
    });

    const profileName = profileSnapshot.exists
      ? (profileSnapshot.data()?.name as string | undefined)?.trim()
      : undefined;
    const actorName =
      profileName ||
      (request.auth?.token?.name as string | undefined) ||
      (request.auth?.token?.email as string | undefined) ||
      'unknown';

    const auditLogRef = requestedOrganizationRef.collection('auditLogs').doc();
    transaction.set(auditLogRef, {
      organizationId,
      actorUserId: uid,
      actorName,
      action: 'organization.created',
      entityType: 'organization',
      entityId: organizationId,
      previousValue: null,
      newValue: { name, slug },
      timestamp: now,
    });

    return {
      alreadyExisted: false,
      organizationId,
      organizationData,
    };
  });

  logger.info('createOrganization succeeded', {
    correlationId,
    uid,
    organizationId: result.organizationId,
    alreadyExisted: result.alreadyExisted,
  });

  return {
    organization: serializeOrganization(result.organizationId, result.organizationData),
    alreadyExisted: result.alreadyExisted,
    correlationId,
  };
});
