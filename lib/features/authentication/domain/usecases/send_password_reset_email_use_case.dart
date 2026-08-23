import 'package:injectable/injectable.dart';

import '../../../../core/auth/auth.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';

/// Requests a password reset e-mail (TASK-036).
///
/// Thin wrapper around [AuthRepository.sendPasswordResetEmail], mirroring
/// [SignInWithEmailAndPasswordUseCase]/`CreateAccountWithEmailAndPasswordUseCase`
/// (TASK-034/TASK-035): [ForgotPasswordPage]/`ForgotPasswordBloc` never call
/// [AuthRepository]/`firebase_auth` directly.
///
/// This is also the single place where a `user-not-found` [Failure] is
/// translated into the same generic success the caller sees for an account
/// that *does* exist — never in the bloc, never on the screen — so account
/// enumeration through the "forgot password" flow stays impossible no
/// matter which widget/bloc ends up calling this use case.
@injectable
final class SendPasswordResetEmailUseCase {
  const SendPasswordResetEmailUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<AppResult<void>> call({required String email}) async {
    final result = await _authRepository.sendPasswordResetEmail(
      email: email.trim(),
    );

    return switch (result) {
      AppSuccess<void>() => result,
      AppFailure<void>(failure: final failure) => _mapFailure(failure),
    };
  }

  AppResult<void> _mapFailure(Failure failure) {
    switch (failure.code) {
      case 'user-not-found':
        // Enumeration-of-accounts prevention (TASK-036): the caller must
        // never be able to tell, from the response alone, whether this
        // e-mail is registered.
        return const AppSuccess<void>(null);
      case 'invalid-email':
        // The shared Firebase Auth mapper's message for this code
        // ("E-mail ou senha inválidos.") is written for the sign-in flow —
        // there is no password involved here, so this flow needs its own
        // wording for the same underlying SDK error.
        return AppFailure<void>(
          ValidationFailure(
            'Informe um e-mail válido.',
            fieldErrors: const <String, String>{'email': 'invalid-email'},
            code: failure.code,
            cause: failure.cause,
          ),
        );
      case 'too-many-requests':
        return AppFailure<void>(
          ServerFailure(
            'Muitas tentativas. Tente novamente mais tarde.',
            code: failure.code,
            cause: failure.cause,
          ),
        );
      default:
        return AppFailure<void>(failure);
    }
  }
}
