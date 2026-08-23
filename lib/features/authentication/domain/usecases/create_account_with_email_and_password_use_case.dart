import 'package:injectable/injectable.dart';

import '../../../../core/auth/auth.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/user_profile.dart';
import '../repositories/user_profile_repository.dart';

/// Creates a brand-new account (TASK-035): a Firebase Auth user plus its
/// basic profile document, with no Organization attached yet — attaching
/// one is TASK-037's exclusive responsibility (see `SignUpPage`/`tasks.md`).
///
/// Thin orchestrator over [AuthRepository] and [UserProfileRepository],
/// mirroring [SignInWithEmailAndPasswordUseCase] (TASK-034): `SignUpPage`/
/// `SignUpBloc` never call either repository directly.
@injectable
final class CreateAccountWithEmailAndPasswordUseCase {
  const CreateAccountWithEmailAndPasswordUseCase(
    this._authRepository,
    this._userProfileRepository,
  );

  final AuthRepository _authRepository;
  final UserProfileRepository _userProfileRepository;

  Future<AppResult<SessionUser>> call({
    required String name,
    required String email,
    required String password,
    required String termsVersion,
  }) async {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim();

    final accountResult = await _authRepository.createUserWithEmailAndPassword(
      email: trimmedEmail,
      password: password,
      displayName: trimmedName,
    );

    return switch (accountResult) {
      AppFailure<SessionUser>() => accountResult,
      AppSuccess<SessionUser>(value: final sessionUser) =>
        await _createInitialProfile(
          sessionUser: sessionUser,
          name: trimmedName,
          email: trimmedEmail,
          termsVersion: termsVersion,
        ),
    };
  }

  Future<AppResult<SessionUser>> _createInitialProfile({
    required SessionUser sessionUser,
    required String name,
    required String email,
    required String termsVersion,
  }) async {
    final now = DateTime.now().toUtc();
    final profileResult = await _userProfileRepository.createInitialProfile(
      UserProfile(
        uid: sessionUser.uid,
        name: name,
        email: email,
        createdAt: now,
        termsVersion: termsVersion,
        termsAcceptedAt: now,
      ),
    );

    return switch (profileResult) {
      AppSuccess<void>() => AppSuccess<SessionUser>(sessionUser),
      AppFailure<void>(failure: final failure) => await _rollBackSession(
        failure,
      ),
    };
  }

  /// The Firebase Auth account already exists once [_createInitialProfile]
  /// runs — signing back out avoids leaving a half-onboarded session behind
  /// after a profile-write failure (e.g. a network drop right after account
  /// creation). Retrying sign-up from `SignUpPage` after this would fail
  /// with `email-already-in-use`; resuming a half-created account instead
  /// of starting over is a known gap, tracked as a risk until a dedicated
  /// resume-onboarding flow exists (TASK-037/TASK-041).
  Future<AppResult<SessionUser>> _rollBackSession(Failure failure) async {
    await _authRepository.signOut();
    return AppFailure<SessionUser>(failure);
  }
}
