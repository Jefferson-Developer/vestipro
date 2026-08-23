import 'package:firebase_auth/firebase_auth.dart';

import '../../../errors/errors.dart';

/// Maps a [FirebaseAuthException] raised by the `firebase_auth` SDK to the
/// app's own [AppException] hierarchy, so the SDK exception never leaves
/// `lib/core/auth/data/`.
AppException mapFirebaseAuthExceptionToAppException(
  FirebaseAuthException exception,
  StackTrace stackTrace,
) {
  switch (exception.code) {
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
    case 'invalid-email':
      return UnauthorizedException(
        'E-mail ou senha inválidos.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
    case 'user-disabled':
      return UnauthorizedException(
        'Seu acesso foi desativado. Entre em contato com o administrador da sua organização.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
    case 'network-request-failed':
      return NetworkException(
        'Sem conexão com a internet.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
    case 'too-many-requests':
      return ServerException(
        'Muitas tentativas de login. Tente novamente mais tarde.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
    case 'email-already-in-use':
      return ConflictException(
        'Este e-mail já está em uso.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
    case 'weak-password':
      return ValidationException(
        'Senha muito fraca.',
        fieldErrors: const {'password': 'weak-password'},
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
    case 'operation-not-allowed':
      return ForbiddenException(
        'Este método de login não está habilitado.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
    // Raised by `User.getIdToken(true)` (TASK-041's session-refresh check)
    // when the account was disabled/deleted or its refresh token was
    // revoked remotely after the app already had a locally cached session.
    // `SessionService.ensureSessionIsActive` reads `code` back off the
    // mapped `AuthenticationFailure` to tell this apart from a transient
    // connectivity failure.
    case 'user-token-expired':
    case 'invalid-user-token':
      return UnauthorizedException(
        'Sua sessão foi encerrada.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
    default:
      return UnknownException(
        exception.message ?? 'Falha de autenticação desconhecida.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
  }
}
