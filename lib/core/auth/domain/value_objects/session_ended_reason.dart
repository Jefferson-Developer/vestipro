/// Why a session stopped being valid, so a redirect to [LoginRoute] can
/// carry a machine-readable reason instead of a raw error code.
///
/// [message] is the user-facing copy a future login screen can surface
/// (read from the `reason` query parameter [SessionAuthGuard] attaches to
/// the redirect) — this task (TASK-041) only wires the mechanism, not the
/// UI that reads it, since no front-end agent is in scope here.
enum SessionEndedReason {
  /// The user tapped "sign out" themselves — [SessionService.logout].
  userInitiated,

  /// The account was disabled/deleted or its refresh token was revoked
  /// remotely (e.g. an admin deactivating the user, TASK-046) and
  /// [SessionService.ensureSessionIsActive] detected it on the next
  /// authenticated check.
  revoked;

  /// User-facing message for this reason, in Portuguese (VestiPro's only
  /// supported language until TASK-174).
  String get message => switch (this) {
    SessionEndedReason.userInitiated => 'Você saiu da sua conta.',
    SessionEndedReason.revoked => 'Sua sessão foi encerrada.',
  };
}
