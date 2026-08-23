/// Lifecycle status of an [Invite] (TASK-039, `tasks.md` seção 3.1/EPIC-04).
///
/// Transitions are decided exclusively server-side, by the
/// `createInvite`/`resendInvite`/`revokeInvite` Cloud Functions
/// (`functions/src/invites/`) — no client code ever writes an
/// [InviteStatus] to Firestore directly.
enum InviteStatus {
  /// Issued and still within [Invite.expiresAt]; can be resent or revoked.
  pending,

  /// Consumed by TASK-040's `acceptInvite` — terminal, never reused.
  accepted,

  /// Past [Invite.expiresAt] without being accepted; can still be resent
  /// (reactivated as [pending]).
  expired,

  /// Explicitly revoked by an OWNER/ADMIN before it was accepted —
  /// terminal, never reused.
  revoked,
}

extension InviteStatusCode on InviteStatus {
  /// The literal value stored in `Invite.status`/Firestore, matching
  /// `functions/src/invites/invite-shared.ts`'s own string literals exactly.
  String get code {
    return switch (this) {
      InviteStatus.pending => 'pending',
      InviteStatus.accepted => 'accepted',
      InviteStatus.expired => 'expired',
      InviteStatus.revoked => 'revoked',
    };
  }
}

/// Parses the raw Firestore/callable-response value back into an
/// [InviteStatus], or `null` for anything unrecognized — callers decide how
/// to handle an unknown status (never silently default to [InviteStatus.pending]).
InviteStatus? inviteStatusFromCode(String code) {
  for (final status in InviteStatus.values) {
    if (status.code == code) return status;
  }
  return null;
}
