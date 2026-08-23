import { createHash, randomBytes } from 'node:crypto';
import { HttpsError } from 'firebase-functions/v2/https';
import {
  Timestamp,
  type DocumentData,
  type DocumentReference,
  type Firestore,
  type Transaction,
} from 'firebase-admin/firestore';

/**
 * The 7 built-in roles and their relative power, mirrored from
 * `functions/src/organizations/create-organization.ts`'s `SYSTEM_ROLE_NAMES`
 * and `lib/core/permissions/role_permission_matrix.dart` (kept in sync
 * manually — same trade-off already accepted for `firestore.rules`'
 * `roleHasCapability`, see that file's own comments). Rank `0` is the most
 * powerful (`OWNER`); higher numbers are strictly less powerful.
 */
export const SYSTEM_ROLE_RANK: Readonly<Record<string, number>> = {
  OWNER: 0,
  ADMIN: 1,
  SALES_MANAGER: 2,
  SALES_REP: 3,
  SALES_ASSISTANT: 4,
  FINANCE: 5,
  READ_ONLY: 6,
};

/**
 * Only these roles are ever granted `Capability.userInvite`
 * (`lib/core/permissions/role_permission_matrix.dart`) — every invite
 * Function re-validates this from the caller's real Membership,
 * independently of anything the client claims.
 */
export const ROLES_ALLOWED_TO_INVITE: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
]);

const DEFAULT_INVITE_EXPIRATION_DAYS = 7;
const MS_PER_DAY = 24 * 60 * 60 * 1000;

const EMAIL_PATTERN = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

export function requireNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new HttpsError('invalid-argument', `${field} is required.`);
  }
  return value.trim();
}

/** Same as {@link requireNonEmptyString}, additionally rejecting anything
 * that does not look like an e-mail address (intentionally loose — mirrors
 * `lib/features/authentication/domain/validators/login_form_validators.dart`'s
 * client-side pattern; the point here is rejecting obvious garbage, not
 * RFC 5322 compliance). Always lower-cased, so the same address never
 * creates two different pending invites just by casing. */
export function requireValidEmail(value: unknown): string {
  const email = requireNonEmptyString(value, 'email').toLowerCase();
  if (!EMAIL_PATTERN.test(email)) {
    throw new HttpsError('invalid-argument', 'email inválido.');
  }
  return email;
}

export interface MembershipRecord {
  roleName: string;
  status: string;
}

/**
 * Reads `organizations/{organizationId}/members/{uid}` with the Admin SDK —
 * never trusts anything the client claims about its own role/membership.
 * Throws `permission-denied` when there is no active Membership, so every
 * invite Function fails the same way for "not a member" and "member but
 * deactivated".
 */
export async function loadActiveMembership(
  db: Firestore,
  organizationId: string,
  uid: string,
): Promise<MembershipRecord> {
  const snapshot = await db
    .collection('organizations')
    .doc(organizationId)
    .collection('members')
    .doc(uid)
    .get();

  const data = snapshot.data();
  if (!snapshot.exists || !data || data.status !== 'active') {
    throw new HttpsError(
      'permission-denied',
      'É necessário ser um membro ativo desta organização.',
    );
  }

  return { roleName: data.roleName as string, status: data.status as string };
}

/**
 * Throws `permission-denied`/`invalid-argument` unless [callerRoleName] is
 * one of {@link ROLES_ALLOWED_TO_INVITE} (OWNER/ADMIN) and [targetRoleName]
 * is a known system role no more powerful than the caller's own — e.g. an
 * ADMIN may invite another ADMIN or anything below, but never an OWNER
 * (`tasks.md`/TASK-039: "ADMIN não pode convidar outro OWNER").
 */
export function assertCanIssueInvite(
  callerRoleName: string,
  targetRoleName: string,
): void {
  if (!ROLES_ALLOWED_TO_INVITE.has(callerRoleName)) {
    throw new HttpsError(
      'permission-denied',
      'Apenas OWNER/ADMIN podem convidar usuários.',
    );
  }

  const targetRank = SYSTEM_ROLE_RANK[targetRoleName];
  if (targetRank === undefined) {
    throw new HttpsError('invalid-argument', 'roleName inválido.');
  }

  const callerRank = SYSTEM_ROLE_RANK[callerRoleName];
  if (targetRank < callerRank) {
    throw new HttpsError(
      'permission-denied',
      'Não é possível convidar alguém para uma função com mais privilégios que a sua.',
    );
  }
}

