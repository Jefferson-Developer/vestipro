import 'package:injectable/injectable.dart';

import '../../../errors/errors.dart';
import '../../../utils/utils.dart';
import '../../domain/entities/session_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/services/session_service.dart';
import '../datasources/secure_session_store.dart';

/// Firebase codes that mean the session itself is no longer valid — as
/// opposed to a transient connectivity/unexpected failure, which must
/// never end an otherwise-valid session (see [SessionServiceImpl.ensureSessionIsActive]).
const _revokedSessionFailureCodes = <String>{
  'user-disabled',
  'user-token-expired',
  'invalid-user-token',
  'user-not-found',
};

@LazySingleton(as: SessionService)
final class SessionServiceImpl implements SessionService {
  const SessionServiceImpl({
    required this.authRepository,
    required this.secureSessionStore,
  });

  final AuthRepository authRepository;
  final SecureSessionStore secureSessionStore;

  @override
  Stream<SessionUser?> get sessionChanges => authRepository.authStateChanges;

  @override
  SessionUser? get currentUser => authRepository.currentUser;

  @override
  Future<AppResult<void>> logout() async {
    final result = await authRepository.signOut();
    // Cleared unconditionally: a partially-failed remote sign-out (e.g. the
    // request timed out after Firebase already dropped the session) must
    // never leave a previous user's data behind on this device.
    await secureSessionStore.clear();
    return result;
  }

  @override
  Future<AppResult<void>> ensureSessionIsActive() async {
    final user = authRepository.currentUser;
    if (user == null) {
      return const AppSuccess<void>(null);
    }

    final refreshResult = await authRepository.refreshSession();
    if (refreshResult is AppSuccess<void>) {
      // Only touches `SecureSessionStore` for a user that is confirmed
      // signed in right now — never eagerly from a background listener —
      // so this call never runs for an app that has no active session
      // (e.g. it never fires for a fresh install with nobody signed in).
      await secureSessionStore.persistSignedInUserId(user.uid);
      return const AppSuccess<void>(null);
    }

    final failure = (refreshResult as AppFailure<void>).failure;
    if (!_isSessionRevoked(failure)) {
      // Connectivity/unexpected failures never end an otherwise valid
      // session: the refresh simply could not be confirmed (e.g. the
      // device is offline), so the last known session stays active.
      return const AppSuccess<void>(null);
    }

    await authRepository.signOut();
    await secureSessionStore.clear();
    return AppFailure<void>(failure);
  }

  bool _isSessionRevoked(Failure failure) {
    return failure is AuthenticationFailure &&
        _revokedSessionFailureCodes.contains(failure.code);
  }
}
