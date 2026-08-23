import 'package:firebase_core/firebase_core.dart';

import '../errors/errors.dart';

/// Maps a [FirebaseException] raised by the `cloud_functions` SDK (always a
/// [FirebaseFunctionsException] at the real call site — accepting the
/// broader supertype here keeps this mapper testable with a plain
/// [FirebaseException], same trick already used by
/// `mapStorageExceptionToAppException`/`mapFirestoreExceptionToAppException`)
/// to the app's own [AppException] hierarchy, so the SDK exception never
/// leaves `lib/core/functions/`.
///
/// Codes follow the standard Cloud Functions callable error set
/// (`functions.https.HttpsError` on the server side).
AppException mapCloudFunctionsExceptionToAppException(
  FirebaseException exception,
  StackTrace stackTrace,
) {
  switch (exception.code) {
    case 'unauthenticated':
      return UnauthorizedException(
        'Sessão expirada. Faça login novamente.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
    case 'permission-denied':
      return ForbiddenException(
        'Você não tem permissão para executar esta operação.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
    case 'not-found':
      return NotFoundException(
        'Função não encontrada.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
    case 'already-exists':
    case 'aborted':
      return ConflictException(
        'Conflito ao processar a solicitação. Tente novamente.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
    case 'failed-precondition':
      return ConflictException(
        exception.message ??
            'Conflito ao processar a solicitação. Tente novamente.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
    case 'unavailable':
    case 'deadline-exceeded':
    case 'cancelled':
      return NetworkException(
        'Sem conexão com o servidor. Tente novamente.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
    case 'resource-exhausted':
      return ServerException(
        'Limite de uso atingido. Tente novamente mais tarde.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
    case 'invalid-argument':
    case 'out-of-range':
      return ValidationException(
        exception.message ?? 'Dados inválidos enviados à função.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
    case 'internal':
    case 'unimplemented':
    case 'data-loss':
      return ServerException(
        'Falha no processamento no servidor. Tente novamente mais tarde.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
    default:
      return UnknownException(
        exception.message ?? 'Falha desconhecida ao chamar a função.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
  }
}

/// Cloud Functions error codes that represent a transient server/network
/// condition — [CloudFunctionsService] retries automatically only these,
/// relying on every real function being idempotent per `AGENTS.md`. Never
/// includes a validation or permission code: those are the caller's fault
/// (or the current state's), not something a retry fixes.
const transientCloudFunctionsErrorCodes = <String>{
  'unavailable',
  'deadline-exceeded',
  'internal',
  'aborted',
  'cancelled',
};