export interface GeneratedInviteToken {
  token: string;
  tokenHash: string;
}

/**
 * SHA-256 hex digest of a plaintext invite token — the one and only form of
 * a token ever persisted to Firestore (`Invite.tokenHash`). Shared by
 * {@link generateInviteToken} (creating one) and TASK-040's
 * `validateInvite`/`acceptInvite` (looking one up by the hash of whatever
 * the caller presents), so the two ends of the token's lifecycle can never
 * drift into hashing it differently.
 */
export function hashInviteToken(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}

/**
 * Generates a cryptographically secure, non-guessable invite token (256
 * bits of entropy from `crypto.randomBytes`, never `Math.random`/a
 * sequential id) and its SHA-256 hash.
 *
 * Only [GeneratedInviteToken.tokenHash] is ever persisted to Firestore
 * (`Invite.tokenHash`) — the plaintext [GeneratedInviteToken.token] is
 * returned to the caller exactly once, in the callable's own response, so
 * that reading the `invites` collection later (e.g. `InviteListPage`,
 * allowed read-only for OWNER/ADMIN) can never recover a token usable to
 * accept the invite.
 */
export function generateInviteToken(): GeneratedInviteToken {
  const token = randomBytes(32).toString('base64url');
  const tokenHash = hashInviteToken(token);
  return { token, tokenHash };
}

/** One matched `Invite` document, together with a ready-to-use reference to
 * it — returned by {@link findInviteByTokenHash} so callers never have to
 * re-derive `organizationRef`/`inviteRef` from the matched document's own
 * path. */
export interface InviteLookup {
  ref: DocumentReference;
  organizationRef: DocumentReference;
  data: DocumentData;
}

/**
 * Finds the (at most one) `Invite` document anywhere in Firestore whose
 * `tokenHash` equals [tokenHash], via a `collectionGroup('invites')` query —
 * the caller only ever has the plaintext token, not the `organizationId` a
 * direct `organizations/{id}/invites/{id}` lookup would need.
 *
 * `tokenHash` is a SHA-256 digest (`hashInviteToken`), so a match is
 * effectively unique by construction; `limit(1)` is still applied
 * defensively. Returns `null` when nothing matches (unknown/mistyped/
 * tampered token) — the caller decides how to surface that (never treated
 * as an unexpected/internal error, since a stale or garbage token is an
 * entirely ordinary thing for a caller to present).
 */
export async function findInviteByTokenHash(
  db: Firestore,
  tokenHash: string,
  /**
   * When provided, the lookup runs as `transaction.get(query)` instead of a
   * plain `query.get()` — required by `acceptInvite`, which must read the
   * matched `Invite` inside the very same transaction that later updates
   * it, so no concurrent accept of the same token can race past this read
   * (same "read everything inside the transaction" rationale as
   * `createOrganization`).
   */
  transaction?: Transaction,
): Promise<InviteLookup | null> {
  const query = db
    .collectionGroup('invites')
    .where('tokenHash', '==', tokenHash)
    .limit(1);
  const snapshot = transaction ? await transaction.get(query) : await query.get();

  if (snapshot.empty) {
    return null;
  }

  const document = snapshot.docs[0];
  const organizationRef = document.ref.parent.parent;
  if (!organizationRef) {
    // Structurally impossible for a real `organizations/{id}/invites/{id}`
    // document — failing loudly is safer than silently treating a
    // corrupted path as "not found".
    throw new HttpsError(
      'internal',
      'Invite document has no parent organization.',
    );
  }

  return { ref: document.ref, organizationRef, data: document.data() };
}

/**
 * The 4 outcomes {@link resolveInviteOutcome} can settle an already-found
 * `Invite` into. `'notFound'` is deliberately not one of them — that is
 * `findInviteByTokenHash` returning `null`, one level up, before there is
 * any `Invite` document to resolve an outcome from.
 */
export type InviteOutcome = 'valid' | 'expired' | 'accepted' | 'revoked';

