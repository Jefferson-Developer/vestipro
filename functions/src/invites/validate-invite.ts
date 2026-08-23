import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import {
  findInviteByTokenHash,
  hashInviteToken,
  requireNonEmptyString,
  resolveInviteOutcome,
} from './invite-shared';

export interface ValidateInviteRequest extends RequestWithMeta {
  token?: string;
}

export interface ValidateInviteResponse {
  /**
   * `'valid'` is the only outcome `AcceptInvitePage` (TASK-040, Flutter) may
   * act on to actually accept the invite — every other value only exists to
   * pick which clear, specific message to show
   * (`'notFound'`/`'expired'`/`'accepted'`/`'revoked'`), never a raw
   * technical error.
   */
  outcome: 'valid' | 'notFound' | 'expired' | 'accepted' | 'revoked';
  organizationId: string | null;
  organizationName: string | null;
  email: string | null;
  roleName: string | null;
  correlationId: string;
}

/**
 * Looks up the `Invite` behind [ValidateInviteRequest.token] and reports
 * what `AcceptInvitePage` should show *before* it ever offers the user any
 * option (TASK-040, `tasks.md` seção 3.1/EPIC-04: "valida o token junto a
 * uma Cloud Function antes de exibir qualquer opção ao usuário").
 *
 * Deliberately never `throw`s to distinguish "invite not found" from
 * "invite expired/accepted/revoked" from "invite still valid" — all 5 are
 * expected, everyday outcomes of visiting an invite link, not exceptional
 * server conditions, so they are all just different values of
 * [ValidateInviteResponse.outcome]. `HttpsError` is only used for a
 * genuinely malformed request (`token` missing).
 *
 * Callable without authentication ([request.auth] is never checked): the
 * whole point of this Function is to be safe to call *before* anyone is
 * signed in, so `AcceptInvitePage` can decide whether to show a "create
 * account" or a "confirm" flow next.
 *
 * Never returns `tokenHash`, nor accepts/echoes the token back — same
 * restraint as `serializeInvite` (`invite-shared.ts`).
 */
export const validateInvite = onCall<
  ValidateInviteRequest,
  Promise<ValidateInviteResponse>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);
  const token = requireNonEmptyString(request.data?.token, 'token');
  const tokenHash = hashInviteToken(token);

  const db = getFirestore();
  const lookup = await findInviteByTokenHash(db, tokenHash);

  if (!lookup) {
    logger.info('validateInvite: token not found', { correlationId });
    return {
      outcome: 'notFound',
      organizationId: null,
      organizationName: null,
      email: null,
      roleName: null,
      correlationId,
    };
  }

  const now = Timestamp.now();
  const outcome = resolveInviteOutcome(lookup.data, now);
  const organizationSnapshot = await lookup.organizationRef.get();
  const organizationName =
    (organizationSnapshot.data()?.name as string | undefined) ?? null;

  logger.info('validateInvite succeeded', {
    correlationId,
    organizationId: lookup.organizationRef.id,
    inviteId: lookup.ref.id,
    outcome,
  });

  return {
    outcome,
    organizationId: lookup.organizationRef.id,
    organizationName,
    email: lookup.data.email as string,
    roleName: lookup.data.roleName as string,
    correlationId,
  };
});
