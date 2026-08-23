/// What `validateInvite` (TASK-040, `functions/src/invites/validate-invite.ts`)
/// reports about a token *before* `AcceptInvitePage` ever offers the user any
/// option — mirrors that Function's own `ValidateInviteResponse.outcome`
/// exactly.
///
/// [valid] is the only outcome the acceptance flow may act on; every other
/// value only exists to pick which clear, specific message to show
/// (never a raw technical error) — see `tasks.md`/TASK-040: "convite
/// expirado, já usado ou revogado tratado com mensagem clara".
enum InviteAcceptanceOutcome {
  /// Still pending and within its `expiresAt` — the only outcome that lets
  /// `AcceptInvitePage` proceed to actually accept the invite.
  valid,

  /// No `Invite` document anywhere matches the presented token — an
  /// unknown, mistyped or tampered link.
  notFound,

  /// Past `expiresAt` — resolved server-side independently of a possibly
  /// stale `status` field (`resolveInviteOutcome` in
  /// `functions/src/invites/invite-shared.ts`; no scheduled job flips
  /// `status` to `'expired'` in this codebase today).
  expired,

  /// Already consumed by a previous `acceptInvite` call — terminal.
  accepted,

  /// Explicitly revoked by an OWNER/ADMIN before it was accepted —
  /// terminal.
  revoked,
}

extension InviteAcceptanceOutcomeCode on InviteAcceptanceOutcome {
  /// The literal value in `validateInvite`'s own response, matching
  /// `functions/src/invites/validate-invite.ts`'s `ValidateInviteResponse.outcome`
  /// exactly.
  String get code {
    return switch (this) {
      InviteAcceptanceOutcome.valid => 'valid',
      InviteAcceptanceOutcome.notFound => 'notFound',
      InviteAcceptanceOutcome.expired => 'expired',
      InviteAcceptanceOutcome.accepted => 'accepted',
      InviteAcceptanceOutcome.revoked => 'revoked',
    };
  }
}

/// Parses the raw `validateInvite` response value back into an
/// [InviteAcceptanceOutcome], or `null` for anything unrecognized — callers
/// decide how to handle that instead of this silently defaulting to any
/// particular outcome (same precedent as [InviteStatus]'s own
/// `inviteStatusFromCode`).
InviteAcceptanceOutcome? inviteAcceptanceOutcomeFromCode(String code) {
  for (final outcome in InviteAcceptanceOutcome.values) {
    if (outcome.code == code) return outcome;
  }
  return null;
}
