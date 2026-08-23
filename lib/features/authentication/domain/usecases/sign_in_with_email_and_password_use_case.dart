import 'package:injectable/injectable.dart';

import '../../../../core/auth/auth.dart';
import '../../../../core/utils/utils.dart';

/// Signs a user in with e-mail and password (TASK-034).
///
/// Thin wrapper around the already-existing [AuthRepository] (TASK-012):
/// [LoginPage]/[LoginBloc] never call `FirebaseAuth`/[AuthRepository]
/// directly, they depend on this use case instead, so the presentation
/// layer stays testable without Firebase and so any future business rule
/// around sign-in (rate limiting, device binding, etc.) has a single place
/// to live.
@injectable
final class SignInWithEmailAndPasswordUseCase {
  const SignInWithEmailAndPasswordUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<AppResult<SessionUser>> call({
    required String email,
    required String password,
  }) {
    return _authRepository.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
}
