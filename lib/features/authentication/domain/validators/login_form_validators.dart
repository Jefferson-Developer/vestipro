/// Pure client-side validation for the login form (TASK-034).
///
/// Runs before [SignInWithEmailAndPasswordUseCase] is ever called, so an
/// obviously malformed e-mail or an empty password never reaches
/// `firebase_auth`. Never decides *authentication* outcomes (wrong
/// password, unknown account, etc.) — that mapping happens server-side and
/// is translated by `firebase_auth_exception_mapper.dart`. Kept in
/// `domain/` and free of Flutter imports: [FormFieldValidator] itself is
/// just a `String? Function(String?)` typedef, so these functions compose
/// directly with `AppTextField.validator` without this package depending on
/// `package:flutter`.
library;

final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Returns a user-facing message when [value] is not a plausible e-mail
/// address, or `null` when it passes this (intentionally loose) client-side
/// check.
String? validateLoginEmail(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return 'Informe seu e-mail.';
  }
  if (!_emailPattern.hasMatch(trimmed)) {
    return 'Informe um e-mail válido.';
  }
  return null;
}

/// Returns a user-facing message when [value] is empty, or `null` when a
/// password was typed. Deliberately does not enforce a minimum length or
/// complexity here — that belongs to account creation (TASK-035), not to
/// every subsequent sign-in.
String? validateLoginPassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Informe sua senha.';
  }
  return null;
}