/**
 * Resolves what an already-found `Invite` document effectively is *right
 * now*, independently of a stale `status` field: nothing in this codebase
 * ever flips `status` from `'pending'` to `'expired'` on a schedule (no
 * cron/trigger exists for it — see `resend-invite.ts`'s own
 * `RESENDABLE_STATUSES` comment) — expiry is always a lazy, computed
 * property of `expiresAt` vs. [now], never a value trusted verbatim from
 * Firestore. `'accepted'`/`'revoked'` are terminal and always trusted as
 * recorded (nothing un-accepts/un-revokes an invite).
 */
export function resolveInviteOutcome(
  data: DocumentData,
  now: Timestamp,
): InviteOutcome {
  const status = data.status as string;
  if (status === 'accepted') return 'accepted';
  if (status === 'revoked') return 'revoked';
  // A literal `'expired'` is also honored as-is (no code path writes it
  // today, but `resend-invite.ts`'s `RESENDABLE_STATUSES` already models it
  // as a legitimate stored value a future scheduled job could set) — falls
  // through to the lazy `expiresAt` check below only for anything else
  // (`'pending'`).
  if (status === 'expired') return 'expired';

  const expiresAt = data.expiresAt as Timestamp;
  if (expiresAt.toMillis() <= now.toMillis()) return 'expired';

  return 'valid';
}

/**
 * Resolves how many days from [now] a freshly (re)issued invite should
 * expire in: `organizations/{id}.settings.inviteExpirationDays` when the
 * organization configured one (a positive number), otherwise
 * {@link DEFAULT_INVITE_EXPIRATION_DAYS} (7, `tasks.md`/TASK-039's suggested
 * default). There is no dedicated settings UI for this yet (see
 * TASK-039-...-CONCLUIDA.md, "Pendências") — until one exists, an
 * organization can only get a non-default value written directly to
 * Firestore by an administrator/support operation.
 */
export function resolveInviteExpiration(
  organizationData: DocumentData | undefined,
  now: Timestamp,
): Timestamp {
  const configuredDays = organizationData?.settings?.inviteExpirationDays;
  const days =
    typeof configuredDays === 'number' && configuredDays > 0
      ? configuredDays
      : DEFAULT_INVITE_EXPIRATION_DAYS;
  return Timestamp.fromMillis(now.toMillis() + days * MS_PER_DAY);
}

export interface InviteResponse {
  id: string;
  organizationId: string;
  email: string;
  roleName: string;
  status: string;
  invitedByUserId: string;
  invitedByName: string;
  message: string | null;
  expiresAt: string;
  createdAt: string;
  createdBy: string;
  updatedAt: string;
  updatedBy: string;
}

/**
 * Serializes an `Invite` Firestore document into the callable response
 * shape. Deliberately never includes `tokenHash`, nor the plaintext token —
 * the latter is returned once, separately, only by `createInvite`/
 * `resendInvite`'s own response field.
 */
export function serializeInvite(
  id: string,
  data: DocumentData,
): InviteResponse {
  const expiresAt = data.expiresAt as Timestamp;
  const createdAt = data.createdAt as Timestamp;
  const updatedAt = data.updatedAt as Timestamp;
  return {
    id,
    organizationId: data.organizationId as string,
    email: data.email as string,
    roleName: data.roleName as string,
    status: data.status as string,
    invitedByUserId: data.invitedByUserId as string,
    invitedByName: data.invitedByName as string,
    message: (data.message as string | null | undefined) ?? null,
    expiresAt: expiresAt.toDate().toISOString(),
    createdAt: createdAt.toDate().toISOString(),
    createdBy: data.createdBy as string,
    updatedAt: updatedAt.toDate().toISOString(),
    updatedBy: data.updatedBy as string,
  };
}

/**
 * Resolves a human-readable actor name for the audit log entry, same
 * fallback chain already used by `createOrganization`
 * (`functions/src/organizations/create-organization.ts`): the `name` field
 * of the caller's `users/{uid}` profile (TASK-035), then the auth token's
 * `name`, then its `email`, then `'unknown'` — never left blank.
 */
export async function resolveActorName(
  db: Firestore,
  uid: string,
  authToken: Record<string, unknown> | undefined,
): Promise<string> {
  const profileSnapshot = await db.collection('users').doc(uid).get();
  const profileName = profileSnapshot.exists
    ? (profileSnapshot.data()?.name as string | undefined)?.trim()
    : undefined;
  return (
    profileName ||
    (authToken?.name as string | undefined) ||
    (authToken?.email as string | undefined) ||
    'unknown'
  );
}
