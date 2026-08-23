/// Pure client-side validation for `InviteUserPage`'s form (TASK-039).
///
/// Runs before [CreateInviteUseCase] is ever called, so an obviously
/// malformed e-mail or a missing role never reaches the `createInvite`
/// Cloud Function. Never decides the *authorization* outcome (who may
/// invite whom) — that is `assertCanIssueInvite`'s job, entirely
/// server-side. Kept in `domain/` and free of Flutter imports, same
/// rationale as `login_form_validators.dart`.
library;

final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Returns a user-facing message when [value] is not a plausible e-mail
/// address, or `null` when it passes this (intentionally loose) check.
String? validateInviteEmail(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return 'Informe o e-mail do convidado.';
  }
  if (!_emailPattern.hasMatch(trimmed)) {
    return 'Informe um e-mail válido.';
  }
  return null;
}
