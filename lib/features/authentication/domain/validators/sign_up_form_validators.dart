/// Pure client-side validation for the sign-up form (TASK-035).
///
/// Runs before [CreateAccountWithEmailAndPasswordUseCase] is ever called, so
/// an obviously invalid name/e-mail/password never reaches `firebase_auth`.
/// Never decides *account creation* outcomes (e-mail already in use, etc.)
/// — that mapping happens server-side and is translated by
/// `firebase_auth_exception_mapper.dart`. Kept in `domain/` and free of
/// Flutter imports, same rationale as `login_form_validators.dart`.
library;

final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// A password policy stricter than [validateLoginPassword]'s (TASK-034):
/// account *creation* enforces a minimum length and a mix of letters and
/// digits, so every new account starts above a reasonable strength floor —
/// existing accounts created before this policy (or through any future
/// provider) are never re-validated against it at sign-in time.
final RegExp _passwordHasLetter = RegExp(r'[A-Za-z]');
final RegExp _passwordHasDigit = RegExp(r'\d');
const int _minimumPasswordLength = 8;

/// Returns a user-facing message when [value] is not a plausible full name,
/// or `null` when it passes this (intentionally loose) client-side check.
String? validateSignUpName(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return 'Informe seu nome.';
  }
  if (trimmed.length < 2) {
    return 'Informe um nome válido.';
  }
  return null;
}

/// Returns a user-facing message when [value] is not a plausible e-mail
/// address, or `null` when it passes this (intentionally loose) client-side
/// check.
String? validateSignUpEmail(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return 'Informe seu e-mail.';
  }
  if (!_emailPattern.hasMatch(trimmed)) {
    return 'Informe um e-mail válido.';
  }
  return null;
}

/// Returns a user-facing message when [value] does not meet the minimum
/// password policy for account creation ([_minimumPasswordLength] characters
/// with at least one letter and one digit), or `null` when it passes.
String? validateSignUpPassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) {
    return 'Informe uma senha.';
  }
  if (password.length < _minimumPasswordLength ||
      !_passwordHasLetter.hasMatch(password) ||
      !_passwordHasDigit.hasMatch(password)) {
    return 'A senha deve ter pelo menos $_minimumPasswordLength caracteres, '
        'com letras e números.';
  }
  return null;
}

/// Returns a user-facing message when [confirmation] does not match
/// [password], or `null` when they are equal. Only meaningful once
/// [validateSignUpPassword] itself has already passed for [password].
String? validateSignUpPasswordConfirmation(
  String? password,
  String? confirmation,
) {
  if (confirmation == null || confirmation.isEmpty) {
    return 'Confirme sua senha.';
  }
  if (confirmation != password) {
    return 'As senhas não coincidem.';
  }
  return null;
}
